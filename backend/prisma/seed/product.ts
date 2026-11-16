import type { PrismaClient } from '@prisma/client';
import { APP_PRODUCT_CODE } from '../../src/config/product';

export async function seedProducts(prisma: PrismaClient) {
  const product = await prisma.digaProduct.upsert({
    where: { code: APP_PRODUCT_CODE },
    create: { code: APP_PRODUCT_CODE, name: 'TheraCare Rücken', durationDays: 90 },
    update: {},
  });
  // A second product exists only to demonstrate wrong-product rejection.
  const other = await prisma.digaProduct.upsert({
    where: { code: 'OTHER-APP' },
    create: { code: 'OTHER-APP', name: 'Other demo app', durationDays: 90 },
    update: {},
  });
  return { product, other };
}
