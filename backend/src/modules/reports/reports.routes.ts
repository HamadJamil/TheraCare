import { Router, type Response } from 'express';
import { z } from 'zod';
import { created, ok } from '../../common/http';
import { localeOf } from '../../common/locale';
import { idParams } from '../../common/schemas';
import { parse } from '../../common/validation';
import { authenticate, authOf } from '../../middleware/authenticate';
import { requireTreatmentAccess } from '../../middleware/treatment-access';
import { capabilityStatement } from '../fhir/fhir.service';
import * as reports from './reports.service';

const createSchema = z.object({ kind: z.literal('TREATMENT_SUMMARY_PDF') }).strict();

function sendFile(res: Response, file: { content: Buffer; fileName: string; contentType: string }) {
  res.setHeader('content-type', file.contentType);
  res.setHeader('content-disposition', `attachment; filename="${file.fileName}"`);
  res.setHeader('cache-control', 'no-store');
  res.send(file.content);
}

/** Mounted at the API root: every route authenticates itself (except FHIR metadata). */
export const reportsRouter = Router();

// ───────────── Human-readable reports ─────────────

reportsRouter.get('/reports', authenticate, requireTreatmentAccess, async (req, res) => {
  ok(res, await reports.listReports(authOf(req).userId, 'TREATMENT_SUMMARY_PDF'));
});

reportsRouter.post('/reports', authenticate, requireTreatmentAccess, async (req, res) => {
  const { kind } = parse(createSchema, req.body);
  created(
    res,
    await reports.requestReport(authOf(req).userId, kind, localeOf(req), res.locals.requestId),
  );
});

reportsRouter.get('/reports/:id', authenticate, requireTreatmentAccess, async (req, res) => {
  ok(res, await reports.getReport(authOf(req).userId, parse(idParams, req.params).id));
});

reportsRouter.post(
  '/reports/:id/export',
  authenticate,
  requireTreatmentAccess,
  async (req, res) => {
    ok(
      res,
      await reports.retryReport(authOf(req).userId, parse(idParams, req.params).id, localeOf(req)),
    );
  },
);

reportsRouter.get(
  '/reports/:id/download',
  authenticate,
  requireTreatmentAccess,
  async (req, res) => {
    const { id } = parse(idParams, req.params);
    sendFile(res, await reports.downloadReport(authOf(req).userId, id, res.locals.requestId));
  },
);

// ───────────── FHIR export ─────────────

reportsRouter.get('/fhir/metadata', (_req, res) => {
  res.type('application/fhir+json').json(capabilityStatement());
});

reportsRouter.post('/fhir/exports', authenticate, requireTreatmentAccess, async (req, res) => {
  created(
    res,
    await reports.requestReport(
      authOf(req).userId,
      'FHIR_BUNDLE',
      localeOf(req),
      res.locals.requestId,
    ),
  );
});

reportsRouter.get('/fhir/exports/:id', authenticate, requireTreatmentAccess, async (req, res) => {
  ok(
    res,
    await reports.getReport(authOf(req).userId, parse(idParams, req.params).id, 'FHIR_BUNDLE'),
  );
});

reportsRouter.get(
  '/fhir/exports/:id/download',
  authenticate,
  requireTreatmentAccess,
  async (req, res) => {
    const { id } = parse(idParams, req.params);
    sendFile(
      res,
      await reports.downloadReport(authOf(req).userId, id, res.locals.requestId, 'FHIR_BUNDLE'),
    );
  },
);
