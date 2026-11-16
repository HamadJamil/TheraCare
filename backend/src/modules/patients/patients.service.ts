import { prisma } from '../../config/database';
import { Errors } from '../../common/errors';
import { audit } from '../audit/audit.service';
import { revokeAllSessions } from '../auth/auth.service';
import { verifyPassword } from '../auth/password';
import { getJourney } from '../journey/journey.service';
import type { z } from 'zod';
import type { updatePreferencesSchema, updateProfileSchema } from './patients.schemas';

export async function getMe(userId: string) {
  const user = await prisma.user.findUniqueOrThrow({
    where: { id: userId },
    include: { profile: true },
  });
  return {
    id: user.id,
    email: user.email,
    accountStatus: user.status,
    journey: await getJourney(userId),
    profile: user.profile && {
      firstName: user.profile.firstName,
      lastName: user.profile.lastName,
      dateOfBirth: user.profile.dateOfBirth,
      preferredLanguage: user.profile.preferredLanguage,
      timezone: user.profile.timezone,
    },
  };
}

export async function updateProfile(
  userId: string,
  data: z.infer<typeof updateProfileSchema>,
  requestId?: string,
) {
  await prisma.patientProfile.update({ where: { userId }, data });
  await audit({
    action: 'patient.profile_updated',
    resourceType: 'patient_profile',
    resourceId: userId,
    actorId: userId,
    requestId,
    // Field names only — never the values.
    sourceContext: { fields: Object.keys(data) },
  });
  return getMe(userId);
}

const preferencesView = (
  p: Awaited<ReturnType<typeof prisma.patientPreferences.findUniqueOrThrow>>,
) => ({
  textScale: p.textScale,
  highContrast: p.highContrast,
  reducedMotion: p.reducedMotion,
  remindersEnabled: p.remindersEnabled,
  reminderTime: p.reminderTime,
  quietHoursStart: p.quietHoursStart,
  quietHoursEnd: p.quietHoursEnd,
});

export async function getPreferences(userId: string) {
  return preferencesView(
    await prisma.patientPreferences.upsert({ where: { userId }, create: { userId }, update: {} }),
  );
}

export async function updatePreferences(
  userId: string,
  data: z.infer<typeof updatePreferencesSchema>,
) {
  const prefs = await prisma.patientPreferences.upsert({
    where: { userId },
    create: { userId, ...data },
    update: data,
  });
  if (data.remindersEnabled === false) {
    await prisma.notification.updateMany({
      where: { userId, status: 'SCHEDULED' },
      data: { status: 'CANCELLED' },
    });
  }
  return preferencesView(prefs);
}

/**
 * Closes the account. Clinical records are retained according to the retention
 * policy (see jobs/retention) — nothing is cascade-deleted here.
 */
export async function closeAccount(userId: string, password: string, requestId?: string) {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  if (!(await verifyPassword(user.passwordHash, password))) throw Errors.invalidCredentials();

  await prisma.$transaction(async (tx) => {
    await tx.user.update({
      where: { id: userId },
      data: { status: 'CLOSED', journeyState: 'ACCOUNT_CLOSED', closedAt: new Date() },
    });
    await tx.notification.updateMany({
      where: { userId, status: 'SCHEDULED' },
      data: { status: 'CANCELLED' },
    });
    await revokeAllSessions(userId, 'account_closed', tx);
    await audit(
      {
        action: 'patient.account_closed',
        resourceType: 'user',
        resourceId: userId,
        actorId: userId,
        requestId,
      },
      tx,
    );
  });
  return {
    closed: true,
    retention:
      'Your sign-in has been removed. Treatment records are kept only as long as the law requires and then deleted or anonymised.',
  };
}
