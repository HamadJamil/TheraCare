import { inQuietHours, nextReminder } from '../../src/modules/notifications/reminder-policy';
import { REMINDER_TEXT } from '../../src/modules/notifications/provider';

const prefs = {
  reminderTime: '09:00',
  quietHoursStart: '21:00',
  quietHoursEnd: '08:00',
  timezone: 'Europe/Berlin',
};

describe('inQuietHours', () => {
  it('handles windows that wrap midnight', () => {
    expect(inQuietHours('23:30', '21:00', '08:00')).toBe(true);
    expect(inQuietHours('07:59', '21:00', '08:00')).toBe(true);
    expect(inQuietHours('08:00', '21:00', '08:00')).toBe(false);
  });

  it('handles same-day windows', () => {
    expect(inQuietHours('13:00', '12:00', '14:00')).toBe(true);
    expect(inQuietHours('15:00', '12:00', '14:00')).toBe(false);
  });
});

describe('nextReminder', () => {
  it('schedules later today in the patient time zone', () => {
    const r = nextReminder(new Date('2026-11-16T06:00:00Z'), prefs);
    expect(r.at.toISOString()).toBe('2026-11-16T08:00:00.000Z');
    expect(r.localDate).toBe('2026-11-16');
  });

  it('rolls over to tomorrow when today has passed', () => {
    const r = nextReminder(new Date('2026-11-16T12:00:00Z'), prefs);
    expect(r.at.toISOString()).toBe('2026-11-17T08:00:00.000Z');
    expect(r.localDate).toBe('2026-11-17');
  });

  it('moves reminders out of quiet hours', () => {
    const r = nextReminder(new Date('2026-11-16T03:00:00Z'), { ...prefs, reminderTime: '06:30' });
    expect(r.at.toISOString()).toBe('2026-11-16T07:00:00.000Z');
  });

  it('respects a different time zone', () => {
    const r = nextReminder(new Date('2026-11-16T00:00:00Z'), {
      ...prefs,
      timezone: 'America/New_York',
    });
    expect(r.at.toISOString()).toBe('2026-11-16T14:00:00.000Z');
  });
});

describe('reminder text', () => {
  it('never mentions back pain, symptoms or therapy type', () => {
    const all = JSON.stringify(REMINDER_TEXT).toLowerCase();
    for (const word of [
      'pain',
      'schmerz',
      'rücken',
      'back',
      'therapy',
      'therapie',
      'exercise',
      'übung',
    ]) {
      expect(all).not.toContain(word);
    }
  });
});
