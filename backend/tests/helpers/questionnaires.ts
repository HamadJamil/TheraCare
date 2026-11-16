import { api } from './app';
import type { TestUser } from './users';

export const BACK_CHECK_KEYS = [
  'pain-now',
  'sitting',
  'walking',
  'sleeping',
  'lifting',
  'chores',
  'worry',
];

/** Answers for the back check: pain value plus the same Likert value for every item. */
export function backCheckAnswers(pain: number, likert: number) {
  return BACK_CHECK_KEYS.map((questionKey) => ({
    questionKey,
    value: questionKey === 'pain-now' ? pain : likert,
  }));
}

export async function questionnaireByKey(user: TestUser, key: string) {
  const res = await api()
    .get('/api/v1/questionnaires')
    .set('authorization', user.bearer)
    .expect(200);
  return res.body.data.find((q: { key: string }) => q.key === key) as
    { id: string; status: string } | undefined;
}
