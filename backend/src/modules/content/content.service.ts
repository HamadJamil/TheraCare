import type { ContentResource, ContentStatus, Prisma, ReviewAction, Role } from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError, Errors } from '../../common/errors';
import { audit } from '../audit/audit.service';
import { EDITABLE, nextStatus } from './lifecycle';

type Versioned = { id: string; status: ContentStatus; createdById: string | null };

/** Uniform access to the three versioned content tables. */
const STORES: Record<
  ContentResource,
  {
    find: (id: string) => Promise<Versioned | null>;
    setStatus: (
      tx: Prisma.TransactionClient,
      id: string,
      status: ContentStatus,
    ) => Promise<unknown>;
  }
> = {
  EXERCISE_VERSION: {
    find: (id) => prisma.exerciseVersion.findUnique({ where: { id } }),
    setStatus: (tx, id, status) =>
      tx.exerciseVersion.update({
        where: { id },
        data: { status, publishedAt: status === 'PUBLISHED' ? new Date() : undefined },
      }),
  },
  TREATMENT_VERSION: {
    find: (id) => prisma.treatmentVersion.findUnique({ where: { id } }),
    setStatus: (tx, id, status) =>
      tx.treatmentVersion.update({
        where: { id },
        data: { status, publishedAt: status === 'PUBLISHED' ? new Date() : undefined },
      }),
  },
  QUESTIONNAIRE: {
    find: (id) => prisma.questionnaire.findUnique({ where: { id } }),
    setStatus: (tx, id, status) =>
      tx.questionnaire.update({
        where: { id },
        data: { status, publishedAt: status === 'PUBLISHED' ? new Date() : undefined },
      }),
  },
};

type Actor = { userId: string; role: Role };

export async function transition(
  resource: ContentResource,
  id: string,
  action: ReviewAction,
  actor: Actor,
  reason?: string,
  requestId?: string,
) {
  const item = await STORES[resource].find(id);
  if (!item) throw Errors.notFound('The content item');

  const to = nextStatus(action, item.status, actor.role);
  if (to === 'FORBIDDEN') throw Errors.forbidden('Your role cannot perform this step.');
  if (to === 'INVALID') {
    throw new AppError(
      409,
      'INVALID_TRANSITION',
      `Content in status ${item.status} cannot be ${action.toLowerCase()}.`,
    );
  }
  if (action === 'APPROVED' && item.createdById === actor.userId) {
    throw Errors.forbidden('Content must be reviewed by someone other than its author.');
  }
  if (action === 'REJECTED' && !reason)
    throw Errors.validation({ reason: 'Please give a reason for the rejection.' });

  await prisma.$transaction(async (tx) => {
    await STORES[resource].setStatus(tx, id, to);
    await tx.contentReview.create({
      data: { resourceType: resource, resourceId: id, action, actorId: actor.userId, reason },
    });
    await audit(
      {
        action: `content.${action.toLowerCase()}`,
        resourceType: resource,
        resourceId: id,
        actorId: actor.userId,
        actorRole: actor.role,
        reason,
        requestId,
      },
      tx,
    );
  });
  return { id, status: to };
}

export async function reviewHistory(resourceId: string) {
  return prisma.contentReview.findMany({ where: { resourceId }, orderBy: { createdAt: 'asc' } });
}

// ───────────── Exercise authoring ─────────────

export async function listExercises() {
  const exercises = await prisma.exercise.findMany({
    include: { versions: { orderBy: { version: 'desc' } } },
    orderBy: { key: 'asc' },
  });
  return exercises.map((e) => ({
    id: e.id,
    key: e.key,
    versions: e.versions.map((v) => ({
      id: v.id,
      version: v.version,
      status: v.status,
      title: v.title,
      publishedAt: v.publishedAt,
    })),
  }));
}

/** New draft version copied from the latest version; published versions are never edited in place. */
export async function createExerciseDraft(exerciseId: string, authorId: string) {
  const latest = await prisma.exerciseVersion.findFirst({
    where: { exerciseId },
    orderBy: { version: 'desc' },
  });
  if (!latest) throw Errors.notFound('The exercise');
  if (EDITABLE.includes(latest.status) || latest.status === 'IN_REVIEW') {
    throw new AppError(409, 'DRAFT_EXISTS', 'A draft of this exercise is already in progress.');
  }
  const draft = await prisma.exerciseVersion.create({
    data: {
      exerciseId,
      version: latest.version + 1,
      title: latest.title as Prisma.InputJsonValue,
      summary: latest.summary as Prisma.InputJsonValue,
      steps: latest.steps as Prisma.InputJsonValue,
      safetyNotes: latest.safetyNotes as Prisma.InputJsonValue,
      transcript: (latest.transcript ?? undefined) as Prisma.InputJsonValue | undefined,
      durationSeconds: latest.durationSeconds,
      mediaUrl: latest.mediaUrl,
      createdById: authorId,
    },
  });
  await audit({
    action: 'content.draft_created',
    resourceType: 'EXERCISE_VERSION',
    resourceId: draft.id,
    actorId: authorId,
    actorRole: 'CONTENT_AUTHOR',
  });
  return draft;
}

export async function editExerciseDraft(
  id: string,
  authorId: string,
  data: Prisma.ExerciseVersionUpdateInput,
) {
  const version = await prisma.exerciseVersion.findUnique({ where: { id } });
  if (!version) throw Errors.notFound('The exercise version');
  if (!EDITABLE.includes(version.status)) {
    throw new AppError(
      409,
      'CONTENT_IMMUTABLE',
      'Only drafts can be edited. Create a new version instead.',
    );
  }
  const updated = await prisma.exerciseVersion.update({
    where: { id },
    data: { ...data, createdById: authorId },
  });
  await audit({
    action: 'content.draft_edited',
    resourceType: 'EXERCISE_VERSION',
    resourceId: id,
    actorId: authorId,
    actorRole: 'CONTENT_AUTHOR',
  });
  return updated;
}
