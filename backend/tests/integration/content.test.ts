import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { seedBase, startTreatment } from '../helpers/fixtures';
import { signUp, staff } from '../helpers/users';

beforeEach(async () => {
  await resetDb();
  await seedBase();
});
afterAll(() => prisma.$disconnect());

const as = (bearer: string) => ({
  get: (path: string) => api().get(`/api/v1/admin/content${path}`).set('authorization', bearer),
  post: (path: string, body: object = {}) =>
    api().post(`/api/v1/admin/content${path}`).set('authorization', bearer).send(body),
  patch: (path: string, body: object) =>
    api().patch(`/api/v1/admin/content${path}`).set('authorization', bearer).send(body),
});

describe('content administration', () => {
  it('runs the full review and release workflow', async () => {
    const author = as((await staff('CONTENT_AUTHOR')).bearer);
    const reviewer = as((await staff('CLINICAL_REVIEWER')).bearer);
    const admin = as((await staff('ADMIN')).bearer);

    const list = await author.get('/exercises').expect(200);
    const bridge = list.body.data.find((e: { key: string }) => e.key === 'bridge');
    const draft = await author.post(`/exercises/${bridge.id}/versions`).expect(201);
    expect(draft.body.data).toMatchObject({ version: 2, status: 'DRAFT' });
    await author.post(`/exercises/${bridge.id}/versions`).expect(409);

    await author
      .patch(`/exercise-versions/${draft.body.data.id}`, { durationSeconds: 180 })
      .expect(200);
    await author.post(`/exercise/${draft.body.data.id}/submit`).expect(200);
    await author
      .patch(`/exercise-versions/${draft.body.data.id}`, { durationSeconds: 200 })
      .expect(409);

    await admin.post(`/exercise/${draft.body.data.id}/publish`).expect(409);
    await reviewer.post(`/exercise/${draft.body.data.id}/reject`).expect(400);
    await reviewer
      .post(`/exercise/${draft.body.data.id}/reject`, { reason: 'Clarify step 2' })
      .expect(200);
    await author.post(`/exercise/${draft.body.data.id}/submit`).expect(200);
    await reviewer.post(`/exercise/${draft.body.data.id}/approve`).expect(200);
    const published = await admin.post(`/exercise/${draft.body.data.id}/publish`).expect(200);
    expect(published.body.data.status).toBe('PUBLISHED');

    await author
      .patch(`/exercise-versions/${draft.body.data.id}`, { durationSeconds: 99 })
      .expect(409);
    const history = await admin.get(`/reviews/${draft.body.data.id}`).expect(200);
    expect(history.body.data.map((r: { action: string }) => r.action)).toEqual([
      'SUBMITTED',
      'REJECTED',
      'SUBMITTED',
      'APPROVED',
      'PUBLISHED',
    ]);
    expect(await prisma.auditEvent.count({ where: { action: { startsWith: 'content.' } } })).toBe(
      7,
    );
  });

  it('prevents authors from approving their own content', async () => {
    const authorAccount = await staff('CONTENT_AUTHOR');
    const author = as(authorAccount.bearer);
    const exercise = (await author.get('/exercises').expect(200)).body.data[0];
    const draft = await author.post(`/exercises/${exercise.id}/versions`).expect(201);
    await author.post(`/exercise/${draft.body.data.id}/submit`).expect(200);
    await author.post(`/exercise/${draft.body.data.id}/approve`).expect(403);

    // Even a reviewer account that authored the draft cannot approve it.
    await prisma.user.update({
      where: { email: authorAccount.email },
      data: { role: 'CLINICAL_REVIEWER' },
    });
    const relogin = await api()
      .post('/api/v1/auth/login')
      .send({ email: authorAccount.email, password: 'correct-horse-42' })
      .expect(200);
    await as(`Bearer ${relogin.body.data.accessToken}`)
      .post(`/exercise/${draft.body.data.id}/approve`)
      .expect(403);
  });

  it('keeps patients on their assigned historical version', async () => {
    const patient = await signUp();
    await startTreatment(patient, 25);
    const before = (
      await api().get('/api/v1/exercises').set('authorization', patient.bearer).expect(200)
    ).body.data[0];

    const author = as((await staff('CONTENT_AUTHOR')).bearer);
    const reviewer = as((await staff('CLINICAL_REVIEWER')).bearer);
    const admin = as((await staff('ADMIN')).bearer);
    const exercise = (await author.get('/exercises').expect(200)).body.data.find(
      (e: { key: string }) => e.key === 'pelvic-tilt',
    );
    const draft = await author.post(`/exercises/${exercise.id}/versions`).expect(201);
    await author.post(`/exercise/${draft.body.data.id}/submit`).expect(200);
    await reviewer.post(`/exercise/${draft.body.data.id}/approve`).expect(200);
    await admin.post(`/exercise/${draft.body.data.id}/publish`).expect(200);

    const after = (
      await api().get('/api/v1/exercises').set('authorization', patient.bearer).expect(200)
    ).body.data[0];
    expect(after).toMatchObject({ id: before.id, version: 1 });
  });

  it('is closed to patients and support agents', async () => {
    const patient = await signUp();
    await as(patient.bearer).get('/exercises').expect(403);
    await as((await staff('SUPPORT_AGENT')).bearer)
      .get('/exercises')
      .expect(403);
  });
});
