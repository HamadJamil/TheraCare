import { z } from 'zod';
import { parse } from '../../common/validation';
import { recordCompletion } from '../exercises/exercises.service';
import { completionSchema } from '../exercises/exercises.schemas';
import { createObservation } from '../tracking/tracking.service';
import { createObservationSchema } from '../tracking/tracking.schemas';

export type SyncResult = { resultId: string };
type Handler = (userId: string, clientEventId: string, payload: unknown) => Promise<SyncResult>;

/**
 * Offline event types the server accepts. Each reuses the same domain service as
 * the online endpoint, so validation and idempotency rules are identical.
 */
export const SYNC_HANDLERS: Record<string, Handler> = {
  OBSERVATION_CREATED: async (userId, clientEventId, payload) => {
    const body = parse(createObservationSchema.partial({ clientId: true }), payload);
    const { observation } = await createObservation(userId, {
      ...body,
      clientId: body.clientId ?? clientEventId,
      source: 'sync',
    });
    return { resultId: observation.id };
  },
  EXERCISE_COMPLETED: async (userId, clientEventId, payload) => {
    const body = parse(
      completionSchema.partial({ clientId: true }).extend({ exerciseVersionId: z.string().uuid() }),
      payload,
    );
    const { completion } = await recordCompletion(userId, {
      ...body,
      clientId: body.clientId ?? clientEventId,
    });
    return { resultId: completion.id };
  },
};

export const SYNC_EVENT_TYPES = Object.keys(SYNC_HANDLERS) as [string, ...string[]];
