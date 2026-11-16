import { Router } from 'express';
import { ok } from '../../common/http';
import { authenticate, authOf } from '../../middleware/authenticate';
import { myNotifications } from './notifications.service';

export const notificationsRouter = Router();
notificationsRouter.use(authenticate);

notificationsRouter.get('/me', async (req, res) => {
  ok(res, await myNotifications(authOf(req).userId));
});
