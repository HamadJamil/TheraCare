import type { ConsentDecision } from '@prisma/client';
import { prisma } from '../../config/database';
import { AppError, Errors } from '../../common/errors';
import { pickLocale, type Locale } from '../../common/localized';
import { audit } from '../audit/audit.service';
import { advanceJourney } from '../journey/journey.service';

const activeTypes = () =>
  prisma.consentType.findMany({
    where: { active: true },
    orderBy: [{ required: 'desc' }, { key: 'asc' }],
  });

export async function listTypes(locale: Locale) {
  return (await activeTypes()).map((t) => ({
    id: t.id,
    key: t.key,
    policyVersion: t.policyVersion,
    required: t.required,
    title: pickLocale(t.title, locale),
    summary: pickLocale(t.summary, locale),
    details: pickLocale(t.details, locale),
  }));
}

export async function hasRequiredConsents(userId: string): Promise<boolean> {
  const required = (await activeTypes()).filter((t) => t.required);
  const granted = await prisma.consent.count({
    where: { userId, decision: 'GRANTED', consentTypeId: { in: required.map((t) => t.id) } },
  });
  return granted === required.length;
}

/** Advances to PRIVACY_COMPLETE once the patient is entitled and has given all required consents. */
export async function syncPrivacyMilestone(userId: string) {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  if (user.journeyState === 'ENTITLEMENT_ACTIVE' && (await hasRequiredConsents(userId))) {
    await advanceJourney(userId, 'PRIVACY_COMPLETE');
  }
}

type DecisionInput = {
  consentTypeId: string;
  decision: Extract<ConsentDecision, 'GRANTED' | 'DECLINED'>;
  locale: Locale;
  appVersion?: string;
};

async function writeDecision(
  userId: string,
  consentTypeId: string,
  decision: ConsentDecision,
  meta: { locale: Locale; appVersion?: string; requestId?: string },
) {
  const type = await prisma.consentType.findUnique({ where: { id: consentTypeId } });
  if (!type?.active) throw Errors.notFound('The privacy topic');

  return prisma.$transaction(async (tx) => {
    const consent = await tx.consent.upsert({
      where: { userId_consentTypeId: { userId, consentTypeId } },
      create: { userId, consentTypeId, policyVersion: type.policyVersion, decision },
      update: { decision, policyVersion: type.policyVersion, decidedAt: new Date() },
    });
    await tx.consentEvent.create({
      data: {
        consentId: consent.id,
        userId,
        decision,
        policyVersion: type.policyVersion,
        locale: meta.locale,
        appVersion: meta.appVersion,
      },
    });
    await audit(
      {
        action: `consent.${decision.toLowerCase()}`,
        resourceType: 'consent',
        resourceId: consent.id,
        actorId: userId,
        requestId: meta.requestId,
        sourceContext: { key: type.key, policyVersion: type.policyVersion },
      },
      tx,
    );
    return { consent, type };
  });
}

export async function recordDecision(userId: string, input: DecisionInput, requestId?: string) {
  const { consent, type } = await writeDecision(userId, input.consentTypeId, input.decision, {
    ...input,
    requestId,
  });
  await syncPrivacyMilestone(userId);
  return {
    id: consent.id,
    key: type.key,
    decision: consent.decision,
    policyVersion: consent.policyVersion,
    decidedAt: consent.decidedAt,
  };
}

const CONSEQUENCES: Record<'required' | 'optional', string> = {
  required:
    'Without this consent TheraCare cannot process your treatment data, so treatment features are paused. Existing records are kept as the law requires. You can give consent again at any time.',
  optional: 'We will no longer use your data for this purpose. Your treatment is not affected.',
};

export async function withdraw(
  userId: string,
  consentId: string,
  locale: Locale,
  requestId?: string,
) {
  const consent = await prisma.consent.findFirst({ where: { id: consentId, userId } });
  if (!consent) throw Errors.notFound('The consent');
  if (consent.decision !== 'GRANTED') {
    throw new AppError(409, 'CONSENT_NOT_ACTIVE', 'This consent is not currently given.');
  }
  const { type } = await writeDecision(userId, consent.consentTypeId, 'WITHDRAWN', {
    locale,
    requestId,
  });
  return {
    id: consent.id,
    key: type.key,
    decision: 'WITHDRAWN',
    consequence: CONSEQUENCES[type.required ? 'required' : 'optional'],
  };
}

export async function myConsents(userId: string, locale: Locale) {
  const [consents, events] = await Promise.all([
    prisma.consent.findMany({ where: { userId }, include: { consentType: true } }),
    prisma.consentEvent.findMany({
      where: { userId },
      include: { consent: { include: { consentType: true } } },
      orderBy: { occurredAt: 'desc' },
    }),
  ]);
  return {
    current: consents.map((c) => ({
      id: c.id,
      key: c.consentType.key,
      title: pickLocale(c.consentType.title, locale),
      required: c.consentType.required,
      decision: c.decision,
      policyVersion: c.policyVersion,
      decidedAt: c.decidedAt,
    })),
    history: events.map((e) => ({
      id: e.id,
      key: e.consent.consentType.key,
      decision: e.decision,
      policyVersion: e.policyVersion,
      occurredAt: e.occurredAt,
    })),
  };
}
