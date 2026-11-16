import { Router } from 'express';
import { z } from 'zod';
import { ok } from '../../common/http';
import { localeOf } from '../../common/locale';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { requireTreatmentAccess } from '../../middleware/treatment-access';
import * as progress from './progress.service';

const weeklyQuery = z.object({ weeks: z.coerce.number().int().min(1).max(12).default(4) });

export const progressRouter = Router();
progressRouter.use(authenticate, requireTreatmentAccess);

progressRouter.get('/overview', async (req, res) => {
  ok(res, await progress.overview(authOf(req).userId, localeOf(req)));
});

progressRouter.get('/weekly', async (req, res) => {
  const { weeks } = parse(weeklyQuery, req.query);
  ok(res, await progress.weekly(authOf(req).userId, weeks, localeOf(req)));
});
