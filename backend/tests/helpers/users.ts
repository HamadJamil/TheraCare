import { testOutbox } from '../../src/infrastructure/mailer';
import { api } from './app';

export const PASSWORD = 'correct-horse-42';

/** Extracts the most recent code sent to an address from the captured outbox. */
export function lastCodeFor(email: string, pattern = /code is ([\w-]+)/): string {
  const mail = [...testOutbox].reverse().find((m) => m.to === email);
  const match = mail?.text.match(pattern);
  if (!match) throw new Error(`no code mailed to ${email}`);
  return match[1];
}

export function register(email: string, password = PASSWORD) {
  return api()
    .post('/api/v1/auth/register')
    .send({ email, password, firstName: 'Erika', lastName: 'Muster', language: 'de' });
}

/** Registers, verifies and returns a signed-in patient. */
export async function signUp(email = `patient-${Date.now()}-${Math.random()}@example.test`) {
  await register(email).expect(202);
  const res = await api()
    .post('/api/v1/auth/verify-email')
    .send({ email, code: lastCodeFor(email) })
    .expect(201);
  const { accessToken, refreshToken } = res.body.data;
  return {
    email,
    accessToken: accessToken as string,
    refreshToken: refreshToken as string,
    bearer: `Bearer ${accessToken}`,
  };
}

export type TestUser = Awaited<ReturnType<typeof signUp>>;
