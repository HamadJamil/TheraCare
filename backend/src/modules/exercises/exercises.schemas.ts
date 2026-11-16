import { z } from 'zod';
import { clientId } from '../../common/schemas';

export const completionSchema = z
  .object({
    clientId,
    sessionId: z.string().uuid().optional(),
    startedAt: z.coerce.date(),
    completedAt: z.coerce.date(),
    perceivedDifficulty: z.number().int().min(1).max(5).optional(),
  })
  .strict();
