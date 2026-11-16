import { Router } from 'express';
import { created, ok } from '../../common/http';
import { localeOf } from '../../common/locale';
import { idParams } from '../../common/schemas';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { requireTreatmentAccess } from '../../middleware/treatment-access';
import * as tracking from './tracking.service';
import {
  correctionSchema,
  createObservationSchema,
  listObservationsQuery,
} from './tracking.schemas';

export const trackingRouter = Router();
trackingRouter.use(authenticate, requireTreatmentAccess);

trackingRouter.get('/instruments', (req, res) => {
  ok(res, tracking.listInstruments(localeOf(req)));
});

trackingRouter.post('/', async (req, res) => {
  const body = parse(createObservationSchema, req.body);
  const result = await tracking.createObservation(authOf(req).userId, body);
  ok(
    res,
    { ...tracking.observationView(result.observation), duplicate: result.duplicate },
    result.duplicate ? 200 : 201,
  );
});

trackingRouter.get('/', async (req, res) => {
  ok(
    res,
    await tracking.listObservations(authOf(req).userId, parse(listObservationsQuery, req.query)),
  );
});

trackingRouter.post('/:id/corrections', async (req, res) => {
  const { id } = parse(idParams, req.params);
  const body = parse(correctionSchema, req.body);
  created(
    res,
    await tracking.correctObservation(authOf(req).userId, id, body, res.locals.requestId),
  );
});

trackingRouter.get('/:id/history', async (req, res) => {
  const { id } = parse(idParams, req.params);
  ok(res, await tracking.observationHistory(authOf(req).userId, id));
});
