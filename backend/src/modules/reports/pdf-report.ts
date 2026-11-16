import PDFDocument from 'pdfkit';
import type { Locale } from '../../common/localized';
import type { TreatmentSummary } from './summary';

const T = {
  de: {
    title: 'TheraCare – Zusammenfassung Ihrer Therapie',
    patient: 'Name',
    period: 'Zeitraum',
    plan: 'Therapieplan',
    exercises: 'Übungen',
    exercisesLine: (n: number, d: number) => `${n} Übungen an ${d} Tagen abgeschlossen.`,
    pain: 'Schmerzangaben',
    painLine: (n: number) => `${n} Einträge.`,
    firstWeek: 'Durchschnitt erste Woche',
    lastWeek: 'Durchschnitt letzte Woche',
    assessments: 'Rücken-Check (0–34, niedriger ist besser)',
    baseline: 'Zu Beginn',
    final: 'Zum Abschluss',
    none: 'keine Angabe',
    limits:
      'Hinweis: Diese Zusammenfassung zeigt Ihre eigenen Eingaben. Sie ist keine medizinische Diagnose. Besprechen Sie Fragen bitte mit Ihrer Ärztin oder Ihrem Arzt. Demo-Projekt – kein zugelassenes Medizinprodukt.',
  },
  en: {
    title: 'TheraCare – Summary of your therapy',
    patient: 'Name',
    period: 'Period',
    plan: 'Treatment plan',
    exercises: 'Exercises',
    exercisesLine: (n: number, d: number) => `${n} exercises completed on ${d} days.`,
    pain: 'Pain entries',
    painLine: (n: number) => `${n} entries.`,
    firstWeek: 'Average in the first week',
    lastWeek: 'Average in the last week',
    assessments: 'Back check (0–34, lower is better)',
    baseline: 'At the start',
    final: 'At the end',
    none: 'not available',
    limits:
      'Note: this summary shows your own entries. It is not a medical diagnosis. Please discuss questions with your doctor. Demo project – not an approved medical device.',
  },
};

/** Accessible (tagged, titled, language-tagged) PDF with large type and simple structure. */
export function renderSummaryPdf(summary: TreatmentSummary, locale: Locale): Promise<Buffer> {
  const t = T[locale];
  const date = (d: Date) => d.toLocaleDateString(locale === 'de' ? 'de-DE' : 'en-GB');
  const value = (v: number | null) => (v === null ? t.none : String(v));

  const doc = new PDFDocument({
    size: 'A4',
    margin: 56,
    tagged: true,
    lang: locale,
    displayTitle: true,
    pdfVersion: '1.7',
    info: { Title: t.title, Author: 'TheraCare' },
  });
  const chunks: Buffer[] = [];
  doc.on('data', (c: Buffer) => chunks.push(c));
  const done = new Promise<Buffer>((resolve) =>
    doc.on('end', () => resolve(Buffer.concat(chunks))),
  );

  const heading = (text: string, size: number, type: 'H1' | 'H2') => {
    doc.addStructure(
      doc.struct(type, {}, () =>
        doc.font('Helvetica-Bold').fontSize(size).fillColor('#174A68').text(text),
      ),
    );
    doc.moveDown(0.4);
  };
  const paragraph = (text: string) => {
    doc.addStructure(
      doc.struct('P', {}, () =>
        doc.font('Helvetica').fontSize(14).fillColor('#263746').text(text, { lineGap: 4 }),
      ),
    );
    doc.moveDown(0.6);
  };

  heading(t.title, 22, 'H1');
  paragraph(`${t.patient}: ${summary.patient.name}`);
  paragraph(`${t.period}: ${date(summary.period.from)} – ${date(summary.period.to)}`);
  if (summary.plan) paragraph(`${t.plan}: ${summary.plan.title} (v${summary.plan.version})`);

  heading(t.exercises, 17, 'H2');
  paragraph(t.exercisesLine(summary.exercises.completed, summary.exercises.activeDays));

  heading(t.pain, 17, 'H2');
  paragraph(t.painLine(summary.pain.entries));
  paragraph(`${t.firstWeek}: ${value(summary.pain.firstWeekAverage)} / 10`);
  paragraph(`${t.lastWeek}: ${value(summary.pain.lastWeekAverage)} / 10`);

  heading(t.assessments, 17, 'H2');
  paragraph(`${t.baseline}: ${value(summary.assessments.baseline)}`);
  paragraph(`${t.final}: ${value(summary.assessments.final)}`);

  doc.moveDown();
  paragraph(t.limits);
  doc.end();
  return done;
}
