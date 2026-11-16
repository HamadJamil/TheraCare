import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { createCode, seedBase } from '../helpers/fixtures';
import { signUp, type TestUser } from '../helpers/users';
import { addDays } from '../../src/common/dates';

let user: TestUser;

beforeEach(async () => {
  await resetDb();
  await seedBase();
  user = await signUp();
});
afterAll(() => prisma.$disconnect());

const redeem = (code: string, as = user, key?: string) => {
  const req = api().post('/api/v1/activations/redeem').set('authorization', as.bearer);
  if (key) req.set('idempotency-key', key);
  return req.send({ code });
};

describe('activation', () => {
  it('redeems a valid code once and creates one entitlement', async () => {
    const code = await createCode();
    const res = await redeem(code.toLowerCase().replace(/-/g, ' ')).expect(201);
    expect(res.body.data).toMatchObject({ status: 'ACTIVE' });

    const status = await api()
      .get('/api/v1/activations/status')
      .set('authorization', user.bearer)
      .expect(200);
    expect(status.body.data.activated).toBe(true);
    expect(await prisma.entitlement.count()).toBe(1);
    const db = await prisma.user.findUniqueOrThrow({ where: { email: user.email } });
    expect(db.journeyState).toBe('ENTITLEMENT_ACTIVE');
  });

  it.each([
    ['unknown', async () => 'ABCD-EFGH-JKLM', 'ACTIVATION_INVALID'],
    ['expired', () => createCode({ expiresAt: addDays(new Date(), -1) }), 'ACTIVATION_EXPIRED'],
    ['revoked', () => createCode({ status: 'REVOKED' }), 'ACTIVATION_REVOKED'],
    [
      'wrong product',
      async () => createCode({ productId: (await seedBase()).other.id }),
      'ACTIVATION_WRONG_PRODUCT',
    ],
  ])('rejects %s codes', async (_label, makeCode, errorCode) => {
    const res = await redeem(await makeCode()).expect(400);
    expect(res.body.error.code).toBe(errorCode);
    expect(await prisma.entitlement.count()).toBe(0);
  });

  it('rejects a code already redeemed by someone else', async () => {
    const code = await createCode();
    await redeem(code).expect(201);
    const other = await signUp();
    const res = await redeem(code, other).expect(400);
    expect(res.body.error.code).toBe('ACTIVATION_ALREADY_USED');
  });

  it('returns the original result when the same patient retries', async () => {
    const code = await createCode();
    const first = await redeem(code).expect(201);
    const retry = await redeem(code).expect(201);
    expect(retry.body.data.id).toBe(first.body.data.id);
    expect(await prisma.entitlement.count()).toBe(1);
  });

  it('replays responses for a repeated idempotency key', async () => {
    const code = await createCode();
    const first = await redeem(code, user, 'retry-key-0001').expect(201);
    const replay = await redeem(code, user, 'retry-key-0001').expect(201);
    expect(replay.headers['idempotent-replay']).toBe('true');
    expect(replay.body).toEqual(first.body);
  });

  it('allows at most one redemption under concurrency', async () => {
    const code = await createCode();
    const others = await Promise.all([signUp(), signUp(), signUp(), signUp()]);
    const results = await Promise.all(others.map((u) => redeem(code, u)));
    expect(results.filter((r) => r.status === 201)).toHaveLength(1);
    expect(await prisma.entitlement.count()).toBe(1);
  });

  it('never stores or audits the raw code', async () => {
    const code = await createCode();
    await redeem(code).expect(201);
    const dump = JSON.stringify([
      await prisma.activation.findMany(),
      await prisma.auditEvent.findMany(),
    ]);
    expect(dump).not.toContain(code);
    expect(dump).not.toContain(code.replace(/-/g, ''));
  });

  it('requires a verified account', async () => {
    await api().post('/api/v1/activations/redeem').send({ code: 'ABCD-EFGH-JKLM' }).expect(401);
  });
});
