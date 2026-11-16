import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { activateAndConsent, startTreatment } from '../helpers/fixtures';
import { backCheckAnswers, questionnaireByKey } from '../helpers/questionnaires';
import { signUp, type TestUser } from '../helpers/users';
import { addDays } from '../../src/common/dates';

let user: TestUser;

beforeEach(async () => {
  await resetDb();
  user = await signUp();
});
afterAll(() => prisma.$disconnect());

const get = (path: string) => api().get(`/api/v1${path}`).set('authorization', user.bearer);
const post = (path: string, body: object = {}) =>
  api().post(`/api/v1${path}`).set('authorization', user.bearer).send(body);
const journey = async () =>
  (await prisma.user.findUniqueOrThrow({ where: { email: user.email } })).journeyState;

describe('onboarding and baseline', () => {
  beforeEach(() => activateAndConsent(user));

  it('starts onboarding after privacy is complete', async () => {
    expect(await journey()).toBe('PRIVACY_COMPLETE');
    const res = await post('/onboarding/start').expect(200);
    expect(res.body.data.state).toBe('ONBOARDING_IN_PROGRESS');
  });

  it('offers the baseline questionnaire with localized questions', async () => {
    const baseline = await questionnaireByKey(user, 'back-check-baseline');
    expect(baseline?.status).toBe('NOT_STARTED');
    const def = await get(`/questionnaires/${baseline!.id}?lang=en`).expect(200);
    expect(def.body.data.questions).toHaveLength(7);
    expect(def.body.data.questions[0]).toMatchObject({
      key: 'pain-now',
      type: 'NUMERIC',
      min: 0,
      max: 10,
    });
    expect(def.body.data.questions[1].options[0].label).toBe('No difficulty');
  });

  it('saves and resumes a draft', async () => {
    const baseline = await questionnaireByKey(user, 'back-check-baseline');
    await post(`/questionnaires/${baseline!.id}/drafts`, {
      answers: [{ questionKey: 'pain-now', value: 6 }],
    }).expect(200);
    await post(`/questionnaires/${baseline!.id}/drafts`, {
      answers: [
        { questionKey: 'pain-now', value: 7 },
        { questionKey: 'sitting', value: 2 },
      ],
    }).expect(200);
    const def = await get(`/questionnaires/${baseline!.id}`).expect(200);
    expect(def.body.data.draft.answers).toEqual(
      expect.arrayContaining([
        { questionKey: 'pain-now', value: 7 },
        { questionKey: 'sitting', value: 2 },
      ]),
    );
    expect((await questionnaireByKey(user, 'back-check-baseline'))?.status).toBe('DRAFT');
  });

  it('identifies missing required answers and invalid values', async () => {
    const baseline = await questionnaireByKey(user, 'back-check-baseline');
    const res = await post(`/questionnaires/${baseline!.id}/responses`, {
      answers: [
        { questionKey: 'pain-now', value: 12 },
        { questionKey: 'sitting', value: 1 },
      ],
    }).expect(400);
    expect(res.body.error.fields['pain-now']).toMatch(/whole number/);
    expect(res.body.error.fields.walking).toBe('Please answer this question.');
  });

  it('submits, scores, assigns a plan and starts treatment', async () => {
    const baseline = await questionnaireByKey(user, 'back-check-baseline');
    const res = await api()
      .post(`/api/v1/questionnaires/${baseline!.id}/responses`)
      .set('authorization', user.bearer)
      .set('idempotency-key', 'baseline-submit-1')
      .send({ answers: backCheckAnswers(7, 3) })
      .expect(201);
    expect(res.body.data).toMatchObject({
      score: 25,
      scoringVersion: 'sum_v1@1',
      questionnaire: { version: 1 },
    });
    expect(res.body.data.treatmentId).toBeTruthy();
    expect(await journey()).toBe('TREATMENT_ACTIVE');

    const plan = await get('/treatments/current?lang=en').expect(200);
    expect(plan.body.data.plan.title).toBe('Gentle start');

    const replay = await api()
      .post(`/api/v1/questionnaires/${baseline!.id}/responses`)
      .set('authorization', user.bearer)
      .set('idempotency-key', 'baseline-submit-1')
      .send({ answers: backCheckAnswers(7, 3) })
      .expect(201);
    expect(replay.body.data.id).toBe(res.body.data.id);
    expect(await prisma.assessment.count()).toBe(1);
    expect(await prisma.patientTreatment.count()).toBe(1);
  });

  it('does not offer the baseline again once submitted', async () => {
    const baseline = await questionnaireByKey(user, 'back-check-baseline');
    await post(`/questionnaires/${baseline!.id}/responses`, {
      answers: backCheckAnswers(2, 1),
    }).expect(201);
    expect(await questionnaireByKey(user, 'back-check-baseline')).toBeUndefined();
    await post(`/questionnaires/${baseline!.id}/responses`, {
      answers: backCheckAnswers(2, 1),
    }).expect(404);
  });
});

describe('weekly check-in and final assessment', () => {
  it('accepts one weekly check-in per week', async () => {
    await startTreatment(user);
    const weekly = await questionnaireByKey(user, 'weekly-check-in');
    const answers = [
      { questionKey: 'week-overall', value: 'better' },
      { questionKey: 'week-exercises-ok', value: true },
      { questionKey: 'week-helped', value: ['exercises', 'heat'] },
    ];
    const res = await post(`/questionnaires/${weekly!.id}/responses`, { answers }).expect(201);
    expect(res.body.data.score).toBeNull();
    expect((await questionnaireByKey(user, 'weekly-check-in'))?.status).toBe('SUBMITTED');
    const again = await post(`/questionnaires/${weekly!.id}/responses`, { answers }).expect(409);
    expect(again.body.error.code).toBe('ALREADY_SUBMITTED');
  });

  it('completes treatment with the final assessment and compares scores', async () => {
    await activateAndConsent(user);
    const baseline = await questionnaireByKey(user, 'back-check-baseline');
    await post(`/questionnaires/${baseline!.id}/responses`, {
      answers: backCheckAnswers(8, 3),
    }).expect(201);
    await prisma.patientTreatment.updateMany({ data: { endsAt: addDays(new Date(), -1) } });
    await get('/treatments/current').expect(200);

    const final = await questionnaireByKey(user, 'back-check-final');
    expect(final).toBeDefined();
    await post(`/questionnaires/${final!.id}/responses`, {
      answers: backCheckAnswers(3, 1),
    }).expect(201);
    expect(await journey()).toBe('TREATMENT_COMPLETED');

    const assessments = await get('/assessments/me').expect(200);
    expect(assessments.body.data).toMatchObject({
      baseline: { score: 26 },
      final: { score: 9 },
      change: -17,
    });
  });

  it('hides questionnaires from other journey stages', async () => {
    await startTreatment(user);
    expect(await questionnaireByKey(user, 'back-check-final')).toBeUndefined();
    const final = await prisma.questionnaire.findFirstOrThrow({
      where: { key: 'back-check-final' },
    });
    await get(`/questionnaires/${final.id}`).expect(404);
  });
});
