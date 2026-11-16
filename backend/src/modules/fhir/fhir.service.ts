import { prisma } from '../../config/database';
import { AppError } from '../../common/errors';
import type { Locale } from '../../common/localized';
import {
  FHIR_VERSION,
  SYSTEM,
  toBundle,
  toCarePlan,
  toObservation,
  toPatient,
  toQuestionnaire,
  toQuestionnaireResponse,
  type Resource,
} from './fhir.mappers';
import { validateBundle } from './fhir.validation';

/** Builds the patient's export bundle from their own records only. */
export async function buildPatientBundle(userId: string, locale: Locale) {
  const user = await prisma.user.findUniqueOrThrow({
    where: { id: userId },
    include: { profile: true },
  });
  const patient = toPatient(user, user.profile);
  const [observations, responses, treatments] = await Promise.all([
    prisma.observation.findMany({ where: { userId }, orderBy: { effectiveAt: 'asc' } }),
    prisma.questionnaireResponse.findMany({
      where: { userId, status: 'SUBMITTED' },
      include: {
        answers: { include: { question: true } },
        questionnaire: { include: { questions: { orderBy: { order: 'asc' } } } },
      },
    }),
    prisma.patientTreatment.findMany({ where: { userId }, include: { treatmentVersion: true } }),
  ]);

  const questionnaires = new Map<string, Resource>();
  for (const r of responses) {
    if (!questionnaires.has(r.questionnaireId))
      questionnaires.set(r.questionnaireId, toQuestionnaire(r.questionnaire, locale));
  }
  const bundle = toBundle([
    patient,
    ...treatments.map((t) => toCarePlan(t, patient, locale)),
    ...observations.map((o) => toObservation(o, patient, locale)),
    ...questionnaires.values(),
    ...responses.map((r) =>
      toQuestionnaireResponse(r, questionnaires.get(r.questionnaireId)!, patient),
    ),
  ]);

  const issues = validateBundle(bundle);
  if (issues.length > 0) {
    // Fail safely: never hand out an export that does not match the documented profile.
    throw new AppError(
      500,
      'FHIR_MAPPING_INVALID',
      'The export could not be created. Please try again later.',
    );
  }
  return bundle;
}

export function capabilityStatement() {
  return {
    resourceType: 'CapabilityStatement',
    status: 'active',
    date: '2026-11-16',
    kind: 'instance',
    fhirVersion: FHIR_VERSION,
    format: ['application/fhir+json'],
    implementation: { description: 'TheraCare FHIR export prototype (not connected to the ePA)' },
    rest: [
      {
        mode: 'server',
        documentation: 'Patient-initiated export only. Bundle of type collection.',
        resource: [
          'Patient',
          'Observation',
          'Questionnaire',
          'QuestionnaireResponse',
          'CarePlan',
        ].map((type) => ({
          type,
          profile: `${SYSTEM}/StructureDefinition/theracare-${type.toLowerCase()}`,
          interaction: [{ code: 'read' }],
        })),
      },
    ],
  };
}
