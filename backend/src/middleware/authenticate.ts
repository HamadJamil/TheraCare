import type { NextFunction, Request, Response } from 'express';
import { Errors } from '../common/errors';
import { verifyAccessToken } from '../modules/auth/tokens';

/** Verifies the bearer access token. Authorization is checked separately per route. */
export function authenticate(req: Request, _res: Response, next: NextFunction) {
  const header = req.header('authorization');
  if (!header?.startsWith('Bearer ')) throw Errors.unauthenticated();
  req.auth = verifyAccessToken(header.slice('Bearer '.length));
  next();
}

export function authOf(req: Request) {
  if (!req.auth) throw Errors.unauthenticated();
  return req.auth;
}
