import { Router } from 'express';
import { ok } from '../../common/http';
import { localeOf } from '../../common/locale';
import { idParams } from '../../common/schemas';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { requireTreatmentAccess } from '../../middleware/treatment-access';
import * as exercises from './exercises.service';
import { completionSchema } from './exercises.schemas';

export const exercisesRouter = Router();
exercisesRouter.use(authenticate, requireTreatmentAccess);

exercisesRouter.get('/', async (req, res) => {
  ok(res, await exercises.listAssigned(authOf(req).userId, localeOf(req)));
});

exercisesRouter.get('/:id', async (req, res) => {
  const { id } = parse(idParams, req.params);
  ok(res, await exercises.getAssigned(authOf(req).userId, id, localeOf(req)));
});

exercisesRouter.post('/:id/completions', async (req, res) => {
  const { id } = parse(idParams, req.params);
  const body = parse(completionSchema, req.body);
  const result = await exercises.recordCompletion(authOf(req).userId, {
    ...body,
    exerciseVersionId: id,
  });
  ok(res, { ...result.completion, duplicate: result.duplicate }, result.duplicate ? 200 : 201);
});
