import type { PrismaClient } from '@prisma/client';

/**
 * Two demo plans. Assignment uses the baseline score range (0–34, higher = more
 * burden). These rules are illustrative, not clinical guidance.
 */
const PLANS = [
  {
    key: 'gentle-start',
    title: { de: 'Sanfter Einstieg', en: 'Gentle start' },
    objectives: [
      { de: 'Den Rücken täglich sanft bewegen', en: 'Move your back gently every day' },
      { de: 'Vertrauen in Bewegung aufbauen', en: 'Build confidence in movement' },
    ],
    durationWeeks: 12,
    minBaselineScore: 15,
    maxBaselineScore: 34,
    exercises: ['pelvic-tilt', 'seated-rotation', 'cat-cow-seated'],
  },
  {
    key: 'active-mobility',
    title: { de: 'Aktive Beweglichkeit', en: 'Active mobility' },
    objectives: [
      { de: 'Beweglichkeit und Kraft verbessern', en: 'Improve mobility and strength' },
      { de: 'Aktivität in den Alltag bringen', en: 'Bring activity into everyday life' },
    ],
    durationWeeks: 12,
    minBaselineScore: 0,
    maxBaselineScore: 14,
    exercises: ['pelvic-tilt', 'knee-to-chest', 'bridge', 'seated-rotation', 'easy-walk'],
  },
];

export async function seedTreatments(
  prisma: PrismaClient,
  productId: string,
  exerciseVersions: Record<string, string>,
) {
  for (const plan of PLANS) {
    const parent = await prisma.treatmentPlan.upsert({
      where: { key: plan.key },
      create: { key: plan.key, productId },
      update: {},
    });
    const existing = await prisma.treatmentVersion.findUnique({
      where: { planId_version: { planId: parent.id, version: 1 } },
    });
    if (existing) continue;
    await prisma.treatmentVersion.create({
      data: {
        planId: parent.id,
        version: 1,
        status: 'PUBLISHED',
        publishedAt: new Date(),
        title: plan.title,
        objectives: plan.objectives,
        durationWeeks: plan.durationWeeks,
        minBaselineScore: plan.minBaselineScore,
        maxBaselineScore: plan.maxBaselineScore,
        exercises: {
          create: plan.exercises.map((key, order) => ({
            exerciseVersionId: exerciseVersions[key],
            order,
          })),
        },
      },
    });
  }
}
