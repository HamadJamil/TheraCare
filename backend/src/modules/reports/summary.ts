import { prisma } from '../../config/database';
import { pickLocale, type Locale } from '../../common/localized';

const avg = (values: number[]) =>
  values.length ? Math.round((values.reduce((a, b) => a + b, 0) / values.length) * 10) / 10 : null;

/**
 * Collects the facts shown in the treatment summary. Contains only the
 * patient's own records and no clinical interpretation.
 */
export async function buildSummary(userId: string, locale: Locale) {
  const user = await prisma.user.findUniqueOrThrow({
    where: { id: userId },
    include: { profile: true },
  });
  const treatment = await prisma.patientTreatment.findFirst({
    where: { userId },
    orderBy: { startedAt: 'desc' },
    include: { treatmentVersion: true },
  });
  const from = treatment?.startedAt ?? user.createdAt;
  const to = treatment?.completedAt ?? new Date();

  const [completions, pains, assessments] = await Promise.all([
    prisma.exerciseCompletion.findMany({ where: { userId, completedAt: { gte: from, lte: to } } }),
    prisma.observation.findMany({
      where: {
        userId,
        kind: 'PAIN_INTENSITY',
        status: 'CURRENT',
        effectiveAt: { gte: from, lte: to },
      },
      orderBy: { effectiveAt: 'asc' },
    }),
    prisma.assessment.findMany({ where: { userId } }),
  ]);
  const firstWeekEnd = new Date(from.getTime() + 7 * 86_400_000);
  const lastWeekStart = new Date(to.getTime() - 7 * 86_400_000);

  return {
    patient: { name: `${user.profile?.firstName ?? ''} ${user.profile?.lastName ?? ''}`.trim() },
    period: { from, to },
    plan: treatment && {
      title: pickLocale(treatment.treatmentVersion.title, locale),
      version: treatment.treatmentVersion.version,
      status: treatment.status,
    },
    exercises: {
      completed: completions.length,
      activeDays: new Set(completions.map((c) => c.completedAt.toISOString().slice(0, 10))).size,
    },
    pain: {
      entries: pains.length,
      firstWeekAverage: avg(pains.filter((p) => p.effectiveAt < firstWeekEnd).map((p) => p.value)),
      lastWeekAverage: avg(pains.filter((p) => p.effectiveAt >= lastWeekStart).map((p) => p.value)),
    },
    assessments: {
      baseline: assessments.find((a) => a.purpose === 'BASELINE')?.score ?? null,
      final: assessments.find((a) => a.purpose === 'FINAL')?.score ?? null,
    },
  };
}

export type TreatmentSummary = Awaited<ReturnType<typeof buildSummary>>;
