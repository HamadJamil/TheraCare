import { prisma } from '../../config/database';
import { consoleProvider, REMINDER_TEXT, type NotificationProvider } from './provider';
import { nextReminder } from './reminder-policy';

/** Creates at most one reminder per patient and local day (dedupe key). */
export async function scheduleReminders(now = new Date()) {
  const patients = await prisma.user.findMany({
    where: {
      status: 'ACTIVE',
      journeyState: 'TREATMENT_ACTIVE',
      preferences: { remindersEnabled: true },
    },
    include: { preferences: true, profile: true },
  });
  let created = 0;
  for (const patient of patients) {
    const prefs = patient.preferences!;
    const { at, localDate } = nextReminder(now, {
      reminderTime: prefs.reminderTime,
      quietHoursStart: prefs.quietHoursStart,
      quietHoursEnd: prefs.quietHoursEnd,
      timezone: patient.profile?.timezone ?? 'Europe/Berlin',
    });
    const result = await prisma.notification.createMany({
      data: [
        {
          userId: patient.id,
          kind: 'DAILY_REMINDER',
          dedupeKey: `reminder:${patient.id}:${localDate}`,
          scheduledFor: at,
        },
      ],
      skipDuplicates: true,
    });
    created += result.count;
  }
  return created;
}

/** Sends due reminders. A failed delivery is recorded and never blocks treatment. */
export async function dispatchDue(
  provider: NotificationProvider = consoleProvider,
  now = new Date(),
) {
  const due = await prisma.notification.findMany({
    where: { status: 'SCHEDULED', scheduledFor: { lte: now } },
    include: { user: { include: { profile: true, preferences: true } } },
    take: 500,
  });
  let sent = 0;
  for (const n of due) {
    if (n.user.status !== 'ACTIVE' || !n.user.preferences?.remindersEnabled) {
      await prisma.notification.update({ where: { id: n.id }, data: { status: 'CANCELLED' } });
      continue;
    }
    const text = REMINDER_TEXT[n.user.profile?.preferredLanguage === 'en' ? 'en' : 'de'];
    try {
      const { providerRef } = await provider.send({ userId: n.userId, ...text });
      // Conditional update prevents double sending if two workers overlap.
      const { count } = await prisma.notification.updateMany({
        where: { id: n.id, status: 'SCHEDULED' },
        data: { status: 'SENT', sentAt: new Date(), providerRef },
      });
      sent += count;
    } catch (err) {
      await prisma.notification.update({
        where: { id: n.id },
        data: { status: 'FAILED', failureReason: (err as Error).message.slice(0, 200) },
      });
    }
  }
  return sent;
}

export async function myNotifications(userId: string) {
  const rows = await prisma.notification.findMany({
    where: { userId },
    orderBy: { scheduledFor: 'desc' },
    take: 20,
  });
  return rows.map((n) => ({
    id: n.id,
    kind: n.kind,
    scheduledFor: n.scheduledFor,
    status: n.status,
    sentAt: n.sentAt,
  }));
}
