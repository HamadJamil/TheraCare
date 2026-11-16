import type { PrismaClient } from '@prisma/client';

const CONSENT_TYPES = [
  {
    key: 'privacy-policy',
    policyVersion: '2026-11',
    required: true,
    title: { de: 'Datenschutzhinweise', en: 'Privacy notice' },
    summary: {
      de: 'Wir erklären, welche Daten TheraCare speichert und warum.',
      en: 'We explain which data TheraCare stores and why.',
    },
    details: {
      de: 'TheraCare speichert Ihre Kontodaten, Übungen, Schmerzangaben und Fragebögen, um Ihre Therapie bereitzustellen. Die Daten werden verschlüsselt übertragen und nur in der EU verarbeitet. Sie können Ihre Daten exportieren und Ihr Konto schließen.',
      en: 'TheraCare stores your account details, exercises, pain entries and questionnaires to provide your therapy. Data is encrypted in transit and processed only in the EU. You can export your data and close your account.',
    },
  },
  {
    key: 'health-data-processing',
    policyVersion: '2026-11',
    required: true,
    title: { de: 'Verarbeitung von Gesundheitsdaten', en: 'Processing of health data' },
    summary: {
      de: 'Ihre Gesundheitsangaben werden nur für Ihre Therapie verwendet.',
      en: 'Your health information is used only for your therapy.',
    },
    details: {
      de: 'Damit TheraCare Ihnen Übungen zuweisen und Ihren Fortschritt zeigen kann, verarbeiten wir Ihre Angaben zu Schmerzen und Beweglichkeit. Ohne diese Einwilligung kann die Therapie nicht genutzt werden.',
      en: 'To assign exercises and show your progress, TheraCare processes your pain and mobility information. Without this consent the therapy cannot be used.',
    },
  },
  {
    key: 'technical-improvement',
    policyVersion: '2026-11',
    required: false,
    title: { de: 'Technische Verbesserung (freiwillig)', en: 'Technical improvement (optional)' },
    summary: {
      de: 'Anonyme technische Daten helfen uns, Fehler zu finden.',
      en: 'Anonymous technical data helps us find errors.',
    },
    details: {
      de: 'Freiwillig: Wir erfassen anonyme Absturzberichte und Ladezeiten. Keine Gesundheitsdaten. Ihre Therapie funktioniert auch ohne diese Einwilligung.',
      en: 'Optional: we collect anonymous crash reports and loading times. No health data. Your therapy works without this consent.',
    },
  },
];

export async function seedConsentTypes(prisma: PrismaClient) {
  for (const type of CONSENT_TYPES) {
    await prisma.consentType.upsert({
      where: { key_policyVersion: { key: type.key, policyVersion: type.policyVersion } },
      create: type,
      update: {},
    });
  }
}
