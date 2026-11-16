import { prisma } from '../../src/config/database';
import { seedConsentTypes } from '../../prisma/seed/consents';
import { seedProducts } from '../../prisma/seed/product';
import {
  generateActivationCode,
  hashActivationCode,
} from '../../src/modules/activations/activation-code';
import { addDays } from '../../src/common/dates';
import { api } from './app';
import type { TestUser } from './users';

export async function seedBase() {
  await seedConsentTypes(prisma);
  return seedProducts(prisma);
}

type CodeOptions = {
  productId?: string;
  status?: 'UNUSED' | 'REVOKED' | 'EXPIRED';
  expiresAt?: Date;
};

/** Creates an activation code (raw value returned once, only its hash is stored). */
export async function createCode(options: CodeOptions = {}) {
  const { product } = await seedProducts(prisma);
  const code = generateActivationCode();
  await prisma.activation.create({
    data: {
      codeHash: hashActivationCode(code),
      productId: options.productId ?? product.id,
      status: options.status ?? 'UNUSED',
      expiresAt: options.expiresAt ?? addDays(new Date(), 30),
    },
  });
  return code;
}

/** Activates and grants every consent type — the precondition for treatment endpoints. */
export async function activateAndConsent(user: TestUser) {
  await seedBase();
  await api()
    .post('/api/v1/activations/redeem')
    .set('authorization', user.bearer)
    .send({ code: await createCode() })
    .expect(201);
  const types = await prisma.consentType.findMany({ where: { active: true } });
  for (const type of types) {
    await api()
      .post('/api/v1/consents')
      .set('authorization', user.bearer)
      .send({ consentTypeId: type.id, decision: 'GRANTED' })
      .expect(201);
  }
}
