import type { NextFunction, Request, Response } from 'express';
import { Errors } from '../common/errors';
import { prisma } from '../config/database';
import { authOf } from './authenticate';
import { hasActiveEntitlement } from '../modules/activations/activations.service';
import { hasRequiredConsents } from '../modules/consents/consents.service';

/**
 * Treatment data requires a verified account, an active entitlement and all
 * required consents. Enforced on the server — client route guards are UX only.
 */
export async function ensureTreatmentAccess(userId: string) {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (user?.status !== 'ACTIVE') {
    throw Errors.precondition('EMAIL_NOT_VERIFIED', 'Please confirm your email address first.');
  }
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
}

export async function requireTreatmentAccess(req: Request, _res: Response, next: NextFunction) {
  await ensureTreatmentAccess(authOf(req).userId);
  next();
}
