import type { Observation, ObservationKind } from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError, Errors } from '../../common/errors';
import { pickLocale, type Locale } from '../../common/localized';
import { pageArgs, toPage, type Pagination } from '../../common/pagination';
import { audit } from '../audit/audit.service';
import { INSTRUMENTS } from './instruments';

export function listInstruments(locale: Locale) {
  return Object.values(INSTRUMENTS).map((i) => ({
    kind: i.kind,
    min: i.min,
    max: i.max,
    unit: i.unit,
    title: pickLocale(i.title, locale),
    minLabel: pickLocale(i.minLabel, locale),
    maxLabel: pickLocale(i.maxLabel, locale),
  }));
}

function assertInRange(kind: ObservationKind, value: number) {
  const { min, max } = INSTRUMENTS[kind];
  if (!Number.isInteger(value) || value < min || value > max) {
    throw Errors.validation({ value: `Please choose a whole number from ${min} to ${max}.` });
  }
}

function assertNotFuture(effectiveAt: Date) {
  if (effectiveAt.getTime() > Date.now() + 5 * 60_000) {
    throw Errors.validation({ effectiveAt: 'The time cannot be in the future.' });
  }
}

export const observationView = (o: Observation) => ({
  id: o.id,
  clientId: o.clientId,
  kind: o.kind,
  value: o.value,
  unit: INSTRUMENTS[o.kind].unit,
  note: o.note,
  effectiveAt: o.effectiveAt,
  recordedAt: o.recordedAt,
  source: o.source,
  status: o.status,
  supersedesId: o.supersedesId,
});

export type ObservationInput = {
  clientId: string;
  kind: ObservationKind;
  value: number;
  note?: string;
  effectiveAt: Date;
  source?: 'app' | 'sync';
};

/** Creates an observation exactly once per client id (safe for retries and offline sync). */
export async function createObservation(userId: string, input: ObservationInput) {
  const existing = await prisma.observation.findUnique({
    where: { userId_clientId: { userId, clientId: input.clientId } },
  });
  if (existing) return { observation: existing, duplicate: true };

  assertInRange(input.kind, input.value);
  assertNotFuture(input.effectiveAt);
  try {
    const observation = await prisma.observation.create({
      data: { userId, ...input, source: input.source ?? 'app' },
    });
    return { observation, duplicate: false };
  } catch (err) {
    const raced = await prisma.observation.findUnique({
      where: { userId_clientId: { userId, clientId: input.clientId } },
    });
    if (raced) return { observation: raced, duplicate: true };
    throw err;
  }
}

type ListFilter = Pagination & {
  kind?: ObservationKind;
  from?: Date;
  to?: Date;
  includeCorrected?: boolean;
};

export async function listObservations(userId: string, filter: ListFilter) {
  const rows = await prisma.observation.findMany({
    where: {
      userId,
      kind: filter.kind,
      status: filter.includeCorrected ? undefined : 'CURRENT',
      effectiveAt: { gte: filter.from, lte: filter.to },
    },
    orderBy: [{ effectiveAt: 'desc' }, { id: 'desc' }],
    ...pageArgs(filter),
  });
  const page = toPage(rows, filter.limit);
  return { items: page.items.map(observationView), nextCursor: page.nextCursor };
}

/**
 * Corrections are append-only: the original is kept (status CORRECTED) and a
 * new observation supersedes it, preserving provenance.
 */
export async function correctObservation(
  userId: string,
  observationId: string,
  input: { clientId: string; value: number; reason: string; note?: string },
  requestId?: string,
) {
  const original = await prisma.observation.findFirst({ where: { id: observationId, userId } });
  if (!original) throw Errors.notFound('The entry');
  const existing = await prisma.observation.findUnique({
    where: { userId_clientId: { userId, clientId: input.clientId } },
  });
  if (existing) return observationView(existing);
  if (original.status !== 'CURRENT') {
    throw new AppError(409, 'ALREADY_CORRECTED', 'This entry has already been corrected.');
  }
  assertInRange(original.kind, input.value);

  const replacement = await prisma.$transaction(async (tx) => {
    const { count } = await tx.observation.updateMany({
      where: { id: original.id, status: 'CURRENT' },
      data: { status: 'CORRECTED' },
    });
    if (count === 0)
      throw new AppError(409, 'ALREADY_CORRECTED', 'This entry has already been corrected.');
    const created = await tx.observation.create({
      data: {
        userId,
        clientId: input.clientId,
        kind: original.kind,
        value: input.value,
        note: input.note ?? original.note,
        effectiveAt: original.effectiveAt,
        source: original.source,
        supersedesId: original.id,
      },
    });
    await tx.observationCorrection.create({
      data: {
        originalId: original.id,
        replacementId: created.id,
        reason: input.reason,
        correctedById: userId,
      },
    });
    await audit(
      {
        action: 'observation.corrected',
        resourceType: 'observation',
        resourceId: original.id,
        actorId: userId,
        requestId,
      },
      tx,
    );
    return created;
  });
  return observationView(replacement);
}

/** Full correction chain for an entry, oldest first. */
export async function observationHistory(userId: string, observationId: string) {
  const start = await prisma.observation.findFirst({ where: { id: observationId, userId } });
  if (!start) throw Errors.notFound('The entry');

  let oldest: Observation = start;
  while (oldest.supersedesId) {
    oldest = await prisma.observation.findUniqueOrThrow({ where: { id: oldest.supersedesId } });
  }
  const chain: Observation[] = [oldest];
  for (;;) {
    const next = await prisma.observation.findUnique({
      where: { supersedesId: chain[chain.length - 1].id },
    });
    if (!next) break;
    chain.push(next);
  }
  const corrections = await prisma.observationCorrection.findMany({
    where: { originalId: { in: chain.map((o) => o.id) } },
  });
  return chain.map((o) => ({
    ...observationView(o),
    correctionReason: corrections.find((c) => c.replacementId === o.id)?.reason ?? null,
  }));
}
