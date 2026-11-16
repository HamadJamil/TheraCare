import { Router } from 'express';
import { z } from 'zod';
import { created, ok } from '../../common/http';
import { idParams } from '../../common/schemas';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { requireRole } from '../../middleware/authorize';
import * as content from './content.service';

const localized = z
  .object({ de: z.string().min(1).max(2000), en: z.string().min(1).max(2000) })
  .strict();

const editSchema = z
  .object({
    title: localized,
    summary: localized,
    steps: z.array(localized).min(1).max(20),
    safetyNotes: z.array(localized).min(1).max(10),
    durationSeconds: z.number().int().min(10).max(3600),
    transcript: localized,
    mediaUrl: z.string().url().nullable(),
  })
  .partial()
  .strict();

const RESOURCE = {
  exercise: 'EXERCISE_VERSION',
  treatment: 'TREATMENT_VERSION',
  questionnaire: 'QUESTIONNAIRE',
} as const;
const ACTION = {
  submit: 'SUBMITTED',
  approve: 'APPROVED',
  reject: 'REJECTED',
  publish: 'PUBLISHED',
  retire: 'RETIRED',
} as const;

const transitionParams = z.object({
  resource: z.enum(['exercise', 'treatment', 'questionnaire']),
  id: z.string().uuid(),
  action: z.enum(['submit', 'approve', 'reject', 'publish', 'retire']),
});

export const contentRouter = Router();
contentRouter.use(authenticate, requireRole('CONTENT_AUTHOR', 'CLINICAL_REVIEWER', 'ADMIN'));

contentRouter.get('/exercises', async (_req, res) => {
  ok(res, await content.listExercises());
});

contentRouter.post('/exercises/:id/versions', requireRole('CONTENT_AUTHOR'), async (req, res) => {
  created(
    res,
    await content.createExerciseDraft(parse(idParams, req.params).id, authOf(req).userId),
  );
});

contentRouter.patch('/exercise-versions/:id', requireRole('CONTENT_AUTHOR'), async (req, res) => {
  const { id } = parse(idParams, req.params);
  ok(res, await content.editExerciseDraft(id, authOf(req).userId, parse(editSchema, req.body)));
});

contentRouter.post('/:resource/:id/:action', async (req, res) => {
  const params = parse(transitionParams, req.params);
  const { reason } = parse(
    z.object({ reason: z.string().trim().max(500).optional() }).strict(),
    req.body ?? {},
  );
  const { userId, role } = authOf(req);
  ok(
    res,
    await content.transition(
      RESOURCE[params.resource],
      params.id,
      ACTION[params.action],
      { userId, role },
      reason,
      res.locals.requestId,
    ),
  );
});

contentRouter.get('/reviews/:id', async (req, res) => {
  ok(res, await content.reviewHistory(parse(idParams, req.params).id));
});
