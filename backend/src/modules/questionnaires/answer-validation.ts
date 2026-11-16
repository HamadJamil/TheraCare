import type { Question } from '@prisma/client';

type Option = { value: string | number };
type Check = (q: Question, value: unknown) => string | null;

const optionValues = (q: Question) => ((q.options as Option[] | null) ?? []).map((o) => o.value);
const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

const text =
  (max: number): Check =>
  (_q, v) =>
    typeof v === 'string' && v.length <= max ? null : `Please write at most ${max} characters.`;

/** One validator per question type (open for extension without touching callers). */
const CHECKS: Record<Question['type'], Check> = {
  SINGLE_CHOICE: (q, v) =>
    optionValues(q).includes(v as never) ? null : 'Please choose one of the answers.',
  LIKERT: (q, v) =>
    optionValues(q).includes(v as never) ? null : 'Please choose one of the answers.',
  MULTI_CHOICE: (q, v) =>
    Array.isArray(v) && new Set(v).size === v.length && v.every((x) => optionValues(q).includes(x))
      ? null
      : 'Please choose from the listed answers.',
  YES_NO: (_q, v) => (typeof v === 'boolean' ? null : 'Please answer yes or no.'),
  NUMERIC: (q, v) =>
    Number.isInteger(v) &&
    (q.min === null || (v as number) >= q.min) &&
    (q.max === null || (v as number) <= q.max)
      ? null
      : `Please choose a whole number from ${q.min ?? ''} to ${q.max ?? ''}.`,
  DATE: (_q, v) =>
    typeof v === 'string' && ISO_DATE.test(v) && !Number.isNaN(Date.parse(v))
      ? null
      : 'Please enter a valid date.',
  SHORT_TEXT: text(200),
  LONG_TEXT: text(2000),
};

/** Returns a plain-language error for an invalid value, or null when valid. */
export function validateAnswer(question: Question, value: unknown): string | null {
  return CHECKS[question.type](question, value);
}

export function isEmpty(value: unknown): boolean {
  return (
    value === null ||
    value === undefined ||
    value === '' ||
    (Array.isArray(value) && value.length === 0)
  );
}
