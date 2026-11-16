import type { NextFunction, Request, Response } from 'express';
import type { Role } from '@prisma/client';
import { Errors } from '../common/errors';
import { prisma } from '../config/database';
import { authOf } from './authenticate';

type Handler = (req: Request, res: Response, next: NextFunction) => Promise<void> | void;

/** Role-based access for staff endpoints. */
export function requireRole(...roles: Role[]): Handler {
  return (req, _res, next) => {
    if (!roles.includes(authOf(req).role)) throw Errors.forbidden();
    next();
  };
}

/** The account must have a verified email address. */
export const requireVerified: Handler = async (req, _res, next) => {
  const user = await prisma.user.findUnique({ where: { id: authOf(req).userId } });
  if (user?.status !== 'ACTIVE') {
    throw Errors.precondition('EMAIL_NOT_VERIFIED', 'Please confirm your email address first.');
  }
  next();
};
