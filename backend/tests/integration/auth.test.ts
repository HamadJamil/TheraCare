import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { PASSWORD, lastCodeFor, register, signUp } from '../helpers/users';
import { testOutbox } from '../../src/infrastructure/mailer';

beforeEach(resetDb);
afterAll(() => prisma.$disconnect());

describe('registration and verification', () => {
  it('creates an unverified account and mails a code', async () => {
    const res = await register('anna@example.test').expect(202);
    expect(res.body.data.message).toMatch(/If this email address can be used/);
    const user = await prisma.user.findUniqueOrThrow({
      where: { email: 'anna@example.test' },
      include: { profile: true },
    });
    expect(user.status).toBe('PENDING_VERIFICATION');
    expect(user.journeyState).toBe('ACCOUNT_PENDING_VERIFICATION');
    expect(user.passwordHash).toMatch(/^\$argon2id\$/);
    expect(user.profile?.firstName).toBe('Erika');
    expect(lastCodeFor('anna@example.test')).toMatch(/^\d{6}$/);
  });

  it('answers duplicate registration identically without creating a second account', async () => {
    await register('dup@example.test').expect(202);
    const second = await register('dup@example.test').expect(202);
    expect(second.body.data.message).toMatch(/If this email address can be used/);
    expect(await prisma.user.count({ where: { email: 'dup@example.test' } })).toBe(1);
  });

  it('validates fields server-side', async () => {
    const res = await api()
      .post('/api/v1/auth/register')
      .send({ email: 'not-an-email', password: 'short', firstName: '', lastName: 'X' })
      .expect(400);
    expect(Object.keys(res.body.error.fields)).toEqual(
      expect.arrayContaining(['email', 'password', 'firstName']),
    );
  });

  it('verifies with the mailed code and advances the journey', async () => {
    const user = await signUp('ben@example.test');
    expect(user.accessToken).toBeTruthy();
    const db = await prisma.user.findUniqueOrThrow({ where: { email: 'ben@example.test' } });
    expect(db.status).toBe('ACTIVE');
    expect(db.journeyState).toBe('ENTITLEMENT_PENDING');
  });

  it('rejects wrong codes and locks after repeated attempts', async () => {
    await register('carl@example.test').expect(202);
    const code = lastCodeFor('carl@example.test');
    const wrong = code === '000000' ? '111111' : '000000';
    for (let i = 0; i < 5; i++) {
      const res = await api()
        .post('/api/v1/auth/verify-email')
        .send({ email: 'carl@example.test', code: wrong })
        .expect(400);
      expect(res.body.error.code).toBe('INVALID_CODE');
    }
    await api()
      .post('/api/v1/auth/verify-email')
      .send({ email: 'carl@example.test', code })
      .expect(400);
  });

  it('resend invalidates the previous code', async () => {
    await register('dora@example.test').expect(202);
    const first = lastCodeFor('dora@example.test');
    await api()
      .post('/api/v1/auth/resend-verification')
      .send({ email: 'dora@example.test' })
      .expect(202);
    const second = lastCodeFor('dora@example.test');
    if (first !== second) {
      await api()
        .post('/api/v1/auth/verify-email')
        .send({ email: 'dora@example.test', code: first })
        .expect(400);
    }
    await api()
      .post('/api/v1/auth/verify-email')
      .send({ email: 'dora@example.test', code: second })
      .expect(201);
  });
});

describe('login', () => {
  it('signs in a verified user', async () => {
    await signUp('eva@example.test');
    const res = await api()
      .post('/api/v1/auth/login')
      .send({ email: 'eva@example.test', password: PASSWORD })
      .expect(200);
    expect(res.body.data).toMatchObject({
      accessToken: expect.any(String),
      refreshToken: expect.any(String),
    });
  });

  it('uses the same generic error for unknown email and wrong password', async () => {
    await signUp('finn@example.test');
    const wrongPw = await api()
      .post('/api/v1/auth/login')
      .send({ email: 'finn@example.test', password: 'nope-nope-nope' })
      .expect(401);
    const unknown = await api()
      .post('/api/v1/auth/login')
      .send({ email: 'ghost@example.test', password: 'nope-nope-nope' })
      .expect(401);
    expect(wrongPw.body.error).toEqual(unknown.body.error);
    expect(await prisma.auditEvent.count({ where: { action: 'auth.login_failed' } })).toBe(2);
  });

  it('asks unverified users to confirm their email', async () => {
    await register('gina@example.test').expect(202);
    const res = await api()
      .post('/api/v1/auth/login')
      .send({ email: 'gina@example.test', password: PASSWORD })
      .expect(412);
    expect(res.body.error.code).toBe('EMAIL_NOT_VERIFIED');
  });
});

describe('sessions', () => {
  it('rotates refresh credentials and rejects the old one', async () => {
    const user = await signUp();
    const rotated = await api()
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken })
      .expect(200);
    expect(rotated.body.data.refreshToken).not.toBe(user.refreshToken);
    await api().post('/api/v1/auth/refresh').send({ refreshToken: user.refreshToken }).expect(401);
  });

  it('revokes the whole family when a rotated credential is reused', async () => {
    const user = await signUp();
    const rotated = await api()
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: user.refreshToken })
      .expect(200);
    await api().post('/api/v1/auth/refresh').send({ refreshToken: user.refreshToken }).expect(401);
    await api()
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: rotated.body.data.refreshToken })
      .expect(401);
    expect(
      await prisma.auditEvent.count({ where: { action: 'auth.refresh_reuse_detected' } }),
    ).toBe(1);
  });

  it('logout revokes the current session', async () => {
    const user = await signUp();
    await api().post('/api/v1/auth/logout').set('authorization', user.bearer).expect(200);
    await api().post('/api/v1/auth/refresh').send({ refreshToken: user.refreshToken }).expect(401);
  });

  it('lists and revokes own sessions only', async () => {
    const user = await signUp('hans@example.test');
    const other = await signUp();
    await api()
      .post('/api/v1/auth/login')
      .send({ email: 'hans@example.test', password: PASSWORD, deviceLabel: 'Tablet' })
      .expect(200);

    const list = await api()
      .get('/api/v1/auth/sessions')
      .set('authorization', user.bearer)
      .expect(200);
    expect(list.body.data).toHaveLength(2);
    expect(list.body.data.filter((s: { current: boolean }) => s.current)).toHaveLength(1);

    const tablet = list.body.data.find((s: { deviceLabel: string }) => s.deviceLabel === 'Tablet');
    await api()
      .delete(`/api/v1/auth/sessions/${tablet.id}`)
      .set('authorization', other.bearer)
      .expect(404);
    await api()
      .delete(`/api/v1/auth/sessions/${tablet.id}`)
      .set('authorization', user.bearer)
      .expect(200);
  });
});

describe('password recovery', () => {
  it('resets once with the mailed code and revokes sessions', async () => {
    const user = await signUp('ida@example.test');
    await api()
      .post('/api/v1/auth/forgot-password')
      .send({ email: 'ida@example.test' })
      .expect(202);
    const code = lastCodeFor('ida@example.test', /reset code is ([A-Z0-9-]+)/);

    await api()
      .post('/api/v1/auth/reset-password')
      .send({ token: code.toLowerCase(), password: 'a-brand-new-pass-1' })
      .expect(200);
    await api()
      .post('/api/v1/auth/reset-password')
      .send({ token: code, password: 'another-pass-123' })
      .expect(400);
    await api().post('/api/v1/auth/refresh').send({ refreshToken: user.refreshToken }).expect(401);
    await api()
      .post('/api/v1/auth/login')
      .send({ email: 'ida@example.test', password: 'a-brand-new-pass-1' })
      .expect(200);
  });

  it('does not reveal unknown emails', async () => {
    const before = testOutbox.length;
    await api()
      .post('/api/v1/auth/forgot-password')
      .send({ email: 'nobody@example.test' })
      .expect(202);
    expect(testOutbox.length).toBe(before);
  });

  it('rejects expired codes', async () => {
    await signUp('jan@example.test');
    await api()
      .post('/api/v1/auth/forgot-password')
      .send({ email: 'jan@example.test' })
      .expect(202);
    const code = lastCodeFor('jan@example.test', /reset code is ([A-Z0-9-]+)/);
    await prisma.passwordReset.updateMany({ data: { expiresAt: new Date(Date.now() - 1000) } });
    await api()
      .post('/api/v1/auth/reset-password')
      .send({ token: code, password: 'a-brand-new-pass-1' })
      .expect(400);
  });
});
