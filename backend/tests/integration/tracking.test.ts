import { randomUUID } from 'node:crypto';
import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { startTreatment } from '../helpers/fixtures';
import { signUp, type TestUser } from '../helpers/users';

let user: TestUser;

beforeEach(async () => {
  await resetDb();
  user = await signUp();
  await startTreatment(user);
});
afterAll(() => prisma.$disconnect());

const post = (path: string, body: object, as = user) =>
  api().post(`/api/v1${path}`).set('authorization', as.bearer).send(body);
const get = (path: string, as = user) =>
  api().get(`/api/v1${path}`).set('authorization', as.bearer);

const pain = (value: number, extra: object = {}) => ({
  clientId: randomUUID(),
  kind: 'PAIN_INTENSITY',
  value,
  effectiveAt: new Date().toISOString(),
  ...extra,
});

describe('observations', () => {
  it('lists configured instruments', async () => {
    const res = await get('/observations/instruments?lang=en').expect(200);
    expect(res.body.data.find((i: { kind: string }) => i.kind === 'PAIN_INTENSITY')).toMatchObject({
      min: 0,
      max: 10,
      minLabel: 'No pain',
    });
  });

  it.each([0, 10])('accepts boundary value %i', async (value) => {
    await post('/observations', pain(value)).expect(201);
  });

  it.each([-1, 11, 4.5])('rejects out-of-range value %p', async (value) => {
    await post('/observations', pain(value)).expect(400);
  });

  it('rejects future entries', async () => {
    await post(
      '/observations',
      pain(3, { effectiveAt: new Date(Date.now() + 3_600_000).toISOString() }),
    ).expect(400);
  });

  it('saves once despite retries and shows in history', async () => {
    const entry = pain(6, { note: 'after gardening' });
    await post('/observations', entry).expect(201);
    const retry = await post('/observations', entry).expect(200);
    expect(retry.body.data.duplicate).toBe(true);
    const list = await get('/observations?kind=PAIN_INTENSITY').expect(200);
    expect(list.body.data.items).toHaveLength(1);
    expect(list.body.data.items[0]).toMatchObject({
      value: 6,
      note: 'after gardening',
      status: 'CURRENT',
    });
  });

  it('paginates with a stable order', async () => {
    for (let i = 0; i < 5; i++) {
      await post(
        '/observations',
        pain(i, { effectiveAt: new Date(Date.now() - i * 60_000).toISOString() }),
      ).expect(201);
    }
    const first = await get('/observations?limit=2').expect(200);
    expect(first.body.data.items.map((o: { value: number }) => o.value)).toEqual([0, 1]);
    const second = await get(`/observations?limit=2&cursor=${first.body.data.nextCursor}`).expect(
      200,
    );
    expect(second.body.data.items.map((o: { value: number }) => o.value)).toEqual([2, 3]);
  });

  it('corrects append-only and preserves the prior value', async () => {
    const created = await post('/observations', pain(8)).expect(201);
    const correction = { clientId: randomUUID(), value: 5, reason: 'Typed the wrong number' };
    const fixed = await post(
      `/observations/${created.body.data.id}/corrections`,
      correction,
    ).expect(201);
    expect(fixed.body.data).toMatchObject({ value: 5, supersedesId: created.body.data.id });
    await post(`/observations/${created.body.data.id}/corrections`, {
      ...correction,
      clientId: randomUUID(),
    }).expect(409);

    const current = await get('/observations').expect(200);
    expect(current.body.data.items.map((o: { value: number }) => o.value)).toEqual([5]);
    const all = await get('/observations?includeCorrected=true').expect(200);
    expect(all.body.data.items).toHaveLength(2);

    const history = await get(`/observations/${fixed.body.data.id}/history`).expect(200);
    expect(
      history.body.data.map((o: { value: number; status: string }) => [o.value, o.status]),
    ).toEqual([
      [8, 'CORRECTED'],
      [5, 'CURRENT'],
    ]);
    expect(history.body.data[1].correctionReason).toBe('Typed the wrong number');
  });

  it('isolates patients', async () => {
    const created = await post('/observations', pain(4)).expect(201);
    const other = await signUp();
    await startTreatment(other);
    expect((await get('/observations', other).expect(200)).body.data.items).toHaveLength(0);
    await get(`/observations/${created.body.data.id}/history`, other).expect(404);
    await post(
      `/observations/${created.body.data.id}/corrections`,
      { clientId: randomUUID(), value: 1, reason: 'x' },
      other,
    ).expect(404);
  });
});
