import type { ReportKind } from '@prisma/client';
import type { Locale } from '../../common/localized';
import { buildPatientBundle } from '../fhir/fhir.service';
import { renderSummaryPdf } from './pdf-report';
import { buildSummary } from './summary';

export type GeneratedFile = { content: Buffer; fileName: string; contentType: string };
type Generator = (userId: string, locale: Locale) => Promise<GeneratedFile>;

const stamp = () => new Date().toISOString().slice(0, 10);

/** One generator per report kind; new kinds are added here only. */
export const GENERATORS: Record<ReportKind, Generator> = {
  TREATMENT_SUMMARY_PDF: async (userId, locale) => ({
    content: await renderSummaryPdf(await buildSummary(userId, locale), locale),
    fileName: `theracare-summary-${stamp()}.pdf`,
    contentType: 'application/pdf',
  }),
  FHIR_BUNDLE: async (userId, locale) => ({
    content: Buffer.from(JSON.stringify(await buildPatientBundle(userId, locale), null, 2)),
    fileName: `theracare-fhir-export-${stamp()}.json`,
    contentType: 'application/fhir+json',
  }),
};
