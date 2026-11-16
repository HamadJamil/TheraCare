import type { Prisma, Role } from '@prisma/client';
import { prisma, type Tx } from '../../config/database';

export type AuditEntry = {
  action: string;
  resourceType: string;
  resourceId?: string;
  actorId?: string;
  actorRole?: Role;
  outcome?: 'SUCCESS' | 'FAILURE';
  requestId?: string;
  reason?: string;
  sourceContext?: Prisma.InputJsonValue;
};

/**
 * Appends an audit event. Callers must pass references only — never medical
 * payloads, tokens or activation codes.
 */
export async function audit(entry: AuditEntry, tx: Tx = prisma): Promise<void> {
  await tx.auditEvent.create({ data: { outcome: 'SUCCESS', ...entry } });
}
