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

const get = (path: string) => api().get(`/api/v1${path}`).set('authorization', user.bearer);
const post = (path: string, body: object) =>
  api().post(`/api/v1${path}`).set('authorization', user.bearer).send(body);

describe('progress', () => {
  it('shows an empty-state friendly overview with the next action', async () => {
    const res = await get('/progress/overview?lang=en').expect(200);
    expect(res.body.data.today).toEqual({ planned: 3, completed: 0 });
    expect(res.body.data.nextAction).toMatchObject({ type: 'EXERCISE', title: 'Pelvic tilt' });
    expect(res.body.data.recentEntries).toEqual([]);
    expect(res.body.data.thisWeek.text).toBe('0 exercises on 0 days, no pain entries.');
  });

  it('totals match the source events', async () => {
    const exercises = (await get('/exercises').expect(200)).body.data;
    for (const exercise of exercises.slice(0, 2)) {
      await post(`/exercises/${exercise.id}/completions`, {
        clientId: randomUUID(),
        startedAt: new Date(Date.now() - 120_000).toISOString(),
        completedAt: new Date().toISOString(),
      }).expect(201);
    }
    for (const value of [6, 3]) {
      await post('/observations', {
        clientId: randomUUID(),
        kind: 'PAIN_INTENSITY',
        value,
        effectiveAt: new Date().toISOString(),
      }).expect(201);
    }

    const overview = await get('/progress/overview?lang=en').expect(200);
    expect(overview.body.data.today).toEqual({ planned: 3, completed: 2 });
    expect(overview.body.data.nextAction.title).toBe('Seated cat-cow');
    expect(overview.body.data.recentEntries).toHaveLength(2);
    expect(overview.body.data.thisWeek).toMatchObject({
      exercisesCompleted: 2,
      activeDays: 1,
      painEntries: 2,
      painAverage: 4.5,
    });

    const weekly = await get('/progress/weekly?weeks=3&lang=en').expect(200);
    expect(weekly.body.data).toHaveLength(3);
    expect(weekly.body.data[2]).toMatchObject({ exercisesCompleted: 2, painAverage: 4.5 });
    expect(weekly.body.data[2].text).toBe('2 exercises on 1 days, average pain 4.5 out of 10.');
    expect(weekly.body.data[0]).toMatchObject({ exercisesCompleted: 0, painAverage: null });
  });

  it('points to the weekly check-in once exercises are done', async () => {
    const exercises = (await get('/exercises').expect(200)).body.data;
    for (const exercise of exercises) {
      await post(`/exercises/${exercise.id}/completions`, {
        clientId: randomUUID(),
        startedAt: new Date(Date.now() - 60_000).toISOString(),
        completedAt: new Date().toISOString(),
      }).expect(201);
    }
    const res = await get('/progress/overview?lang=en').expect(200);
    expect(res.body.data.nextAction).toMatchObject({
      type: 'QUESTIONNAIRE',
      title: 'Weekly check-in',
    });
  });

  it('validates the weekly range', async () => {
    await get('/progress/weekly?weeks=60').expect(400);
  });
});
