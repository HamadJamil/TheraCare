export const DAY_MS = 24 * 60 * 60 * 1000;

export function addDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * DAY_MS);
}

export function startOfUtcDay(date: Date): Date {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

/** Monday 00:00 UTC of the week containing `date`. */
export function startOfUtcWeek(date: Date): Date {
  const day = startOfUtcDay(date);
  const offset = (day.getUTCDay() + 6) % 7;
  return addDays(day, -offset);
}
