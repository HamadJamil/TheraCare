import { prisma } from '../config/database';
import { env } from '../config/env';
import { addDays } from '../common/dates';
import { audit } from '../modules/audit/audit.service';

const ANONYMISED_DOMAIN = '@anonymised.invalid';

/**
 * Applies the documented retention policy:
 * - removes expired technical records (sessions, codes, idempotency keys);
 * - anonymises identity data of closed accounts after the retention period.
 * Clinical records are never cascade-deleted; they become pseudonymous.
 */
export async function runRetention(now = new Date()) {
  const cutoff = addDays(now, -30);
  const [sessions, verifications, resets, idempotency] = await Promise.all([
    prisma.userSession.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: cutoff } },
          { revokedAt: { lt: cutoff } },
          { rotatedAt: { lt: cutoff } },
        ],
      },
    }),
    prisma.emailVerification.deleteMany({ where: { expiresAt: { lt: cutoff } } }),
    prisma.passwordReset.deleteMany({ where: { expiresAt: { lt: cutoff } } }),
    prisma.idempotencyRecord.deleteMany({ where: { expiresAt: { lt: now } } }),
  ]);

  const closed = await prisma.user.findMany({
    where: {
      status: 'CLOSED',
      closedAt: { lt: addDays(now, -env.CLOSED_ACCOUNT_RETENTION_DAYS) },
      NOT: { email: { endsWith: ANONYMISED_DOMAIN } },
    },
  });
  for (const user of closed) {
    await prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id: user.id },
        data: { email: `${user.id}${ANONYMISED_DOMAIN}`, passwordHash: '!' },
      });
      await tx.patientProfile.updateMany({
        where: { userId: user.id },
        data: { firstName: 'Anonymised', lastName: 'Anonymised', dateOfBirth: null },
      });
      await tx.supportTicket.updateMany({
        where: { userId: user.id },
        data: { message: '[removed]', subject: '[removed]' },
      });
      await audit(
        { action: 'retention.account_anonymised', resourceType: 'user', resourceId: user.id },
        tx,
      );
    });
  }

  return {
    sessions: sessions.count,
    verifications: verifications.count,
    resets: resets.count,
    idempotency: idempotency.count,
    anonymised: closed.length,
  };
}
