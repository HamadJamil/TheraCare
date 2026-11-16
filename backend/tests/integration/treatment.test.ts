import { randomUUID } from 'node:crypto';
import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { activateAndConsent, startTreatment } from '../helpers/fixtures';
import { signUp, type TestUser } from '../helpers/users';
import { addDays } from '../../src/common/dates';

let user: TestUser;

beforeEach(async () => {
  await resetDb();
  user = await signUp();
});
afterAll(() => prisma.$disconnect());

const get = (path: string, as = user) =>
  api().get(`/api/v1${path}`).set('authorization', as.bearer);
const post = (path: string, body: object = {}, as = user) =>
  api().post(`/api/v1${path}`).set('authorization', as.bearer).send(body);

describe('treatment access', () => {
  it('requires entitlement before treatment data', async () => {
    const res = await get('/treatments/current').expect(412);
    expect(res.body.error.code).toBe('ENTITLEMENT_REQUIRED');
  });

  it('blocks treatment data after a required consent is withdrawn', async () => {
    await startTreatment(user);
    const consent = await prisma.consent.findFirstOrThrow({
      where: { consentType: { required: true } },
    });
    await post(`/consents/${consent.id}/withdraw`).expect(200);
    const res = await get('/treatments/current').expect(412);
    expect(res.body.error.code).toBe('CONSENT_REQUIRED');
  });

  it('returns null before a plan is assigned', async () => {
    await activateAndConsent(user);
    const res = await get('/treatments/current').expect(200);
    expect(res.body.data).toBeNull();
  });
});

describe('current plan', () => {
  it('assigns the plan matching the baseline score', async () => {
    await startTreatment(user, 25);
    const res = await get('/treatments/current?lang=en').expect(200);
    expect(res.body.data.plan).toMatchObject({ title: 'Gentle start', version: 1 });
    expect(res.body.data.today).toHaveLength(3);
    expect(res.body.data).toMatchObject({ week: 1, totalWeeks: 12, status: 'ACTIVE' });
  });

  it('assigns the active plan for a low score', async () => {
    await startTreatment(user, 5);
    const res = await get('/treatments/current?lang=en').expect(200);
    expect(res.body.data.plan.title).toBe('Active mobility');
  });

  it('moves to the final assessment when the period has ended', async () => {
    const treatment = await startTreatment(user);
    await prisma.patientTreatment.update({
      where: { id: treatment.id },
      data: { endsAt: addDays(new Date(), -1) },
    });
    const res = await get('/treatments/current').expect(200);
    expect(res.body.data.status).toBe('AWAITING_FINAL_ASSESSMENT');
    const db = await prisma.user.findUniqueOrThrow({ where: { email: user.email } });
    expect(db.journeyState).toBe('FINAL_ASSESSMENT');
  });

  it('shows a schedule only for the patient’s own plan', async () => {
    const treatment = await startTreatment(user);
    const res = await get(`/treatments/${treatment.id}/schedule`).expect(200);
    expect(res.body.data.weeks).toHaveLength(12);
    expect(res.body.data.weeks[0].days[0]).toMatchObject({ planned: 3, completed: 0 });

    const other = await signUp();
    await startTreatment(other);
    await get(`/treatments/${treatment.id}/schedule`, other).expect(404);
  });
});

describe('exercises and sessions', () => {
  it('lists assigned exercises with safety notes and versions', async () => {
    await startTreatment(user);
    const res = await get('/exercises?lang=en').expect(200);
    expect(res.body.data).toHaveLength(3);
    expect(res.body.data[0]).toMatchObject({ version: 1, title: 'Pelvic tilt' });
    expect(res.body.data[0].safetyNotes[0]).toMatch(/Stop immediately/);
  });

  it('does not serve exercises outside the assigned plan', async () => {
    await startTreatment(user, 25);
    const notAssigned = await prisma.exerciseVersion.findFirstOrThrow({
      where: { exercise: { key: 'bridge' } },
    });
    await get(`/exercises/${notAssigned.id}`).expect(404);
  });

  it('runs a session and records each completion once', async () => {
    const treatment = await startTreatment(user);
    const sessionClientId = randomUUID();
    const session = await post(`/treatments/${treatment.id}/sessions`, {
      clientId: sessionClientId,
    }).expect(201);
    const again = await post(`/treatments/${treatment.id}/sessions`, {
      clientId: sessionClientId,
    }).expect(201);
    expect(again.body.data.id).toBe(session.body.data.id);

    await post(`/sessions/${session.body.data.id}/pause`).expect(200);
    const resumed = await post(`/sessions/${session.body.data.id}/resume`).expect(200);
    expect(resumed.body.data.status).toBe('IN_PROGRESS');

    const [exercise] = (await get('/exercises').expect(200)).body.data;
    const completion = {
      clientId: randomUUID(),
      sessionId: session.body.data.id,
      startedAt: new Date(Date.now() - 120_000).toISOString(),
      completedAt: new Date().toISOString(),
      perceivedDifficulty: 2,
    };
    const first = await post(`/exercises/${exercise.id}/completions`, completion).expect(201);
    const retry = await post(`/exercises/${exercise.id}/completions`, completion).expect(200);
    expect(retry.body.data).toMatchObject({ id: first.body.data.id, duplicate: true });
    expect(await prisma.exerciseCompletion.count()).toBe(1);

    const done = await post(`/sessions/${session.body.data.id}/complete`, {
      perceivedEffort: 3,
    }).expect(200);
    expect(done.body.data.status).toBe('COMPLETED');
    await post(`/sessions/${session.body.data.id}/complete`).expect(200);
    await post(`/sessions/${session.body.data.id}/pause`).expect(409);

    const current = await get('/treatments/current').expect(200);
    expect(
      current.body.data.today.find((t: { exerciseId: string }) => t.exerciseId === exercise.id)
        .completed,
    ).toBe(true);
  });

  it('rejects impossible completion times', async () => {
    await startTreatment(user);
    const [exercise] = (await get('/exercises').expect(200)).body.data;
    const res = await post(`/exercises/${exercise.id}/completions`, {
      clientId: randomUUID(),
      startedAt: new Date().toISOString(),
      completedAt: new Date(Date.now() - 60_000).toISOString(),
    }).expect(400);
    expect(res.body.error.code).toBe('INVALID_TIME_RANGE');
  });

  it('cannot touch another patient’s session', async () => {
    const treatment = await startTreatment(user);
    const session = await post(`/treatments/${treatment.id}/sessions`, {
      clientId: randomUUID(),
    }).expect(201);
    const other = await signUp();
    await startTreatment(other);
    await post(`/sessions/${session.body.data.id}/complete`, {}, other).expect(404);
  });
});
