import { prisma } from '../../config/database';
import { AppError } from '../../common/errors';
import { logger } from '../../config/logger';
import { ensureTreatmentAccess } from '../../middleware/treatment-access';
import { SYNC_HANDLERS } from './sync.handlers';

export type SyncEventInput = { clientEventId: string; type: string; payload: unknown };

export type SyncOutcome = {
  clientEventId: string;
  status: 'ACCEPTED' | 'REJECTED' | 'RETRY';
  resultId?: string | null;
  errorCode?: string | null;
  duplicate: boolean;
};

/**
 * Ingests a batch of offline events. Accepted and permanently rejected events are
 * recorded so redelivery returns the original outcome; transient failures are
 * reported as RETRY and not recorded.
 */
export async function ingest(userId: string, events: SyncEventInput[]): Promise<SyncOutcome[]> {
  const outcomes: SyncOutcome[] = [];
  for (const event of events) {
    outcomes.push(await ingestOne(userId, event));
  }
  return outcomes;
}

async function ingestOne(userId: string, event: SyncEventInput): Promise<SyncOutcome> {
  const known = await prisma.syncEvent.findUnique({
    where: { userId_clientEventId: { userId, clientEventId: event.clientEventId } },
  });
  if (known) {
    return {
      clientEventId: event.clientEventId,
      status: known.status,
      resultId: known.resultId,
      errorCode: known.errorCode,
      duplicate: true,
    };
  }

  let status: 'ACCEPTED' | 'REJECTED';
  let resultId: string | undefined;
  let errorCode: string | undefined;
  try {
    await ensureTreatmentAccess(userId);
    ({ resultId } = await SYNC_HANDLERS[event.type](userId, event.clientEventId, event.payload));
    status = 'ACCEPTED';
  } catch (err) {
    if (err instanceof AppError && err.status === 412) {
      // Access can be restored (e.g. consent given again) — keep the event on the device.
      return {
        clientEventId: event.clientEventId,
        status: 'RETRY',
        errorCode: err.code,
        duplicate: false,
      };
    }
    if (err instanceof AppError && err.status < 500) {
      status = 'REJECTED';
      errorCode = err.code;
    } else {
      logger.warn({ err, type: event.type }, 'sync event failed transiently');
      return {
        clientEventId: event.clientEventId,
        status: 'RETRY',
        errorCode: 'TEMPORARY_FAILURE',
        duplicate: false,
      };
    }
  }

  await prisma.syncEvent
    .create({
      data: {
        userId,
        clientEventId: event.clientEventId,
        type: event.type,
        status,
        resultId,
        errorCode,
      },
    })
    .catch(() => undefined); // concurrent redelivery already recorded the same outcome
  return { clientEventId: event.clientEventId, status, resultId, errorCode, duplicate: false };
}

export async function status(userId: string) {
  const [accepted, rejected, last] = await Promise.all([
    prisma.syncEvent.count({ where: { userId, status: 'ACCEPTED' } }),
    prisma.syncEvent.count({ where: { userId, status: 'REJECTED' } }),
    prisma.syncEvent.findFirst({ where: { userId }, orderBy: { receivedAt: 'desc' } }),
  ]);
  return { accepted, rejected, lastReceivedAt: last?.receivedAt ?? null, serverTime: new Date() };
}
