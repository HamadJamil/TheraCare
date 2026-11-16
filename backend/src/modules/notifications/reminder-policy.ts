import { addDays, startOfZonedDay } from '../../common/dates';

const toMinutes = (clock: string) => {
  const [h, m] = clock.split(':').map(Number);
  return h * 60 + m;
};

/** True when `clock` falls inside a quiet window that may wrap past midnight. */
export function inQuietHours(clock: string, start: string, end: string): boolean {
  const t = toMinutes(clock);
  const s = toMinutes(start);
  const e = toMinutes(end);
  return s <= e ? t >= s && t < e : t >= s || t < e;
}

export type ReminderPrefs = {
  reminderTime: string;
  quietHoursStart: string;
  quietHoursEnd: string;
  timezone: string;
};

/**
 * Next reminder instant at or after `now`, honouring the patient's time zone and
 * quiet hours (a reminder inside quiet hours moves to the end of the window).
 */
export function nextReminder(now: Date, prefs: ReminderPrefs): { at: Date; localDate: string } {
  const clock = inQuietHours(prefs.reminderTime, prefs.quietHoursStart, prefs.quietHoursEnd)
    ? prefs.quietHoursEnd
    : prefs.reminderTime;
  const minutes = toMinutes(clock);

  for (const offset of [0, 1]) {
    const dayStart = startOfZonedDay(addDays(now, offset), prefs.timezone);
    const at = new Date(dayStart.getTime() + minutes * 60_000);
    if (at >= now) {
      const localDate = new Intl.DateTimeFormat('en-CA', { timeZone: prefs.timezone }).format(at);
      return { at, localDate };
    }
  }
  throw new Error('unreachable: a reminder always exists within two days');
}
