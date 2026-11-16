import { createHash } from 'node:crypto';
import type { NextFunction, Request, Response } from 'express';
import type { Prisma } from '@prisma/client';
import { AppError } from '../common/errors';
import { addDays } from '../common/dates';
import { prisma } from '../config/database';
import { authOf } from './authenticate';

const KEY_PATTERN = /^[A-Za-z0-9-]{8,128}$/;

/**
 * Replays the stored response when a client retries a non-idempotent request
 * with the same `Idempotency-Key`. Requests without the header pass through.
 */
export function idempotent(scope: string) {
  return async (req: Request, res: Response, next: NextFunction) => {
    const key = req.header('idempotency-key');
    if (!key) return next();
    if (!KEY_PATTERN.test(key)) {
      throw new AppError(400, 'INVALID_IDEMPOTENCY_KEY', 'The request identifier is not valid.');
    }
    const { userId } = authOf(req);
    const requestHash = createHash('sha256')
      .update(`${req.originalUrl}:${JSON.stringify(req.body ?? {})}`)
      .digest('hex');
    const existing = await prisma.idempotencyRecord.findUnique({
      where: { userId_scope_key: { userId, scope, key } },
    });
    if (existing) {
      if (existing.requestHash !== requestHash) {
        throw new AppError(
          422,
          'IDEMPOTENCY_KEY_REUSED',
          'This request identifier was already used for different data.',
        );
      }
      res.setHeader('idempotent-replay', 'true');
      res.status(existing.responseStatus).json(existing.responseBody);
      return;
    }

    const send = res.json.bind(res);
    res.json = (body: unknown) => {
      if (res.statusCode >= 500) return send(body);
      // Persist before responding so an immediate retry is always replayed.
      prisma.idempotencyRecord
        .create({
          data: {
            userId,
            scope,
            key,
            requestHash,
            responseStatus: res.statusCode,
            responseBody: body as Prisma.InputJsonValue,
            expiresAt: addDays(new Date(), 1),
          },
        })
        .catch(() => undefined) // a concurrent duplicate already stored the result
        .finally(() => send(body));
      return res;
    };
    next();
  };
}
