import type { NextFunction, Request, Response } from 'express';
import { Errors } from '../common/errors';
import { authOf } from './authenticate';
import { requireVerified } from './authorize';
import { hasActiveEntitlement } from '../modules/activations/activations.service';
import { hasRequiredConsents } from '../modules/consents/consents.service';

/**
 * Treatment data requires a verified account, an active entitlement and all
 * required consents. Enforced on the server — client route guards are UX only.
 */
export async function requireTreatmentAccess(req: Request, res: Response, next: NextFunction) {
  await requireVerified(req, res, () => undefined);
  const { userId } = authOf(req);
  if (!(await hasActiveEntitlement(userId))) {
    throw Errors.precondition(
      'ENTITLEMENT_REQUIRED',
      'Please activate TheraCare with your activation code.',
    );
  }
  if (!(await hasRequiredConsents(userId))) {
    throw Errors.precondition(
      'CONSENT_REQUIRED',
      'Please review the privacy information and give the required consent.',
    );
  }
  next();
}
