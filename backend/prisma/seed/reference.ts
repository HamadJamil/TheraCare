import type { PrismaClient } from '@prisma/client';
import { seedConsentTypes } from './consents';
import { seedExercises } from './exercises';
import { seedProducts } from './product';
import { seedQuestionnaires } from './questionnaires';
import { seedTreatments } from './treatments';

/** Idempotently loads all reference content (product, consents, exercises, plans, questionnaires). */
export async function seedReference(prisma: PrismaClient) {
  const products = await seedProducts(prisma);
  await seedConsentTypes(prisma);
  const exerciseVersions = await seedExercises(prisma);
  await seedTreatments(prisma, products.product.id, exerciseVersions);
  await seedQuestionnaires(prisma);
  return products;
}
