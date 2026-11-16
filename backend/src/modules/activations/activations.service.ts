import { prisma, type Tx } from '../../config/database';
import { APP_PRODUCT_CODE } from '../../config/product';
import { AppError } from '../../common/errors';
import { addDays } from '../../common/dates';
import { audit } from '../audit/audit.service';
import { advanceJourney } from '../journey/journey.service';
import { syncPrivacyMilestone } from '../consents/consents.service';
import { hashActivationCode } from './activation-code';

type LockedActivation = {
  id: string;
  status: 'UNUSED' | 'REDEEMED' | 'EXPIRED' | 'REVOKED';
  expiresAt: Date;
  userId: string | null;
  productCode: string;
  durationDays: number;
  productId: string;
};

const reject = (code: string, message: string) => new AppError(400, code, message);

const REJECTIONS = {
  invalid: () =>
    reject(
      'ACTIVATION_INVALID',
      'This code is not valid. Please check each character and try again.',
    ),
  used: () =>
    reject(
      'ACTIVATION_ALREADY_USED',
      'This code has already been used. Please contact your health insurer for a new code.',
    ),
  expired: () =>
    reject(
      'ACTIVATION_EXPIRED',
      'This code has expired. Please ask your health insurer for a new code.',
    ),
  revoked: () =>
    reject(
      'ACTIVATION_REVOKED',
      'This code is no longer valid. Please contact your health insurer.',
    ),
  wrongProduct: () => reject('ACTIVATION_WRONG_PRODUCT', 'This code belongs to a different app.'),
};

export function entitlementView(e: { id: string; status: string; startsAt: Date; endsAt: Date }) {
  const active = e.status === 'ACTIVE' && e.endsAt > new Date();
  return {
    id: e.id,
    status: active ? 'ACTIVE' : e.status === 'ACTIVE' ? 'EXPIRED' : e.status,
    startsAt: e.startsAt,
    endsAt: e.endsAt,
  };
}

async function lockActivation(tx: Tx, codeHash: string): Promise<LockedActivation | undefined> {
  // Row-level lock: concurrent redemptions of the same code are serialised.
  const rows = await tx.$queryRaw<LockedActivation[]>`
    SELECT a.id, a.status, a."expiresAt", a."userId", a."productId",
           p.code AS "productCode", p."durationDays"
    FROM activations a JOIN diga_products p ON p.id = a."productId"
    WHERE a."codeHash" = ${codeHash}
    FOR UPDATE OF a`;
  return rows[0];
}

/** Atomically redeems a code and creates exactly one entitlement. */
export async function redeem(userId: string, code: string, requestId?: string) {
  const codeHash = hashActivationCode(code);
  try {
    const entitlement = await prisma.$transaction(async (tx) => {
      const activation = await lockActivation(tx, codeHash);
      if (!activation) throw REJECTIONS.invalid();

      if (activation.status === 'REDEEMED') {
        // A retry by the same patient returns the original result instead of failing.
        if (activation.userId !== userId) throw REJECTIONS.used();
        return tx.entitlement.findUniqueOrThrow({ where: { activationId: activation.id } });
      }
      if (activation.status === 'REVOKED') throw REJECTIONS.revoked();
      if (activation.status === 'EXPIRED' || activation.expiresAt < new Date())
        throw REJECTIONS.expired();
      if (activation.productCode !== APP_PRODUCT_CODE) throw REJECTIONS.wrongProduct();

      if (await findActiveEntitlement(userId, tx)) {
        throw new AppError(
          409,
          'ALREADY_ACTIVATED',
          'TheraCare is already activated for your account.',
        );
      }

      const now = new Date();
      await tx.activation.update({
        where: { id: activation.id },
        data: { status: 'REDEEMED', userId, redeemedAt: now },
      });
      const created = await tx.entitlement.create({
        data: {
          userId,
          productId: activation.productId,
          activationId: activation.id,
          startsAt: now,
          endsAt: addDays(now, activation.durationDays),
        },
      });
      await advanceJourney(userId, 'ENTITLEMENT_ACTIVE', tx);
      await audit(
        {
          action: 'activation.redeemed',
          resourceType: 'entitlement',
          resourceId: created.id,
          actorId: userId,
          requestId,
        },
        tx,
      );
      return created;
    });
    await syncPrivacyMilestone(userId);
    return entitlementView(entitlement);
  } catch (err) {
    if (err instanceof AppError) {
      await audit({
        action: 'activation.rejected',
        resourceType: 'activation',
        actorId: userId,
        outcome: 'FAILURE',
        requestId,
        reason: err.code,
      });
    }
    throw err;
  }
}

function findActiveEntitlement(userId: string, tx: Tx = prisma) {
  return tx.entitlement.findFirst({
    where: { userId, status: 'ACTIVE', endsAt: { gt: new Date() } },
    orderBy: { startsAt: 'desc' },
  });
}

export async function hasActiveEntitlement(userId: string) {
  return (await findActiveEntitlement(userId)) !== null;
}

export async function currentEntitlement(userId: string) {
  const latest = await prisma.entitlement.findFirst({
    where: { userId },
    orderBy: { startsAt: 'desc' },
    include: { product: true },
  });
  if (!latest) return null;
  return {
    ...entitlementView(latest),
    product: { code: latest.product.code, name: latest.product.name },
  };
}

export async function activationStatus(userId: string) {
  const entitlement = await currentEntitlement(userId);
  return { activated: entitlement?.status === 'ACTIVE', entitlement };
}
