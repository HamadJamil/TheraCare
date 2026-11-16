import type {
  Observation,
  PatientProfile,
  PatientTreatment,
  Question,
  Questionnaire,
  QuestionnaireAnswer,
  QuestionnaireResponse,
  TreatmentVersion,
  User,
} from '@prisma/client';
import { pickLocale, type Locale } from '../../common/localized';
import { INSTRUMENTS } from '../tracking/instruments';

/**
 * Maps internal records to FHIR R4 resources. The database schema stays
 * independent of FHIR; this is the only place that knows both.
 */
export const FHIR_VERSION = '4.0.1';
export const SYSTEM = 'https://theracare.example/fhir';
const UCUM = 'http://unitsofmeasure.org';

export type Resource = { resourceType: string; id: string; [key: string]: unknown };
export const ref = (r: Resource) => `${r.resourceType}/${r.id}`;

const QUESTION_TYPE: Record<Question['type'], string> = {
  SINGLE_CHOICE: 'choice',
  MULTI_CHOICE: 'choice',
  LIKERT: 'choice',
  YES_NO: 'boolean',
  NUMERIC: 'integer',
  DATE: 'date',
  SHORT_TEXT: 'string',
  LONG_TEXT: 'text',
};

export function toPatient(user: User, profile: PatientProfile | null): Resource {
  return {
    resourceType: 'Patient',
    id: user.id,
    meta: { profile: [`${SYSTEM}/StructureDefinition/theracare-patient`] },
    identifier: [{ system: `${SYSTEM}/patient-id`, value: user.id }],
    name: profile
      ? [{ use: 'official', family: profile.lastName, given: [profile.firstName] }]
      : undefined,
    birthDate: profile?.dateOfBirth?.toISOString().slice(0, 10),
    communication: profile
      ? [{ language: { coding: [{ system: 'urn:ietf:bcp:47', code: profile.preferredLanguage }] } }]
      : undefined,
  };
}

export function toObservation(o: Observation, patient: Resource, locale: Locale): Resource {
  const instrument = INSTRUMENTS[o.kind];
  const coding: { system: string; code: string; display: string }[] = [
    {
      system: `${SYSTEM}/CodeSystem/observation-kind`,
      code: o.kind,
      display: pickLocale(instrument.title, locale),
    },
  ];
  if (instrument.loinc)
    coding.unshift({
      system: 'http://loinc.org',
      code: instrument.loinc.code,
      display: instrument.loinc.display,
    });
  return {
    resourceType: 'Observation',
    id: o.id,
    status: o.status === 'CURRENT' ? (o.supersedesId ? 'amended' : 'final') : 'entered-in-error',
    category: [
      {
        coding: [
          {
            system: 'http://terminology.hl7.org/CodeSystem/observation-category',
            code: 'survey',
            display: 'Survey',
          },
        ],
      },
    ],
    code: { coding, text: pickLocale(instrument.title, locale) },
    subject: { reference: ref(patient) },
    effectiveDateTime: o.effectiveAt.toISOString(),
    issued: o.recordedAt.toISOString(),
    valueQuantity: { value: o.value, unit: 'score', system: UCUM, code: instrument.unit },
    referenceRange: [{ low: { value: instrument.min }, high: { value: instrument.max } }],
    note: o.note ? [{ text: o.note }] : undefined,
  };
}

export function toQuestionnaire(
  q: Questionnaire & { questions: Question[] },
  locale: Locale,
): Resource {
  return {
    resourceType: 'Questionnaire',
    id: q.id,
    url: `${SYSTEM}/Questionnaire/${q.key}`,
    version: String(q.version),
    name: q.key.replace(/[^A-Za-z0-9]/g, '_'),
    title: pickLocale(q.title, locale),
    status: q.status === 'RETIRED' ? 'retired' : 'active',
    item: q.questions.map((question) => ({
      linkId: question.key,
      text: pickLocale(question.prompt, locale),
      type: QUESTION_TYPE[question.type],
      required: question.required,
      repeats: question.type === 'MULTI_CHOICE' || undefined,
      answerOption: (
        (question.options as { value: string | number; label: unknown }[] | null) ?? []
      ).map((o) => ({
        valueCoding: { code: String(o.value), display: pickLocale(o.label, locale) },
      })),
    })),
  };
}

function answerValue(question: Question, value: unknown) {
  const values = Array.isArray(value) ? value : [value];
  return values.map((v) => {
    switch (QUESTION_TYPE[question.type]) {
      case 'choice':
        return { valueCoding: { code: String(v) } };
      case 'boolean':
        return { valueBoolean: v };
      case 'integer':
        return { valueInteger: v };
      case 'date':
        return { valueDate: v };
      default:
        return { valueString: v };
    }
  });
}

export function toQuestionnaireResponse(
  r: QuestionnaireResponse & { answers: (QuestionnaireAnswer & { question: Question })[] },
  questionnaire: Resource & { url?: unknown; version?: unknown },
  patient: Resource,
): Resource {
  return {
    resourceType: 'QuestionnaireResponse',
    id: r.id,
    questionnaire: `${questionnaire.url}|${questionnaire.version}`,
    status: 'completed',
    subject: { reference: ref(patient) },
    authored: r.submittedAt?.toISOString(),
    extension:
      r.score === null
        ? undefined
        : [
            { url: `${SYSTEM}/StructureDefinition/score`, valueDecimal: r.score },
            { url: `${SYSTEM}/StructureDefinition/scoring-version`, valueString: r.scoringVersion },
          ],
    item: r.answers.map((a) => ({
      linkId: a.question.key,
      answer: answerValue(a.question, a.value),
    })),
  };
}

export function toCarePlan(
  t: PatientTreatment & { treatmentVersion: TreatmentVersion },
  patient: Resource,
  locale: Locale,
): Resource {
  const status = {
    ACTIVE: 'active',
    AWAITING_FINAL_ASSESSMENT: 'active',
    COMPLETED: 'completed',
    ENDED: 'revoked',
  }[t.status];
  return {
    resourceType: 'CarePlan',
    id: t.id,
    status,
    intent: 'plan',
    title: pickLocale(t.treatmentVersion.title, locale),
    description: (t.treatmentVersion.objectives as unknown[])
      .map((o) => pickLocale(o, locale))
      .join('; '),
    subject: { reference: ref(patient) },
    period: { start: t.startedAt.toISOString(), end: t.endsAt.toISOString() },
    instantiatesUri: [
      `${SYSTEM}/PlanDefinition/${t.treatmentVersionId}|${t.treatmentVersion.version}`,
    ],
  };
}

export function toBundle(resources: Resource[]) {
  return {
    resourceType: 'Bundle',
    type: 'collection',
    timestamp: new Date().toISOString(),
    meta: { profile: [`${SYSTEM}/StructureDefinition/theracare-export-bundle`] },
    entry: resources.map((resource) => ({ fullUrl: `urn:uuid:${resource.id}`, resource })),
  };
}

export type Bundle = ReturnType<typeof toBundle>;
