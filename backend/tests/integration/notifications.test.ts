import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { startTreatment } from '../helpers/fixtures';
import { signUp, type TestUser } from '../helpers/users';
import {
  dispatchDue,
  scheduleReminders,
} from '../../src/modules/notifications/notifications.service';
import type { NotificationProvider } from '../../src/modules/notifications/provider';

let user: TestUser;

beforeEach(async () => {
  await resetDb();
  user = await signUp();
  await startTreatment(user);
});
afterAll(() => prisma.$disconnect());

const setPrefs = (body: object) =>
  api()
    .patch('/api/v1/patients/me/preferences')
    .set('authorization', user.bearer)
    .send(body)
    .expect(200);

const fakeProvider = (fail = false) => {
  const sent: string[] = [];
  const provider: NotificationProvider = {
    async send(message) {
      if (fail) throw new Error('provider unavailable');
      sent.push(message.body);
      return { providerRef: 'ref-1' };
    },
  };
  return { provider, sent };
};

describe('reminders', () => {
  it('does not schedule optional reminders unless enabled', async () => {
    expect(await scheduleReminders()).toBe(0);
  });

  it('schedules once per local day even when run repeatedly', async () => {
    await setPrefs({ remindersEnabled: true });
    expect(await scheduleReminders()).toBe(1);
    expect(await scheduleReminders()).toBe(0);
    expect(await prisma.notification.count()).toBe(1);
  });

  it('disabling reminders cancels scheduled ones', async () => {
    await setPrefs({ remindersEnabled: true });
    await scheduleReminders();
    await setPrefs({ remindersEnabled: false });
    expect(await prisma.notification.count({ where: { status: 'SCHEDULED' } })).toBe(0);
  });

  it('dispatches due reminders once with neutral text', async () => {
    await setPrefs({ remindersEnabled: true });
    await scheduleReminders();
    await prisma.notification.updateMany({ data: { scheduledFor: new Date(Date.now() - 1000) } });
    const { provider, sent } = fakeProvider();
    expect(await dispatchDue(provider)).toBe(1);
    expect(await dispatchDue(provider)).toBe(0);
    expect(sent).toEqual(['Sie haben heute eine neue Aufgabe.']);

    const list = await api()
      .get('/api/v1/notifications/me')
      .set('authorization', user.bearer)
      .expect(200);
    expect(list.body.data[0]).toMatchObject({ status: 'SENT', kind: 'DAILY_REMINDER' });
  });

  it('records provider failures without throwing', async () => {
    await setPrefs({ remindersEnabled: true });
    await scheduleReminders();
    await prisma.notification.updateMany({ data: { scheduledFor: new Date(Date.now() - 1000) } });
    await expect(dispatchDue(fakeProvider(true).provider)).resolves.toBe(0);
    expect(await prisma.notification.findFirstOrThrow()).toMatchObject({ status: 'FAILED' });
  });
});
