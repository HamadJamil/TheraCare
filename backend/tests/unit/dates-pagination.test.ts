import { addDays, startOfUtcWeek } from '../../src/common/dates';
import { pageArgs, toPage } from '../../src/common/pagination';

describe('dates', () => {
  it('finds Monday as start of week', () => {
    const sunday = new Date('2026-11-15T18:00:00Z');
    expect(startOfUtcWeek(sunday).toISOString()).toBe('2026-11-09T00:00:00.000Z');
  });

  it('adds days', () => {
    expect(addDays(new Date('2026-01-31T00:00:00Z'), 1).toISOString()).toBe(
      '2026-02-01T00:00:00.000Z',
    );
  });
});

describe('pagination', () => {
  it('requests one extra row to detect a next page', () => {
    expect(pageArgs({ limit: 10 })).toEqual({ take: 11 });
  });

  it('returns next cursor only when more rows exist', () => {
    const rows = [{ id: 'a' }, { id: 'b' }, { id: 'c' }];
    expect(toPage(rows, 2)).toEqual({ items: [{ id: 'a' }, { id: 'b' }], nextCursor: 'b' });
    expect(toPage(rows, 5).nextCursor).toBeNull();
  });
});
