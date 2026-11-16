import { Router } from 'express';
import { z } from 'zod';
import { created, ok } from '../../common/http';
import { localeOf } from '../../common/locale';
import { idParams } from '../../common/schemas';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { idempotent } from '../../middleware/idempotency';
import { requireTreatmentAccess } from '../../middleware/treatment-access';
import * as questionnaires from './questionnaires.service';

const answersSchema = z
  .object({
    answers: z
      .array(z.object({ questionKey: z.string().min(1).max(64), value: z.unknown() }).strict())
      .max(200),
  })
  .strict();

export const questionnairesRouter = Router();
questionnairesRouter.use(authenticate, requireTreatmentAccess);

questionnairesRouter.get('/', async (req, res) => {
  ok(res, await questionnaires.listAssigned(authOf(req).userId, localeOf(req)));
});

questionnairesRouter.get('/:id', async (req, res) => {
  const { id } = parse(idParams, req.params);
  ok(res, await questionnaires.getDefinition(authOf(req).userId, id, localeOf(req)));
});

questionnairesRouter.post('/:id/drafts', async (req, res) => {
  const { id } = parse(idParams, req.params);
  const { answers } = parse(answersSchema, req.body);
  ok(res, await questionnaires.saveDraft(authOf(req).userId, id, answers));
});

questionnairesRouter.post(
  '/:id/responses',
  idempotent('questionnaire.submit'),
  async (req, res) => {
    const { id } = parse(idParams, req.params);
    const { answers } = parse(answersSchema, req.body);
    created(
      res,
      await questionnaires.submit(authOf(req).userId, id, answers, res.locals.requestId),
    );
  },
);
