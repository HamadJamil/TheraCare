import type { ObservationKind } from '@prisma/client';
import type { Localized } from '../../common/localized';

export type Instrument = {
  kind: ObservationKind;
  min: number;
  max: number;
  unit: string;
  title: Localized;
  minLabel: Localized;
  maxLabel: Localized;
  /** LOINC code used for FHIR export, when one fits semantically. */
  loinc?: { code: string; display: string };
};

/** Configured measurement instruments. Values outside the range are rejected. */
export const INSTRUMENTS: Record<ObservationKind, Instrument> = {
  PAIN_INTENSITY: {
    kind: 'PAIN_INTENSITY',
    min: 0,
    max: 10,
    unit: '{score}',
    title: { de: 'Schmerzstärke', en: 'Pain intensity' },
    minLabel: { de: 'Keine Schmerzen', en: 'No pain' },
    maxLabel: { de: 'Stärkste vorstellbare Schmerzen', en: 'Worst pain imaginable' },
    loinc: {
      code: '72514-3',
      display: 'Pain severity - 0-10 verbal numeric rating [Score] - Reported',
    },
  },
  STIFFNESS: {
    kind: 'STIFFNESS',
    min: 0,
    max: 10,
    unit: '{score}',
    title: { de: 'Steifheit', en: 'Stiffness' },
    minLabel: { de: 'Keine Steifheit', en: 'No stiffness' },
    maxLabel: { de: 'Sehr steif', en: 'Very stiff' },
  },
  SLEEP_QUALITY: {
    kind: 'SLEEP_QUALITY',
    min: 0,
    max: 10,
    unit: '{score}',
    title: { de: 'Schlafqualität', en: 'Sleep quality' },
    minLabel: { de: 'Sehr schlecht', en: 'Very poor' },
    maxLabel: { de: 'Sehr gut', en: 'Very good' },
  },
  MOOD: {
    kind: 'MOOD',
    min: 1,
    max: 5,
    unit: '{score}',
    title: { de: 'Stimmung', en: 'Mood' },
    minLabel: { de: 'Sehr schlecht', en: 'Very low' },
    maxLabel: { de: 'Sehr gut', en: 'Very good' },
  },
};
