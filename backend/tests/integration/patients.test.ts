import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { PASSWORD, lastCodeFor, signUp } from '../helpers/users';

beforeEach(resetDb);
afterAll(() => prisma.$disconnect());

describe('profile', () => {
  it('returns own profile with account status and journey separately', async () => {
    const user = await signUp('p1@example.test');
    const res = await api()
      .get('/api/v1/patients/me')
      .set('authorization', user.bearer)
      .expect(200);
    expect(res.body.data).toMatchObject({
      email: 'p1@example.test',
      accountStatus: 'ACTIVE',
      journey: { state: 'ENTITLEMENT_PENDING', nextStep: 'ENTER_ACTIVATION_CODE' },
      profile: { firstName: 'Erika', preferredLanguage: 'de' },
    });
  });

  it('updates permitted fields and audits field names only', async () => {
    const user = await signUp();
    const res = await api()
      .patch('/api/v1/patients/me')
      .set('authorization', user.bearer)
      .send({ firstName: 'Maria', timezone: 'Europe/Berlin', preferredLanguage: 'en' })
      .expect(200);
    expect(res.body.data.profile).toMatchObject({ firstName: 'Maria', preferredLanguage: 'en' });
    const event = await prisma.auditEvent.findFirstOrThrow({
      where: { action: 'patient.profile_updated' },
    });
    expect(JSON.stringify(event)).not.toContain('Maria');
  });

  it('rejects unknown and invalid fields', async () => {
    const user = await signUp();
    await api()
      .patch('/api/v1/patients/me')
      .set('authorization', user.bearer)
      .send({ role: 'ADMIN' })
      .expect(400);
    await api()
      .patch('/api/v1/patients/me')
      .set('authorization', user.bearer)
      .send({ timezone: 'Mars/Base' })
      .expect(400);
  });

  it('only ever exposes the caller’s own profile', async () => {
    const a = await signUp('a@example.test');
    const b = await signUp('b@example.test');
    const res = await api().get('/api/v1/patients/me').set('authorization', b.bearer).expect(200);
    expect(res.body.data.email).toBe('b@example.test');
    expect(res.body.data.email).not.toBe(a.email);
  });

  it('requires authentication', async () => {
    await api().get('/api/v1/patients/me').expect(401);
  });
});

describe('preferences', () => {
  it('reads defaults and persists updates', async () => {
    const user = await signUp();
    const defaults = await api()
      .get('/api/v1/patients/me/preferences')
      .set('authorization', user.bearer)
      .expect(200);
    expect(defaults.body.data).toMatchObject({
      textScale: 1,
      reducedMotion: false,
      remindersEnabled: false,
    });

    await api()
      .patch('/api/v1/patients/me/preferences')
      .set('authorization', user.bearer)
      .send({ textScale: 1.6, reducedMotion: true, reminderTime: '18:30' })
      .expect(200);
    const after = await api()
      .get('/api/v1/patients/me/preferences')
      .set('authorization', user.bearer)
      .expect(200);
    expect(after.body.data).toMatchObject({
      textScale: 1.6,
      reducedMotion: true,
      reminderTime: '18:30',
    });
  });

  it('validates ranges and formats', async () => {
    const user = await signUp();
    await api()
      .patch('/api/v1/patients/me/preferences')
      .set('authorization', user.bearer)
      .send({ textScale: 5 })
      .expect(400);
    await api()
      .patch('/api/v1/patients/me/preferences')
      .set('authorization', user.bearer)
      .send({ reminderTime: '25:00' })
      .expect(400);
  });
});

describe('email change', () => {
  it('requires the password and a code sent to the new address', async () => {
    const user = await signUp('old@example.test');
    await api()
      .post('/api/v1/patients/me/email')
      .set('authorization', user.bearer)
      .send({ newEmail: 'new@example.test', password: 'wrong-password' })
      .expect(401);
    await api()
      .post('/api/v1/patients/me/email')
      .set('authorization', user.bearer)
      .send({ newEmail: 'new@example.test', password: PASSWORD })
      .expect(202);
    await api()
      .post('/api/v1/patients/me/email/confirm')
      .set('authorization', user.bearer)
      .send({ code: lastCodeFor('new@example.test') })
      .expect(200);
    const me = await api().get('/api/v1/patients/me').set('authorization', user.bearer).expect(200);
    expect(me.body.data.email).toBe('new@example.test');
  });
});

describe('account closure', () => {
  it('closes the account, revokes sessions and keeps records', async () => {
    const user = await signUp('close@example.test');
    await api()
      .post('/api/v1/patients/me/close')
      .set('authorization', user.bearer)
      .send({ password: PASSWORD })
      .expect(400);
    const res = await api()
      .post('/api/v1/patients/me/close')
      .set('authorization', user.bearer)
      .send({ password: PASSWORD, confirm: true })
      .expect(200);
    expect(res.body.data.closed).toBe(true);

    const db = await prisma.user.findUniqueOrThrow({
      where: { email: 'close@example.test' },
      include: { profile: true },
    });
    expect(db).toMatchObject({ status: 'CLOSED', journeyState: 'ACCOUNT_CLOSED' });
    expect(db.profile).not.toBeNull();
    await api().post('/api/v1/auth/refresh').send({ refreshToken: user.refreshToken }).expect(401);
    await api()
      .post('/api/v1/auth/login')
      .send({ email: 'close@example.test', password: PASSWORD })
      .expect(401);
  });
});
