import { Router, type Request } from 'express';
import { created, ok } from '../../common/http';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { authLimiter } from '../../middleware/rate-limit';
import * as auth from './auth.service';
import {
  emailOnlySchema,
  loginSchema,
  refreshSchema,
  registerSchema,
  resetPasswordSchema,
  sessionIdParams,
  verifyEmailSchema,
} from './auth.schemas';

const ctx = (req: Request, deviceLabel?: string) => ({
  requestId: req.res?.locals.requestId as string | undefined,
  deviceLabel,
});

const GENERIC_SENT = {
  message: 'If this email address can be used, we have sent you a message.',
};

export const authRouter = Router();

authRouter.post('/register', authLimiter, async (req, res) => {
  await auth.register(parse(registerSchema, req.body), ctx(req));
  ok(res, GENERIC_SENT, 202);
});

authRouter.post('/verify-email', authLimiter, async (req, res) => {
  const body = parse(verifyEmailSchema, req.body);
  created(res, await auth.verifyEmail(body.email, body.code, ctx(req, body.deviceLabel)));
});

authRouter.post('/resend-verification', authLimiter, async (req, res) => {
  await auth.resendVerification(parse(emailOnlySchema, req.body).email);
  ok(res, GENERIC_SENT, 202);
});

authRouter.post('/login', authLimiter, async (req, res) => {
  const body = parse(loginSchema, req.body);
  ok(res, await auth.login(body.email, body.password, ctx(req, body.deviceLabel)));
});

authRouter.post('/refresh', authLimiter, async (req, res) => {
  ok(res, await auth.refresh(parse(refreshSchema, req.body).refreshToken, ctx(req)));
});

authRouter.post('/logout', authenticate, async (req, res) => {
  await auth.logout(authOf(req).sessionId);
  ok(res, { loggedOut: true });
});

authRouter.post('/forgot-password', authLimiter, async (req, res) => {
  await auth.forgotPassword(parse(emailOnlySchema, req.body).email, ctx(req));
  ok(res, GENERIC_SENT, 202);
});

authRouter.post('/reset-password', authLimiter, async (req, res) => {
  const body = parse(resetPasswordSchema, req.body);
  await auth.resetPassword(body.token, body.password, ctx(req));
  ok(res, { passwordChanged: true });
});

authRouter.get('/sessions', authenticate, async (req, res) => {
  const { userId, sessionId } = authOf(req);
  ok(res, await auth.listSessions(userId, sessionId));
});

authRouter.delete('/sessions/:id', authenticate, async (req, res) => {
  const { id } = parse(sessionIdParams, req.params);
  await auth.revokeSession(authOf(req).userId, id, ctx(req).requestId);
  ok(res, { revoked: true });
});
