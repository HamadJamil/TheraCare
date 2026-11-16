import { Router } from 'express';
import { ok } from '../../common/http';
import { authenticate, authOf } from '../../middleware/authenticate';
import { requireTreatmentAccess } from '../../middleware/treatment-access';
import { getJourney } from '../journey/journey.service';
import { myAssessments, startOnboarding } from './assessments.service';

/** Mounted at the API root: every route authenticates itself. */
export const assessmentsRouter = Router();

assessmentsRouter.get('/onboarding', authenticate, requireTreatmentAccess, async (req, res) => {
  ok(res, await getJourney(authOf(req).userId));
});

assessmentsRouter.post(
  '/onboarding/start',
  authenticate,
  requireTreatmentAccess,
  async (req, res) => {
    ok(res, await startOnboarding(authOf(req).userId));
  },
);

assessmentsRouter.get('/assessments/me', authenticate, requireTreatmentAccess, async (req, res) => {
  ok(res, await myAssessments(authOf(req).userId));
});
