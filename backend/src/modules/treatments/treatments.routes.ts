import { Router } from 'express';
import { z } from 'zod';
import { created, ok } from '../../common/http';
import { localeOf } from '../../common/locale';
import { clientId, idParams } from '../../common/schemas';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { requireTreatmentAccess } from '../../middleware/treatment-access';
import * as treatments from './treatments.service';

const startSchema = z.object({ clientId }).strict();
const completeSchema = z
  .object({ perceivedEffort: z.number().int().min(1).max(5).optional() })
  .strict();

/** Mounted at the API root: every route authenticates itself. */
export const treatmentsRouter = Router();

treatmentsRouter.get(
  '/treatments/current',
  authenticate,
  requireTreatmentAccess,
  async (req, res) => {
    ok(res, await treatments.getCurrent(authOf(req).userId, localeOf(req)));
  },
);

treatmentsRouter.get(
  '/treatments/:id/schedule',
  authenticate,
  requireTreatmentAccess,
  async (req, res) => {
    const { id } = parse(idParams, req.params);
    ok(res, await treatments.getSchedule(authOf(req).userId, id));
  },
);

treatmentsRouter.post(
  '/treatments/:id/sessions',
  authenticate,
  requireTreatmentAccess,
  async (req, res) => {
    const { id } = parse(idParams, req.params);
    const body = parse(startSchema, req.body);
    created(res, await treatments.startSession(authOf(req).userId, id, body.clientId));
  },
);

treatmentsRouter.post(
  '/sessions/:id/pause',
  authenticate,
  requireTreatmentAccess,
  async (req, res) => {
    ok(res, await treatments.pauseSession(authOf(req).userId, parse(idParams, req.params).id));
  },
);

treatmentsRouter.post(
  '/sessions/:id/resume',
  authenticate,
  requireTreatmentAccess,
  async (req, res) => {
    ok(res, await treatments.resumeSession(authOf(req).userId, parse(idParams, req.params).id));
  },
);

treatmentsRouter.post(
  '/sessions/:id/complete',
  authenticate,
  requireTreatmentAccess,
  async (req, res) => {
    const { id } = parse(idParams, req.params);
    const body = parse(completeSchema, req.body ?? {});
    ok(res, await treatments.completeSession(authOf(req).userId, id, body.perceivedEffort));
  },
);
