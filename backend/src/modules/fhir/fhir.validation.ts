import { z } from 'zod';
import type { Bundle } from './fhir.mappers';

/**
 * Structural validation against the documented TheraCare export profile.
 * This is a prototype check — a production system would also run the official
 * HL7 validator against published profiles and terminology servers.
 */
const reference = z.object({ reference: z.string().regex(/^(Patient)\/[0-9a-f-]{36}$/) });
const instant = z.string().datetime();
const coding = z.object({ system: z.string().url(), code: z.string().min(1) });

const SCHEMAS: Record<string, z.ZodTypeAny> = {
  Patient: z.object({ id: z.string().uuid(), identifier: z.array(z.unknown()).min(1) }),
  Observation: z.object({
    id: z.string().uuid(),
    status: z.enum(['final', 'amended', 'entered-in-error']),
    code: z.object({ coding: z.array(coding).min(1) }),
    subject: reference,
    effectiveDateTime: instant,
    valueQuantity: z.object({
      value: z.number(),
      system: z.literal('http://unitsofmeasure.org'),
      code: z.string(),
    }),
  }),
  Questionnaire: z.object({
    id: z.string().uuid(),
    url: z.string().url(),
    version: z.string(),
    status: z.string(),
    item: z.array(z.object({ linkId: z.string(), type: z.string() })),
  }),
  QuestionnaireResponse: z.object({
    id: z.string().uuid(),
    questionnaire: z.string().includes('|'),
    status: z.literal('completed'),
    subject: reference,
    authored: instant,
    item: z.array(z.object({ linkId: z.string(), answer: z.array(z.record(z.unknown())).min(1) })),
  }),
  CarePlan: z.object({
    id: z.string().uuid(),
    status: z.enum(['active', 'completed', 'revoked']),
    intent: z.literal('plan'),
    subject: reference,
    period: z.object({ start: instant, end: instant }),
  }),
};

export type ValidationIssue = { resource: string; message: string };

export function validateBundle(bundle: Bundle): ValidationIssue[] {
  const issues: ValidationIssue[] = [];
  const ids = new Set(bundle.entry.map((e) => `${e.resource.resourceType}/${e.resource.id}`));
  for (const { resource } of bundle.entry) {
    const label = `${resource.resourceType}/${resource.id}`;
    const schema = SCHEMAS[resource.resourceType];
    if (!schema) {
      issues.push({ resource: label, message: 'Resource type is not part of the export profile.' });
      continue;
    }
    const result = schema.safeParse(resource);
    if (!result.success) {
      for (const issue of result.error.issues)
        issues.push({ resource: label, message: `${issue.path.join('.')}: ${issue.message}` });
    }
    const subject = (resource.subject as { reference?: string } | undefined)?.reference;
    if (subject && !ids.has(subject))
      issues.push({ resource: label, message: `Unresolved reference ${subject}` });
  }
  if (bundle.entry.filter((e) => e.resource.resourceType === 'Patient').length !== 1) {
    issues.push({ resource: 'Bundle', message: 'Exactly one Patient is required.' });
  }
  return issues;
}
