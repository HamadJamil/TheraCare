import { Router } from 'express';
import { z } from 'zod';
import { created, ok } from '../../common/http';
import { localeOf } from '../../common/locale';
import { idParams } from '../../common/schemas';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { requireRole } from '../../middleware/authorize';
import * as support from './support.service';

const ticketSchema = z
  .object({
    category: z.enum([
      'login',
      'activation',
      'exercises',
      'sync',
      'privacy',
      'accessibility',
      'other',
    ]),
    subject: z.string().trim().min(3, 'Please add a short subject.').max(120),
    message: z.string().trim().min(10, 'Please describe the problem in a few words.').max(2000),
  })
  .strict();

const status = z.enum(['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED']);
const updateSchema = z
  .object({ status: status.optional(), agentNote: z.string().max(1000).optional() })
  .strict();

/** Mounted at the API root: every route authenticates itself (except the FAQ). */
export const supportRouter = Router();

supportRouter.get('/support/faq', (req, res) => {
  ok(res, support.listFaq(localeOf(req)));
});

supportRouter.post('/support/tickets', authenticate, async (req, res) => {
  created(
    res,
    await support.createTicket(
      authOf(req).userId,
      parse(ticketSchema, req.body),
      res.locals.requestId,
    ),
  );
});

supportRouter.get('/support/tickets/me', authenticate, async (req, res) => {
  ok(res, await support.myTickets(authOf(req).userId));
});

supportRouter.get(
  '/admin/support/tickets',
  authenticate,
  requireRole('SUPPORT_AGENT', 'ADMIN'),
  async (req, res) => {
    const query = parse(z.object({ status: status.optional() }), req.query);
    ok(res, await support.staffTickets(query.status));
  },
);

supportRouter.patch(
  '/admin/support/tickets/:id',
  authenticate,
  requireRole('SUPPORT_AGENT', 'ADMIN'),
  async (req, res) => {
    const { id } = parse(idParams, req.params);
    const { userId, role } = authOf(req);
    ok(
      res,
      await support.updateTicket(
        id,
        parse(updateSchema, req.body),
        { userId, role: role as 'SUPPORT_AGENT' | 'ADMIN' },
        res.locals.requestId,
      ),
    );
  },
);
