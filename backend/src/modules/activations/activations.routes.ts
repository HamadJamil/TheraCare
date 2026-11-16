import { Router } from 'express';
import { z } from 'zod';
import { created, ok } from '../../common/http';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { requireVerified } from '../../middleware/authorize';
import { idempotent } from '../../middleware/idempotency';
import { activationLimiter } from '../../middleware/rate-limit';
import { activationStatus, currentEntitlement, redeem } from './activations.service';

const redeemSchema = z
  .object({ code: z.string().trim().min(8, 'Enter the full activation code.').max(32) })
  .strict();

export const activationsRouter = Router();

activationsRouter.post(
  '/activations/redeem',
  authenticate,
  requireVerified,
  activationLimiter,
  idempotent('activation.redeem'),
  async (req, res) => {
    const { code } = parse(redeemSchema, req.body);
    created(res, await redeem(authOf(req).userId, code, res.locals.requestId));
  },
);

activationsRouter.get('/activations/status', authenticate, async (req, res) => {
  ok(res, await activationStatus(authOf(req).userId));
});

activationsRouter.get('/entitlements/me', authenticate, async (req, res) => {
  ok(res, await currentEntitlement(authOf(req).userId));
});
