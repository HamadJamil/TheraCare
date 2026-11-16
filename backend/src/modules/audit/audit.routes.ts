import { Router } from 'express';
import { z } from 'zod';
import { ok } from '../../common/http';
import { pageArgs, paginationQuery, toPage } from '../../common/pagination';
import { parse } from '../../common/validation';
import { prisma } from '../../config/database';
import { authenticate } from '../../middleware/authenticate';
import { requireRole } from '../../middleware/authorize';

const query = paginationQuery.extend({
  action: z.string().max(64).optional(),
  actorId: z.string().uuid().optional(),
});

export const auditRouter = Router();

auditRouter.get(
  '/admin/audit-events',
  authenticate,
  requireRole('SECURITY_AUDITOR', 'ADMIN'),
  async (req, res) => {
    const q = parse(query, req.query);
    const rows = await prisma.auditEvent.findMany({
      where: { action: q.action, actorId: q.actorId },
      orderBy: [{ occurredAt: 'desc' }, { id: 'desc' }],
      ...pageArgs(q),
    });
    ok(res, toPage(rows, q.limit));
  },
);
