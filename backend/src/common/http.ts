import type { Response } from 'express';

/** Sends the standard success envelope: { success, data, meta: { requestId } }. */
export function ok<T>(res: Response, data: T, status = 200, extraMeta: object = {}) {
  res
    .status(status)
    .json({ success: true, data, meta: { requestId: res.locals.requestId, ...extraMeta } });
}

export function created<T>(res: Response, data: T) {
  ok(res, data, 201);
}
