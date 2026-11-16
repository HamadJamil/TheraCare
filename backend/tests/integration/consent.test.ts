import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { createCode, seedBase } from '../helpers/fixtures';
import { signUp, type TestUser } from '../helpers/users';

let user: TestUser;

beforeEach(async () => {
  await resetDb();
  await seedBase();
  user = await signUp();
});
afterAll(() => prisma.$disconnect());

const types = () =>
  api().get('/api/v1/consents/types?lang=en').set('authorization', user.bearer).expect(200);
const decide = (consentTypeId: string, decision: 'GRANTED' | 'DECLINED') =>
  api()
    .post('/api/v1/consents')
    .set('authorization', user.bearer)
    .send({ consentTypeId, decision });

describe('consent', () => {
  it('lists localized consent types with required flags', async () => {
    const res = await types();
    expect(res.body.data).toHaveLength(3);
    expect(res.body.data[0]).toMatchObject({ required: true, policyVersion: '2026-11' });
    expect(res.body.data.map((t: { title: string }) => t.title)).toContain('Privacy notice');
  });

  it('records decisions with policy version and history', async () => {
    const [first] = (await types()).body.data;
    const res = await decide(first.id, 'GRANTED').expect(201);
    expect(res.body.data).toMatchObject({ decision: 'GRANTED', policyVersion: '2026-11' });

    const mine = await api()
      .get('/api/v1/consents/me')
      .set('authorization', user.bearer)
      .expect(200);
    expect(mine.body.data.current).toHaveLength(1);
    expect(mine.body.data.history[0]).toMatchObject({
      decision: 'GRANTED',
      policyVersion: '2026-11',
    });
  });

  it('lets optional consent be declined independently', async () => {
    const all = (await types()).body.data as { id: string; required: boolean }[];
    for (const t of all) await decide(t.id, t.required ? 'GRANTED' : 'DECLINED').expect(201);
    await api()
      .post('/api/v1/activations/redeem')
      .set('authorization', user.bearer)
      .send({ code: await createCode() })
      .expect(201);
    const db = await prisma.user.findUniqueOrThrow({ where: { email: user.email } });
    expect(db.journeyState).toBe('PRIVACY_COMPLETE');
  });

  it('withdrawal changes state, explains consequences and is audited', async () => {
    const required = ((await types()).body.data as { id: string; required: boolean }[]).find(
      (t) => t.required,
    )!;
    const granted = await decide(required.id, 'GRANTED').expect(201);
    const res = await api()
      .post(`/api/v1/consents/${granted.body.data.id}/withdraw`)
      .set('authorization', user.bearer)
      .expect(200);
    expect(res.body.data.decision).toBe('WITHDRAWN');
    expect(res.body.data.consequence).toMatch(/paused/);
    expect(await prisma.consentEvent.count()).toBe(2);
    expect(await prisma.auditEvent.count({ where: { action: 'consent.withdrawn' } })).toBe(1);

    await api()
      .post(`/api/v1/consents/${granted.body.data.id}/withdraw`)
      .set('authorization', user.bearer)
      .expect(409);
  });

  it('cannot withdraw another patient’s consent', async () => {
    const [first] = (await types()).body.data;
    const granted = await decide(first.id, 'GRANTED').expect(201);
    const other = await signUp();
    await api()
      .post(`/api/v1/consents/${granted.body.data.id}/withdraw`)
      .set('authorization', other.bearer)
      .expect(404);
  });
});
