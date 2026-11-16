import { prisma } from '../../config/database';
import { DAY_MS, addDays, startOfUtcWeek } from '../../common/dates';
import type { Locale } from '../../common/localized';
import { listAssigned } from '../questionnaires/questionnaires.service';
import { getCurrent } from '../treatments/treatments.service';
import { observationView } from '../tracking/tracking.service';

const round1 = (n: number) => Math.round(n * 10) / 10;

export type WeekSummary = {
  weekStart: string;
  exercisesCompleted: number;
  activeDays: number;
  painEntries: number;
  painAverage: number | null;
};

/** Aggregates per ISO week (Monday, UTC) from source events — no stored totals that can drift. */
export async function weeklySummaries(userId: string, weeks: number): Promise<WeekSummary[]> {
  const firstWeek = addDays(startOfUtcWeek(new Date()), -(weeks - 1) * 7);
  const [completions, pains] = await Promise.all([
    prisma.exerciseCompletion.findMany({
      where: { userId, completedAt: { gte: firstWeek } },
      select: { completedAt: true },
    }),
    prisma.observation.findMany({
      where: { userId, kind: 'PAIN_INTENSITY', status: 'CURRENT', effectiveAt: { gte: firstWeek } },
      select: { effectiveAt: true, value: true },
    }),
  ]);

  const weekIndex = (d: Date) => Math.floor((d.getTime() - firstWeek.getTime()) / (7 * DAY_MS));
  return Array.from({ length: weeks }, (_, i) => {
    const inWeek = <T extends { at: Date }>(rows: T[]) => rows.filter((r) => weekIndex(r.at) === i);
    const done = inWeek(completions.map((c) => ({ at: c.completedAt })));
    const pain = inWeek(pains.map((p) => ({ at: p.effectiveAt, value: p.value })));
    return {
      weekStart: addDays(firstWeek, i * 7)
        .toISOString()
        .slice(0, 10),
      exercisesCompleted: done.length,
      activeDays: new Set(done.map((d) => d.at.toISOString().slice(0, 10))).size,
      painEntries: pain.length,
      painAverage: pain.length ? round1(pain.reduce((s, p) => s + p.value, 0) / pain.length) : null,
    };
  });
}

/** Plain-language text alternative for a week (used instead of relying on a chart). */
export function describeWeek(week: WeekSummary, locale: Locale): string {
  const pain =
    week.painAverage === null
      ? locale === 'de'
        ? 'keine Schmerzangaben'
        : 'no pain entries'
      : locale === 'de'
        ? `durchschnittliche Schmerzstärke ${week.painAverage} von 10`
        : `average pain ${week.painAverage} out of 10`;
  return locale === 'de'
    ? `${week.exercisesCompleted} Übungen an ${week.activeDays} Tagen, ${pain}.`
    : `${week.exercisesCompleted} exercises on ${week.activeDays} days, ${pain}.`;
}

export async function weekly(userId: string, weeks: number, locale: Locale) {
  const summaries = await weeklySummaries(userId, weeks);
  return summaries.map((w) => ({ ...w, text: describeWeek(w, locale) }));
}

export async function overview(userId: string, locale: Locale) {
  const [treatment, questionnaires, recent, [thisWeek]] = await Promise.all([
    getCurrent(userId, locale),
    listAssigned(userId, locale),
    prisma.observation.findMany({
      where: { userId, status: 'CURRENT' },
      orderBy: { effectiveAt: 'desc' },
      take: 5,
    }),
    weeklySummaries(userId, 1),
  ]);
  const nextExercise = treatment?.today.find((t) => !t.completed) ?? null;
  const openQuestionnaire = questionnaires.find((q) => q.status !== 'SUBMITTED') ?? null;

  return {
    treatment: treatment && {
      id: treatment.id,
      status: treatment.status,
      title: treatment.plan.title,
      week: treatment.week,
      totalWeeks: treatment.totalWeeks,
    },
    today: treatment && {
      planned: treatment.today.length,
      completed: treatment.today.filter((t) => t.completed).length,
    },
    nextAction: nextExercise
      ? { type: 'EXERCISE', id: nextExercise.exerciseId, title: nextExercise.title }
      : openQuestionnaire
        ? { type: 'QUESTIONNAIRE', id: openQuestionnaire.id, title: openQuestionnaire.title }
        : null,
    openQuestionnaires: questionnaires.filter((q) => q.status !== 'SUBMITTED').length,
    recentEntries: recent.map(observationView),
    thisWeek: { ...thisWeek, text: describeWeek(thisWeek, locale) },
  };
}
