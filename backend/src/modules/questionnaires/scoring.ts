import type { Question } from '@prisma/client';

export type AnswerMap = Map<string, unknown>;
type Scorer = (questions: Question[], answers: AnswerMap) => number | null;

/**
 * Approved scoring algorithms, referenced by name + version from questionnaire
 * definitions. Adding an algorithm never changes existing ones.
 */
const SCORERS: Record<string, Scorer> = {
  /** Sum of numeric and Likert answers. */
  sum_v1: (questions, answers) =>
    questions
      .filter((q) => q.type === 'NUMERIC' || q.type === 'LIKERT')
      .reduce((sum, q) => sum + (Number(answers.get(q.id)) || 0), 0),
  /** Unscored check-ins. */
  none_v1: () => null,
};

export function score(algorithm: string, questions: Question[], answers: AnswerMap): number | null {
  const scorer = SCORERS[algorithm];
  if (!scorer) throw new Error(`Unknown scoring algorithm: ${algorithm}`);
  return scorer(questions, answers);
}
