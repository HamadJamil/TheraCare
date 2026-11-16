import type { PatientTreatment } from '@prisma/client';
import { prisma, type Tx } from '../../config/database';
import { AppError, Errors } from '../../common/errors';
import { DAY_MS, addDays, startOfZonedDay } from '../../common/dates';
import { pickLocale, type Locale } from '../../common/localized';
import { audit } from '../audit/audit.service';
import { advanceJourney } from '../journey/journey.service';

const OPEN_STATUSES = ['ACTIVE', 'AWAITING_FINAL_ASSESSMENT'] as const;

/**
 * Assigns the published plan version whose baseline range contains the score.
 * Rules are configuration (versioned content), never computed in the client.
 */
export async function assignTreatment(userId: string, baselineScore: number, tx: Tx) {
  const candidates = await tx.treatmentVersion.findMany({
    where: {
      status: 'PUBLISHED',
      minBaselineScore: { lte: baselineScore },
      maxBaselineScore: { gte: baselineScore },
    },
    orderBy: { version: 'desc' },
  });
  const version = candidates[0];
  if (!version) {
    throw new AppError(
      500,
      'NO_PLAN_CONFIGURED',
      'No treatment plan is configured for this result.',
    );
  }
  const now = new Date();
  const assigned = await tx.patientTreatment.create({
    data: {
      userId,
      treatmentVersionId: version.id,
      startedAt: now,
      endsAt: addDays(now, version.durationWeeks * 7),
    },
  });
  await advanceJourney(userId, 'TREATMENT_ACTIVE', tx);
  await audit(
    {
      action: 'treatment.assigned',
      resourceType: 'patient_treatment',
      resourceId: assigned.id,
      actorId: userId,
    },
    tx,
  );
  return assigned;
}

/** Moves a finished treatment period to the final-assessment step. */
async function settlePeriod(treatment: PatientTreatment) {
  if (treatment.status !== 'ACTIVE' || treatment.endsAt > new Date()) return treatment;
  return prisma.$transaction(async (tx) => {
    const updated = await tx.patientTreatment.update({
      where: { id: treatment.id },
      data: { status: 'AWAITING_FINAL_ASSESSMENT' },
    });
    await advanceJourney(treatment.userId, 'FINAL_ASSESSMENT', tx);
    return updated;
  });
}

/** The patient's open treatment, settling the period if it has ended. */
export async function findOpenTreatment(userId: string) {
  const treatment = await prisma.patientTreatment.findFirst({
    where: { userId, status: { in: [...OPEN_STATUSES] } },
    orderBy: { startedAt: 'desc' },
  });
  return treatment && settlePeriod(treatment);
}

export async function requireOpenTreatment(userId: string, treatmentId?: string) {
  const treatment = await findOpenTreatment(userId);
  if (!treatment || (treatmentId && treatment.id !== treatmentId)) {
    throw Errors.notFound('The treatment plan');
  }
  return treatment;
}

async function timezoneOf(userId: string) {
  const profile = await prisma.patientProfile.findUnique({ where: { userId } });
  return profile?.timezone ?? 'Europe/Berlin';
}

export async function getCurrent(userId: string, locale: Locale) {
  const treatment = await findOpenTreatment(userId);
  if (!treatment) return null;

  const version = await prisma.treatmentVersion.findUniqueOrThrow({
    where: { id: treatment.treatmentVersionId },
    include: { exercises: { include: { exerciseVersion: true }, orderBy: { order: 'asc' } } },
  });
  const todayStart = startOfZonedDay(new Date(), await timezoneOf(userId));
  const doneToday = await prisma.exerciseCompletion.findMany({
    where: { userId, completedAt: { gte: todayStart } },
    select: { exerciseVersionId: true },
  });
  const done = new Set(doneToday.map((c) => c.exerciseVersionId));
  const elapsedDays = Math.floor((Date.now() - treatment.startedAt.getTime()) / DAY_MS);

  return {
    id: treatment.id,
    status: treatment.status,
    startedAt: treatment.startedAt,
    endsAt: treatment.endsAt,
    week: Math.min(Math.floor(elapsedDays / 7) + 1, version.durationWeeks),
    totalWeeks: version.durationWeeks,
    plan: {
      versionId: version.id,
      version: version.version,
      title: pickLocale(version.title, locale),
      objectives: (version.objectives as unknown[]).map((o) => pickLocale(o, locale)),
    },
    today: version.exercises.map(({ exerciseVersion: ev }) => ({
      exerciseId: ev.id,
      title: pickLocale(ev.title, locale),
      durationSeconds: ev.durationSeconds,
      completed: done.has(ev.id),
    })),
  };
}

/** Week-by-week view: planned exercises per day vs. distinct exercises completed. */
export async function getSchedule(userId: string, treatmentId: string) {
  const treatment = await requireOpenTreatment(userId, treatmentId);
  const plannedPerDay = await prisma.planExercise.count({
    where: { treatmentVersionId: treatment.treatmentVersionId },
  });
  const completions = await prisma.exerciseCompletion.findMany({
    where: { userId, completedAt: { gte: treatment.startedAt, lte: treatment.endsAt } },
    select: { completedAt: true, exerciseVersionId: true },
  });

  const totalDays = Math.round(
    (treatment.endsAt.getTime() - treatment.startedAt.getTime()) / DAY_MS,
  );
  const days = Array.from({ length: totalDays }, (_, i) => ({
    date: addDays(treatment.startedAt, i).toISOString().slice(0, 10),
    planned: plannedPerDay,
    completed: new Set<string>(),
  }));
  for (const c of completions) {
    const index = Math.floor((c.completedAt.getTime() - treatment.startedAt.getTime()) / DAY_MS);
    days[index]?.completed.add(c.exerciseVersionId);
  }

  const weeks = [];
  for (let w = 0; w * 7 < days.length; w++) {
    const slice = days.slice(w * 7, w * 7 + 7);
    weeks.push({
      week: w + 1,
      days: slice.map((d) => ({ date: d.date, planned: d.planned, completed: d.completed.size })),
    });
  }
  return { treatmentId: treatment.id, weeks };
}

// ───────────── Sessions ─────────────

export async function startSession(userId: string, treatmentId: string, clientId: string) {
  const treatment = await requireOpenTreatment(userId, treatmentId);
  const existing = await prisma.treatmentSession.findUnique({
    where: { userId_clientId: { userId, clientId } },
  });
  if (existing) return existing;
  return prisma.treatmentSession.create({
    data: { userId, patientTreatmentId: treatment.id, clientId },
  });
}

async function ownSession(userId: string, sessionId: string) {
  const session = await prisma.treatmentSession.findFirst({ where: { id: sessionId, userId } });
  if (!session) throw Errors.notFound('The exercise session');
  return session;
}

const sessionClosed = () =>
  new AppError(409, 'SESSION_CLOSED', 'This exercise session has already ended.');

export async function pauseSession(userId: string, sessionId: string) {
  const session = await ownSession(userId, sessionId);
  if (session.status === 'PAUSED') return session;
  if (session.status !== 'IN_PROGRESS') throw sessionClosed();
  return prisma.treatmentSession.update({
    where: { id: session.id },
    data: { status: 'PAUSED', pausedAt: new Date() },
  });
}

export async function resumeSession(userId: string, sessionId: string) {
  const session = await ownSession(userId, sessionId);
  if (session.status === 'IN_PROGRESS') return session;
  if (session.status !== 'PAUSED') throw sessionClosed();
  return prisma.treatmentSession.update({
    where: { id: session.id },
    data: { status: 'IN_PROGRESS', pausedAt: null },
  });
}

/** Completing twice returns the already-completed session (safe retry). */
export async function completeSession(userId: string, sessionId: string, perceivedEffort?: number) {
  const session = await ownSession(userId, sessionId);
  if (session.status === 'COMPLETED') return session;
  if (session.status === 'ABANDONED') throw sessionClosed();
  return prisma.treatmentSession.update({
    where: { id: session.id },
    data: { status: 'COMPLETED', endedAt: new Date(), pausedAt: null, perceivedEffort },
  });
}
