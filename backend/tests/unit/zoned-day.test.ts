import { startOfZonedDay } from '../../src/common/dates';

describe('startOfZonedDay', () => {
  it('returns local midnight in Berlin winter time', () => {
    expect(startOfZonedDay(new Date('2026-11-16T10:00:00Z'), 'Europe/Berlin').toISOString()).toBe(
      '2026-11-15T23:00:00.000Z',
    );
  });

  it('returns local midnight in Berlin summer time', () => {
    expect(startOfZonedDay(new Date('2026-07-01T10:00:00Z'), 'Europe/Berlin').toISOString()).toBe(
      '2026-06-30T22:00:00.000Z',
    );
  });

  it('handles instants just after local midnight', () => {
    expect(startOfZonedDay(new Date('2026-11-15T23:30:00Z'), 'Europe/Berlin').toISOString()).toBe(
      '2026-11-15T23:00:00.000Z',
    );
  });

  it('works for UTC', () => {
    expect(startOfZonedDay(new Date('2026-11-16T10:00:00Z'), 'UTC').toISOString()).toBe(
      '2026-11-16T00:00:00.000Z',
    );
  });
});
