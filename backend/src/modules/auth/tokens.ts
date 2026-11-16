import jwt from 'jsonwebtoken';
import type { Role } from '@prisma/client';
import { env } from '../../config/env';
import { Errors } from '../../common/errors';

type AccessClaims = { sub: string; role: Role; sid: string };

export function signAccessToken(userId: string, role: Role, sessionId: string): string {
  const claims: AccessClaims = { sub: userId, role, sid: sessionId };
  return jwt.sign(claims, env.JWT_ACCESS_SECRET, {
    algorithm: 'HS256',
    expiresIn: env.ACCESS_TOKEN_TTL_SECONDS,
    issuer: 'theracare',
  });
}

export function verifyAccessToken(token: string) {
  try {
    const claims = jwt.verify(token, env.JWT_ACCESS_SECRET, {
      algorithms: ['HS256'],
      issuer: 'theracare',
    }) as AccessClaims;
    return { userId: claims.sub, role: claims.role, sessionId: claims.sid };
  } catch {
    throw Errors.unauthenticated();
  }
}
