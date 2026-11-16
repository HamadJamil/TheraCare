import { Router } from 'express';
import { z } from 'zod';
import { ok } from '../../common/http';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { requireVerified } from '../../middleware/authorize';
import { SYNC_EVENT_TYPES } from './sync.handlers';
import * as sync from './sync.service';

const batchSchema = z
  .object({
    events: z
      .array(
        z
          .object({
            clientEventId: z.string().uuid(),
            type: z.enum(SYNC_EVENT_TYPES),
            payload: z.record(z.unknown()),
          })
          .strict(),
      )
      .min(1)
      .max(100),
  })
  .strict();

export const syncRouter = Router();
syncRouter.use(authenticate, requireVerified);

syncRouter.post('/events', async (req, res) => {
  const { events } = parse(batchSchema, req.body);
  ok(res, { results: await sync.ingest(authOf(req).userId, events) });
});

syncRouter.get('/status', async (req, res) => {
  ok(res, await sync.status(authOf(req).userId));
});
