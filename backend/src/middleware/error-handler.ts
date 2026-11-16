import type { NextFunction, Request, Response } from 'express';
import { Prisma } from '@prisma/client';
import { AppError } from '../common/errors';
import { logger } from '../config/logger';

function toAppError(err: unknown): AppError {
  if (err instanceof AppError) return err;
  if (err instanceof SyntaxError && 'body' in err) {
    return new AppError(400, 'MALFORMED_JSON', 'The request could not be read.');
  }
  if (err instanceof Prisma.PrismaClientKnownRequestError && err.code === 'P2002') {
    return new AppError(409, 'CONFLICT', 'This item already exists.');
  }
  return new AppError(
    500,
    'INTERNAL_ERROR',
    'Something went wrong on our side. Your data is safe. Please try again.',
  );
}

/** Never exposes stack traces, SQL errors or sensitive details to clients. */
export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction) {
  const appError = toAppError(err);
  if (appError.status >= 500) {
    logger.error({ err, requestId: res.locals.requestId, path: req.path }, 'unhandled error');
  }
  res.status(appError.status).json({
    success: false,
    error: { code: appError.code, message: appError.message, fields: appError.fields },
    meta: { requestId: res.locals.requestId },
  });
}

export function notFoundHandler(_req: Request, res: Response) {
  res.status(404).json({
    success: false,
    error: { code: 'ROUTE_NOT_FOUND', message: 'This address does not exist.' },
    meta: { requestId: res.locals.requestId },
  });
}
