import type { Report, ReportKind } from '@prisma/client';
import { prisma } from '../../config/database';
import { logger } from '../../config/logger';
import { AppError, Errors } from '../../common/errors';
import type { Locale } from '../../common/localized';
import { getObject, putObject } from '../../infrastructure/storage';
import { audit } from '../audit/audit.service';
import { GENERATORS } from './generators';

const running = new Set<Promise<void>>();

/** Waits for background generation jobs (used by graceful shutdown and tests). */
export async function drainReportJobs() {
  await Promise.all([...running]);
}

async function generate(report: Report, locale: Locale) {
  try {
    const file = await GENERATORS[report.kind](report.userId, locale);
    const storageKey = await putObject(file.content);
    await prisma.report.update({
      where: { id: report.id },
      data: {
        status: 'READY',
        storageKey,
        fileName: file.fileName,
        contentType: file.contentType,
        completedAt: new Date(),
        failureCode: null,
      },
    });
  } catch (err) {
    logger.warn({ err, reportId: report.id }, 'report generation failed');
    await prisma.report.update({
      where: { id: report.id },
      data: {
        status: 'FAILED',
        failureCode: err instanceof AppError ? err.code : 'GENERATION_FAILED',
      },
    });
  }
}

/** Runs generation asynchronously; the client polls the status endpoint. */
function enqueue(report: Report, locale: Locale) {
  const job = generate(report, locale).finally(() => running.delete(job));
  running.add(job);
}

export const reportView = (r: Report) => ({
  id: r.id,
  kind: r.kind,
  status: r.status,
  fileName: r.fileName,
  failureCode: r.failureCode,
  createdAt: r.createdAt,
  completedAt: r.completedAt,
});

export async function requestReport(
  userId: string,
  kind: ReportKind,
  locale: Locale,
  requestId?: string,
) {
  const report = await prisma.report.create({ data: { userId, kind } });
  await audit({
    action: 'export.requested',
    resourceType: 'report',
    resourceId: report.id,
    actorId: userId,
    requestId,
    sourceContext: { kind },
  });
  enqueue(report, locale);
  return reportView(report);
}

async function ownReport(userId: string, reportId: string, kind?: ReportKind) {
  const report = await prisma.report.findFirst({ where: { id: reportId, userId, kind } });
  if (!report) throw Errors.notFound('The report');
  return report;
}

export async function getReport(userId: string, reportId: string, kind?: ReportKind) {
  return reportView(await ownReport(userId, reportId, kind));
}

/** Safe retry: only failed reports are regenerated; ready ones are returned unchanged. */
export async function retryReport(userId: string, reportId: string, locale: Locale) {
  const report = await ownReport(userId, reportId);
  if (report.status !== 'FAILED') return reportView(report);
  const pending = await prisma.report.update({
    where: { id: report.id },
    data: { status: 'PENDING', failureCode: null },
  });
  enqueue(pending, locale);
  return reportView(pending);
}

export async function listReports(userId: string, kind?: ReportKind) {
  const rows = await prisma.report.findMany({
    where: { userId, kind },
    orderBy: { createdAt: 'desc' },
    take: 50,
  });
  return rows.map(reportView);
}

export async function downloadReport(
  userId: string,
  reportId: string,
  requestId?: string,
  kind?: ReportKind,
) {
  const report = await ownReport(userId, reportId, kind);
  if (report.status !== 'READY' || !report.storageKey) {
    throw new AppError(
      409,
      'REPORT_NOT_READY',
      'The file is still being prepared. Please try again in a moment.',
    );
  }
  await audit({
    action: 'export.downloaded',
    resourceType: 'report',
    resourceId: report.id,
    actorId: userId,
    requestId,
  });
  return {
    content: await getObject(report.storageKey),
    fileName: report.fileName!,
    contentType: report.contentType!,
  };
}
