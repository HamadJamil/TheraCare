import { randomUUID } from 'node:crypto';
import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { startTreatment } from '../helpers/fixtures';
import { signUp, type TestUser } from '../helpers/users';

let user: TestUser;

beforeEach(async () => {
  await resetDb();
  user = await signUp();
});
afterAll(() => prisma.$disconnect());

const sync = (events: object[]) =>
  api().post('/api/v1/sync/events').set('authorization', user.bearer).send({ events });

const observationEvent = (value: number) => ({
  clientEventId: randomUUID(),
  type: 'OBSERVATION_CREATED',
  payload: {
    kind: 'PAIN_INTENSITY',
    value,
    effectiveAt: new Date(Date.now() - 3_600_000).toISOString(),
  },
});

describe('offline synchronisation', () => {
  beforeEach(() => startTreatment(user));

  it('accepts a batch and reports per-event outcomes', async () => {
    const [exercise] = (
      await api().get('/api/v1/exercises').set('authorization', user.bearer).expect(200)
    ).body.data;
    const events = [
      observationEvent(4),
      observationEvent(42),
      {
        clientEventId: randomUUID(),
        type: 'EXERCISE_COMPLETED',
        payload: {
          exerciseVersionId: exercise.id,
          startedAt: new Date(Date.now() - 600_000).toISOString(),
          completedAt: new Date(Date.now() - 480_000).toISOString(),
        },
      },
    ];
    const res = await sync(events).expect(200);
    expect(res.body.data.results.map((r: { status: string }) => r.status)).toEqual([
      'ACCEPTED',
      'REJECTED',
      'ACCEPTED',
    ]);
    expect(res.body.data.results[1].errorCode).toBe('VALIDATION_ERROR');
    expect(await prisma.observation.findFirstOrThrow()).toMatchObject({ source: 'sync', value: 4 });
  });

  it('creates one server record when an event is delivered twice', async () => {
    const event = observationEvent(5);
    const first = await sync([event]).expect(200);
    const again = await sync([event]).expect(200);
    expect(again.body.data.results[0]).toMatchObject({
      status: 'ACCEPTED',
      duplicate: true,
      resultId: first.body.data.results[0].resultId,
    });
    expect(await prisma.observation.count()).toBe(1);
  });

  it('keeps permanent rejections stable on redelivery', async () => {
    const event = observationEvent(99);
    await sync([event]).expect(200);
    const again = await sync([event]).expect(200);
    expect(again.body.data.results[0]).toMatchObject({ status: 'REJECTED', duplicate: true });
  });

  it('asks the device to retry when access is temporarily missing', async () => {
    const consent = await prisma.consent.findFirstOrThrow({
      where: { consentType: { required: true } },
    });
    await api()
      .post(`/api/v1/consents/${consent.id}/withdraw`)
      .set('authorization', user.bearer)
      .expect(200);
    const res = await sync([observationEvent(3)]).expect(200);
    expect(res.body.data.results[0]).toMatchObject({
      status: 'RETRY',
      errorCode: 'CONSENT_REQUIRED',
    });
    expect(await prisma.syncEvent.count()).toBe(0);
  });

  it('reports sync status', async () => {
    await sync([observationEvent(2), observationEvent(77)]).expect(200);
    const res = await api()
      .get('/api/v1/sync/status')
      .set('authorization', user.bearer)
      .expect(200);
    expect(res.body.data).toMatchObject({ accepted: 1, rejected: 1 });
  });

  it('validates the batch envelope', async () => {
    await sync([]).expect(400);
    await sync([{ clientEventId: 'nope', type: 'UNKNOWN', payload: {} }]).expect(400);
  });
});
