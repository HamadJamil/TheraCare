import type { QuestionnairePurpose } from '@prisma/client';
import { prisma, type Tx } from '../../config/database';
import { AppError, Errors } from '../../common/errors';
import { startOfUtcWeek } from '../../common/dates';
import { audit } from '../audit/audit.service';
import { advanceJourney, rank } from '../journey/journey.service';
import { assignTreatment } from '../treatments/treatments.service';

const alreadySubmitted = () =>
  new AppError(409, 'ALREADY_SUBMITTED', 'You have already answered this questionnaire.');

// ───────────── Onboarding ─────────────

export async function startOnboarding(userId: string) {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  if (rank(user.journeyState) < rank('PRIVACY_COMPLETE')) {
    throw Errors.precondition('PRIVACY_REQUIRED', 'Please complete activation and privacy first.');
  }
  return { state: await advanceJourney(userId, 'ONBOARDING_IN_PROGRESS') };
}

/**
 * Which questionnaire purposes the patient may answer right now, based on the
 * journey and treatment state.
 */
export async function availablePurposes(userId: string): Promise<QuestionnairePurpose[]> {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  const purposes: QuestionnairePurpose[] = [];
  const state = rank(user.journeyState);
  if (state >= rank('PRIVACY_COMPLETE') && state < rank('BASELINE_ASSESSMENT_COMPLETE')) {
    purposes.push('BASELINE');
  }
  const treatment = await prisma.patientTreatment.findFirst({
    where: { userId, status: { in: ['ACTIVE', 'AWAITING_FINAL_ASSESSMENT'] } },
  });
  if (treatment?.status === 'ACTIVE') purposes.push('ROUTINE');
  if (treatment?.status === 'AWAITING_FINAL_ASSESSMENT') purposes.push('FINAL');
  return purposes;
}

export async function submittedThisWeek(userId: string, questionnaireId: string) {
  return (
    (await prisma.questionnaireResponse.count({
      where: {
        userId,
        questionnaireId,
        status: 'SUBMITTED',
        submittedAt: { gte: startOfUtcWeek(new Date()) },
      },
    })) > 0
  );
}

// ───────────── Submission handlers ─────────────

type Submission = {
  userId: string;
  responseId: string;
  questionnaireId: string;
  score: number | null;
};

async function createAssessment(tx: Tx, purpose: QuestionnairePurpose, s: Submission) {
  const exists = await tx.assessment.findUnique({
    where: { userId_purpose: { userId: s.userId, purpose } },
  });
  if (exists) throw alreadySubmitted();
  return tx.assessment.create({
    data: { userId: s.userId, purpose, responseId: s.responseId, score: s.score ?? 0 },
  });
}

const HANDLERS: Record<QuestionnairePurpose, (tx: Tx, s: Submission) => Promise<object>> = {
  BASELINE: async (tx, s) => {
    await createAssessment(tx, 'BASELINE', s);
    await advanceJourney(s.userId, 'BASELINE_ASSESSMENT_COMPLETE', tx);
    const treatment = await assignTreatment(s.userId, s.score ?? 0, tx);
    return { treatmentId: treatment.id };
  },
  ROUTINE: async (tx, s) => {
    const sameWeek = await tx.questionnaireResponse.count({
      where: {
        userId: s.userId,
        questionnaireId: s.questionnaireId,
        status: 'SUBMITTED',
        submittedAt: { gte: startOfUtcWeek(new Date()) },
        id: { not: s.responseId },
      },
    });
    if (sameWeek > 0) throw alreadySubmitted();
    return {};
  },
  FINAL: async (tx, s) => {
    await createAssessment(tx, 'FINAL', s);
    await tx.patientTreatment.updateMany({
      where: { userId: s.userId, status: 'AWAITING_FINAL_ASSESSMENT' },
      data: { status: 'COMPLETED', completedAt: new Date() },
    });
    await advanceJourney(s.userId, 'TREATMENT_COMPLETED', tx);
    await audit(
      {
        action: 'treatment.completed',
        resourceType: 'user',
        resourceId: s.userId,
        actorId: s.userId,
      },
      tx,
    );
    return {};
  },
};

export function onSubmitted(tx: Tx, purpose: QuestionnairePurpose, submission: Submission) {
  return HANDLERS[purpose](tx, submission);
}

/** Baseline vs. final scores, with a neutral description (no clinical interpretation). */
export async function myAssessments(userId: string) {
  const rows = await prisma.assessment.findMany({ where: { userId } });
  const baseline = rows.find((r) => r.purpose === 'BASELINE');
  const final = rows.find((r) => r.purpose === 'FINAL');
  return {
    baseline: baseline && { score: baseline.score, at: baseline.createdAt },
    final: final && { score: final.score, at: final.createdAt },
    change: baseline && final ? final.score - baseline.score : null,
    scale: { min: 0, max: 34, lowerIsBetter: true },
  };
}
