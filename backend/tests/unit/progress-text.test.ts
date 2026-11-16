import { describeWeek } from '../../src/modules/progress/progress.service';

const week = {
  weekStart: '2026-11-16',
  exercisesCompleted: 9,
  activeDays: 4,
  painEntries: 3,
  painAverage: 4.3,
};

describe('describeWeek', () => {
  it('describes a week in English', () => {
    expect(describeWeek(week, 'en')).toBe('9 exercises on 4 days, average pain 4.3 out of 10.');
  });

  it('describes a week in German', () => {
    expect(describeWeek(week, 'de')).toBe(
      '9 Übungen an 4 Tagen, durchschnittliche Schmerzstärke 4.3 von 10.',
    );
  });

  it('handles weeks without pain entries', () => {
    expect(describeWeek({ ...week, painAverage: null, painEntries: 0 }, 'en')).toMatch(
      /no pain entries/,
    );
  });
});
