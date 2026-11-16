import type { ExerciseVersion } from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError, Errors } from '../../common/errors';
import { pickLocale, type Locale } from '../../common/localized';
import { requireOpenTreatment } from '../treatments/treatments.service';

export function exerciseView(ev: ExerciseVersion, locale: Locale) {
  const transcript = ev.transcript ? pickLocale(ev.transcript, locale) : null;
  return {
    id: ev.id,
    version: ev.version,
    title: pickLocale(ev.title, locale),
    summary: pickLocale(ev.summary, locale),
    steps: (ev.steps as unknown[]).map((s) => pickLocale(s, locale)),
    safetyNotes: (ev.safetyNotes as unknown[]).map((s) => pickLocale(s, locale)),
    durationSeconds: ev.durationSeconds,
    mediaUrl: ev.mediaUrl,
    transcript,
  };
}

/** Exercise versions assigned through the patient's open treatment plan. */
async function assignedVersions(userId: string) {
  const treatment = await requireOpenTreatment(userId);
  const rows = await prisma.planExercise.findMany({
    where: { treatmentVersionId: treatment.treatmentVersionId },
    include: { exerciseVersion: true },
    orderBy: { order: 'asc' },
  });
  return { treatment, versions: rows.map((r) => r.exerciseVersion) };
}

export async function listAssigned(userId: string, locale: Locale) {
  const { versions } = await assignedVersions(userId);
  return versions.map((ev) => exerciseView(ev, locale));
}

export async function getAssigned(userId: string, exerciseVersionId: string, locale: Locale) {
  const { versions } = await assignedVersions(userId);
  const ev = versions.find((v) => v.id === exerciseVersionId);
  if (!ev) throw Errors.notFound('The exercise');
  return exerciseView(ev, locale);
}

export type CompletionInput = {
  clientId: string;
  exerciseVersionId: string;
  sessionId?: string;
  startedAt: Date;
  completedAt: Date;
  perceivedDifficulty?: number;
};

/**
 * Records a completion exactly once per client-generated id. Shared by the
 * REST endpoint and offline synchronisation.
 */
export async function recordCompletion(userId: string, input: CompletionInput) {
  const existing = await prisma.exerciseCompletion.findUnique({
    where: { userId_clientId: { userId, clientId: input.clientId } },
  });
  if (existing) return { completion: existing, duplicate: true };

  const { versions } = await assignedVersions(userId);
  if (!versions.some((v) => v.id === input.exerciseVersionId))
    throw Errors.notFound('The exercise');
  if (
    input.completedAt < input.startedAt ||
    input.completedAt.getTime() > Date.now() + 5 * 60_000
  ) {
    throw new AppError(400, 'INVALID_TIME_RANGE', 'The exercise times are not valid.');
  }
  if (input.sessionId) {
    const session = await prisma.treatmentSession.findFirst({
      where: { id: input.sessionId, userId },
    });
    if (!session) throw Errors.notFound('The exercise session');
  }

  try {
    const completion = await prisma.exerciseCompletion.create({
      data: {
        userId,
        clientId: input.clientId,
        exerciseVersionId: input.exerciseVersionId,
        sessionId: input.sessionId,
        startedAt: input.startedAt,
        completedAt: input.completedAt,
        durationSeconds: Math.round(
          (input.completedAt.getTime() - input.startedAt.getTime()) / 1000,
        ),
        perceivedDifficulty: input.perceivedDifficulty,
      },
    });
    return { completion, duplicate: false };
  } catch (err) {
    // Concurrent duplicate delivery: the unique (userId, clientId) constraint won.
    const raced = await prisma.exerciseCompletion.findUnique({
      where: { userId_clientId: { userId, clientId: input.clientId } },
    });
    if (raced) return { completion: raced, duplicate: true };
    throw err;
  }
}
