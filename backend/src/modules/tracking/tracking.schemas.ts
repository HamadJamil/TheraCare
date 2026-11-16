import { z } from 'zod';
import { clientId } from '../../common/schemas';
import { paginationQuery } from '../../common/pagination';

const kind = z.enum(['PAIN_INTENSITY', 'STIFFNESS', 'SLEEP_QUALITY', 'MOOD']);

export const createObservationSchema = z
  .object({
    clientId,
    kind,
    value: z.number().int(),
    note: z.string().trim().max(500).optional(),
    effectiveAt: z.coerce.date(),
  })
  .strict();

export const listObservationsQuery = paginationQuery.extend({
  kind: kind.optional(),
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
  includeCorrected: z
    .enum(['true', 'false'])
    .transform((v) => v === 'true')
    .optional(),
});

export const correctionSchema = z
  .object({
    clientId,
    value: z.number().int(),
    reason: z.string().trim().min(1, 'Please tell us why you are correcting this entry.').max(200),
    note: z.string().trim().max(500).optional(),
  })
  .strict();
