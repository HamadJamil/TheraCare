import type { Question } from '@prisma/client';
import { isEmpty, validateAnswer } from '../../src/modules/questionnaires/answer-validation';
import { score } from '../../src/modules/questionnaires/scoring';

const q = (overrides: Partial<Question>): Question => ({
  id: overrides.key ?? 'q',
  questionnaireId: 'x',
  key: 'q',
  order: 0,
  type: 'SHORT_TEXT',
  prompt: {},
  help: null,
  required: true,
  options: null,
  min: null,
  max: null,
  ...overrides,
});

describe('validateAnswer', () => {
  const choice = q({ type: 'SINGLE_CHOICE', options: [{ value: 'a' }, { value: 'b' }] });

  it.each([
    [choice, 'a', true],
    [choice, 'z', false],
    [q({ type: 'MULTI_CHOICE', options: [{ value: 'a' }, { value: 'b' }] }), ['a', 'b'], true],
    [q({ type: 'MULTI_CHOICE', options: [{ value: 'a' }] }), ['a', 'a'], false],
    [q({ type: 'YES_NO' }), true, true],
    [q({ type: 'YES_NO' }), 'yes', false],
    [q({ type: 'NUMERIC', min: 0, max: 10 }), 10, true],
    [q({ type: 'NUMERIC', min: 0, max: 10 }), 11, false],
    [q({ type: 'NUMERIC', min: 0, max: 10 }), 2.5, false],
    [q({ type: 'DATE' }), '2026-02-28', true],
    [q({ type: 'DATE' }), '28.02.2026', false],
    [q({ type: 'SHORT_TEXT' }), 'x'.repeat(201), false],
    [q({ type: 'LONG_TEXT' }), 'x'.repeat(2000), true],
  ])('validates %#', (question, value, valid) => {
    expect(validateAnswer(question, value) === null).toBe(valid);
  });

  it('treats blank values as empty', () => {
    expect([null, undefined, '', []].every(isEmpty)).toBe(true);
    expect(isEmpty(0)).toBe(false);
    expect(isEmpty(false)).toBe(false);
  });
});

describe('score', () => {
  const questions = [
    q({ key: 'n', type: 'NUMERIC' }),
    q({ key: 'l', type: 'LIKERT' }),
    q({ key: 't', type: 'SHORT_TEXT' }),
  ];

  it('sums numeric and Likert answers with sum_v1', () => {
    expect(
      score(
        'sum_v1',
        questions,
        new Map<string, unknown>([
          ['n', 6],
          ['l', 3],
          ['t', 'hello'],
        ]),
      ),
    ).toBe(9);
  });

  it('returns null for unscored check-ins', () => {
    expect(score('none_v1', questions, new Map())).toBeNull();
  });

  it('refuses unknown algorithms', () => {
    expect(() => score('magic', questions, new Map())).toThrow(/Unknown scoring/);
  });
});
