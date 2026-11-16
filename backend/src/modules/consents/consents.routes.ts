import { Router } from 'express';
import { z } from 'zod';
import { created, ok } from '../../common/http';
import { localeOf } from '../../common/locale';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { requireVerified } from '../../middleware/authorize';
import * as consents from './consents.service';

const decisionSchema = z
  .object({
    consentTypeId: z.string().uuid(),
    decision: z.enum(['GRANTED', 'DECLINED']),
    appVersion: z.string().max(32).optional(),
  })
  .strict();

const idParams = z.object({ id: z.string().uuid() });

export const consentsRouter = Router();
consentsRouter.use(authenticate, requireVerified);

consentsRouter.get('/types', async (req, res) => {
  ok(res, await consents.listTypes(localeOf(req)));
});

consentsRouter.get('/me', async (req, res) => {
  ok(res, await consents.myConsents(authOf(req).userId, localeOf(req)));
});

consentsRouter.post('/', async (req, res) => {
  const body = parse(decisionSchema, req.body);
  created(
    res,
    await consents.recordDecision(
      authOf(req).userId,
      { ...body, locale: localeOf(req) },
      res.locals.requestId,
    ),
  );
});

consentsRouter.post('/:id/withdraw', async (req, res) => {
  const { id } = parse(idParams, req.params);
  ok(res, await consents.withdraw(authOf(req).userId, id, localeOf(req), res.locals.requestId));
});
