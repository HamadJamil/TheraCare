import { Router } from 'express';
import { ok } from '../../common/http';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { requireVerified } from '../../middleware/authorize';
import { authLimiter } from '../../middleware/rate-limit';
import { confirmEmailChange, startEmailChange } from '../auth/auth.service';
import { getJourney } from '../journey/journey.service';
import * as patients from './patients.service';
import {
  closeAccountSchema,
  emailChangeSchema,
  emailConfirmSchema,
  updatePreferencesSchema,
  updateProfileSchema,
} from './patients.schemas';

export const patientsRouter = Router();
patientsRouter.use(authenticate);

patientsRouter.get('/me', async (req, res) => {
  ok(res, await patients.getMe(authOf(req).userId));
});

patientsRouter.get('/me/journey', async (req, res) => {
  ok(res, await getJourney(authOf(req).userId));
});

patientsRouter.patch('/me', requireVerified, async (req, res) => {
  const data = parse(updateProfileSchema, req.body);
  ok(res, await patients.updateProfile(authOf(req).userId, data, res.locals.requestId));
});

patientsRouter.get('/me/preferences', async (req, res) => {
  ok(res, await patients.getPreferences(authOf(req).userId));
});

patientsRouter.patch('/me/preferences', async (req, res) => {
  ok(
    res,
    await patients.updatePreferences(authOf(req).userId, parse(updatePreferencesSchema, req.body)),
  );
});

patientsRouter.post('/me/email', requireVerified, authLimiter, async (req, res) => {
  const body = parse(emailChangeSchema, req.body);
  await startEmailChange(authOf(req).userId, body.password, body.newEmail);
  ok(res, { message: 'If this email address can be used, we have sent a code to it.' }, 202);
});

patientsRouter.post('/me/email/confirm', requireVerified, authLimiter, async (req, res) => {
  const { code } = parse(emailConfirmSchema, req.body);
  ok(res, await confirmEmailChange(authOf(req).userId, code, { requestId: res.locals.requestId }));
});

patientsRouter.post('/me/close', authLimiter, async (req, res) => {
  const { password } = parse(closeAccountSchema, req.body);
  ok(res, await patients.closeAccount(authOf(req).userId, password, res.locals.requestId));
});
