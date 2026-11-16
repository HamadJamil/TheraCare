import { randomUUID } from 'node:crypto';
import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { startTreatment } from '../helpers/fixtures';
import { PASSWORD, signUp } from '../helpers/users';
import { addDays } from '../../src/common/dates';
import { runRetention } from '../../src/jobs/retention';

beforeEach(resetDb);
afterAll(() => prisma.$disconnect());

describe('retention job', () => {
  it('anonymises closed accounts after the retention period but keeps clinical records', async () => {
    const user = await signUp('leaving@example.test');
    await startTreatment(user);
    await api()
      .post('/api/v1/observations')
      .set('authorization', user.bearer)
      .send({
        clientId: randomUUID(),
        kind: 'PAIN_INTENSITY',
        value: 3,
        effectiveAt: new Date().toISOString(),
      })
      .expect(201);
    await api()
      .post('/api/v1/patients/me/close')
      .set('authorization', user.bearer)
      .send({ password: PASSWORD, confirm: true })
      .expect(200);

    expect((await runRetention()).anonymised).toBe(0);
    const result = await runRetention(addDays(new Date(), 31));
    expect(result.anonymised).toBe(1);

    const db = await prisma.user.findFirstOrThrow({ include: { profile: true } });
    expect(db.email).toBe(`${db.id}@anonymised.invalid`);
    expect(db.profile).toMatchObject({ firstName: 'Anonymised', dateOfBirth: null });
    expect(await prisma.observation.count({ where: { userId: db.id } })).toBe(1);
    expect(
      await prisma.auditEvent.count({ where: { action: 'retention.account_anonymised' } }),
    ).toBe(1);

    expect((await runRetention(addDays(new Date(), 32))).anonymised).toBe(0);
  });

  it('removes expired technical records', async () => {
    await signUp();
    const later = addDays(new Date(), 90);
    const result = await runRetention(later);
    expect(result.verifications).toBe(1);
    expect(result.sessions).toBe(1);
  });
});
