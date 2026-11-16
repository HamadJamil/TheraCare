import type { ZodType, ZodTypeDef } from 'zod';
import { Errors, type FieldErrors } from './errors';

/** Parses untrusted input at the API boundary; throws a field-level VALIDATION_ERROR. */
export function parse<T>(schema: ZodType<T, ZodTypeDef, unknown>, input: unknown): T {
  const result = schema.safeParse(input);
  if (result.success) return result.data;
  const fields: FieldErrors = {};
  for (const issue of result.error.issues) {
    const path = issue.path.join('.') || '_';
    fields[path] ??= issue.message;
  }
  throw Errors.validation(fields);
}
