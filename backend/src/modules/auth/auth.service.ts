import { randomUUID } from 'node:crypto';
import type { User } from '@prisma/client';
import { prisma, type Tx } from '../../config/database';
import { env } from '../../config/env';
import { AppError, Errors } from '../../common/errors';
import { addDays } from '../../common/dates';
import {
  HUMAN_ALPHABET,
  hmac,
  normaliseCode,
  numericCode,
  randomCode,
  randomToken,
  safeEqual,
} from '../../common/crypto';
import { sendMail } from '../../infrastructure/mailer';
import { audit } from '../audit/audit.service';
import { advanceJourney } from '../journey/journey.service';
import { DUMMY_HASH_PROMISE, hashPassword, verifyPassword } from './password';
import { signAccessToken } from './tokens';

const VERIFICATION_TTL_MINUTES = 30;
const VERIFICATION_MAX_ATTEMPTS = 5;
const RESET_TTL_MINUTES = 30;

export type SessionTokens = {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
};

type Context = { requestId?: string; deviceLabel?: string };

// ───────────── Sessions ─────────────

async function issueSession(
  user: Pick<User, 'id' | 'role'>,
  ctx: Context,
  familyId: string = randomUUID(),
  tx: Tx = prisma,
): Promise<SessionTokens> {
  const refreshToken = randomToken();
  const session = await tx.userSession.create({
    data: {
      userId: user.id,
      familyId,
      refreshTokenHash: hmac(refreshToken),
      deviceLabel: ctx.deviceLabel,
      expiresAt: addDays(new Date(), env.REFRESH_TOKEN_TTL_DAYS),
    },
  });
  return {
    accessToken: signAccessToken(user.id, user.role, session.id),
    refreshToken,
    expiresIn: env.ACCESS_TOKEN_TTL_SECONDS,
  };
}

async function revokeFamily(familyId: string, reason: string) {
  await prisma.userSession.updateMany({
    where: { familyId, revokedAt: null },
    data: { revokedAt: new Date(), revokeReason: reason },
  });
}

export async function revokeAllSessions(userId: string, reason: string, tx: Tx = prisma) {
  await tx.userSession.updateMany({
    where: { userId, revokedAt: null },
    data: { revokedAt: new Date(), revokeReason: reason },
  });
}

/** Rotates the refresh credential. Reuse of a rotated credential revokes the whole family. */
export async function refresh(refreshToken: string, ctx: Context): Promise<SessionTokens> {
  const session = await prisma.userSession.findUnique({
    where: { refreshTokenHash: hmac(refreshToken) },
    include: { user: true },
  });
  if (!session) throw Errors.unauthenticated();

  if (session.rotatedAt || session.revokedAt) {
    if (session.rotatedAt && !session.revokedAt) {
      await revokeFamily(session.familyId, 'refresh_token_reuse');
      await audit({
        action: 'auth.refresh_reuse_detected',
        resourceType: 'user_session',
        resourceId: session.id,
        actorId: session.userId,
        outcome: 'FAILURE',
        requestId: ctx.requestId,
      });
    }
    throw Errors.unauthenticated();
  }
  if (session.expiresAt < new Date() || session.user.status === 'CLOSED') {
    throw Errors.unauthenticated();
  }

  return prisma.$transaction(async (tx) => {
    // Conditional update guarantees only one concurrent refresh can win.
    const { count } = await tx.userSession.updateMany({
      where: { id: session.id, rotatedAt: null },
      data: { rotatedAt: new Date(), lastUsedAt: new Date() },
    });
    if (count === 0) throw Errors.unauthenticated();
    return issueSession(
      session.user,
      { deviceLabel: session.deviceLabel ?? undefined },
      session.familyId,
      tx,
    );
  });
}

export async function logout(sessionId: string) {
  await prisma.userSession.updateMany({
    where: { id: sessionId, revokedAt: null },
    data: { revokedAt: new Date(), revokeReason: 'logout' },
  });
}

export async function listSessions(userId: string, currentSessionId: string) {
  const sessions = await prisma.userSession.findMany({
    where: { userId, revokedAt: null, rotatedAt: null, expiresAt: { gt: new Date() } },
    orderBy: { lastUsedAt: 'desc' },
  });
  return sessions.map((s) => ({
    id: s.id,
    deviceLabel: s.deviceLabel,
    createdAt: s.createdAt,
    lastUsedAt: s.lastUsedAt,
    current: s.id === currentSessionId,
  }));
}

export async function revokeSession(userId: string, sessionId: string, requestId?: string) {
  const { count } = await prisma.userSession.updateMany({
    where: { id: sessionId, userId, revokedAt: null },
    data: { revokedAt: new Date(), revokeReason: 'user_revoked' },
  });
  if (count === 0) throw Errors.notFound('The session');
  await audit({
    action: 'auth.session_revoked',
    resourceType: 'user_session',
    resourceId: sessionId,
    actorId: userId,
    requestId,
  });
}

// ───────────── Registration & verification ─────────────

async function sendVerificationCode(user: Pick<User, 'id' | 'email'>, tx: Tx = prisma) {
  const code = numericCode(6);
  await tx.emailVerification.updateMany({
    where: { userId: user.id, consumedAt: null },
    data: { consumedAt: new Date() },
  });
  await tx.emailVerification.create({
    data: {
      userId: user.id,
      codeHash: hmac(`${user.id}:${code}`),
      expiresAt: new Date(Date.now() + VERIFICATION_TTL_MINUTES * 60_000),
    },
  });
  await sendMail({
    to: user.email,
    subject: 'Your TheraCare confirmation code',
    text: `Your confirmation code is ${code}. It is valid for ${VERIFICATION_TTL_MINUTES} minutes.`,
  });
}

type RegisterInput = {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  language: 'de' | 'en';
};

/**
 * Always resolves the same way whether or not the email is already registered,
 * so the response cannot be used to discover accounts.
 */
export async function register(input: RegisterInput, ctx: Context): Promise<void> {
  const existing = await prisma.user.findUnique({ where: { email: input.email } });
  if (existing) {
    await sendMail({
      to: existing.email,
      subject: 'TheraCare registration attempt',
      text: 'Someone tried to register with your email address. If this was you, sign in or reset your password instead.',
    });
    return;
  }
  const passwordHash = await hashPassword(input.password);
  const user = await prisma.$transaction(async (tx) => {
    const created = await tx.user.create({
      data: {
        email: input.email,
        passwordHash,
        profile: {
          create: {
            firstName: input.firstName,
            lastName: input.lastName,
            preferredLanguage: input.language,
          },
        },
        preferences: { create: {} },
      },
    });
    await audit(
      {
        action: 'auth.registered',
        resourceType: 'user',
        resourceId: created.id,
        actorId: created.id,
        requestId: ctx.requestId,
      },
      tx,
    );
    return created;
  });
  await sendVerificationCode(user);
}

export async function resendVerification(email: string): Promise<void> {
  const user = await prisma.user.findUnique({ where: { email } });
  if (user?.status === 'PENDING_VERIFICATION') await sendVerificationCode(user);
}

const invalidCode = () =>
  new AppError(
    400,
    'INVALID_CODE',
    'This code is not correct or has expired. You can request a new code.',
  );

export async function verifyEmail(
  email: string,
  code: string,
  ctx: Context,
): Promise<SessionTokens> {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || user.status !== 'PENDING_VERIFICATION') throw invalidCode();

  const challenge = await prisma.emailVerification.findFirst({
    where: { userId: user.id, consumedAt: null, expiresAt: { gt: new Date() } },
    orderBy: { createdAt: 'desc' },
  });
  if (!challenge || challenge.attempts >= VERIFICATION_MAX_ATTEMPTS) throw invalidCode();

  if (!safeEqual(challenge.codeHash, hmac(`${user.id}:${code}`))) {
    await prisma.emailVerification.update({
      where: { id: challenge.id },
      data: { attempts: { increment: 1 } },
    });
    throw invalidCode();
  }

  return prisma.$transaction(async (tx) => {
    await tx.emailVerification.update({
      where: { id: challenge.id },
      data: { consumedAt: new Date() },
    });
    await tx.user.update({ where: { id: user.id }, data: { status: 'ACTIVE' } });
    await advanceJourney(user.id, 'ENTITLEMENT_PENDING', tx);
    await audit(
      {
        action: 'auth.email_verified',
        resourceType: 'user',
        resourceId: user.id,
        actorId: user.id,
        requestId: ctx.requestId,
      },
      tx,
    );
    return issueSession(user, ctx, undefined, tx);
  });
}

// ───────────── Login ─────────────

export async function login(email: string, password: string, ctx: Context): Promise<SessionTokens> {
  const user = await prisma.user.findUnique({ where: { email } });
  const valid = await verifyPassword(user?.passwordHash ?? (await DUMMY_HASH_PROMISE), password);

  if (!user || !valid || user.status === 'CLOSED' || user.status === 'SUSPENDED') {
    await audit({
      action: 'auth.login_failed',
      resourceType: 'user',
      resourceId: user?.id,
      outcome: 'FAILURE',
      requestId: ctx.requestId,
    });
    throw Errors.invalidCredentials();
  }
  if (user.status === 'PENDING_VERIFICATION') {
    await sendVerificationCode(user);
    throw Errors.precondition(
      'EMAIL_NOT_VERIFIED',
      'Please confirm your email address. We sent you a new code.',
    );
  }

  await audit({
    action: 'auth.login',
    resourceType: 'user',
    resourceId: user.id,
    actorId: user.id,
    actorRole: user.role,
    requestId: ctx.requestId,
  });
  return issueSession(user, ctx);
}

// ───────────── Password recovery ─────────────

export async function forgotPassword(email: string, ctx: Context): Promise<void> {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || user.status === 'CLOSED') return;
  const code = randomCode(12, HUMAN_ALPHABET); // ~60 bits, easy to type from an email
  await prisma.passwordReset.create({
    data: {
      userId: user.id,
      tokenHash: hmac(code),
      expiresAt: new Date(Date.now() + RESET_TTL_MINUTES * 60_000),
    },
  });
  await audit({
    action: 'auth.password_reset_requested',
    resourceType: 'user',
    resourceId: user.id,
    requestId: ctx.requestId,
  });
  const display = code.match(/.{1,4}/g)!.join('-');
  await sendMail({
    to: user.email,
    subject: 'Reset your TheraCare password',
    text: `Your reset code is ${display}. It is valid for ${RESET_TTL_MINUTES} minutes and can be used once.`,
  });
}

export async function resetPassword(token: string, password: string, ctx: Context): Promise<void> {
  const reset = await prisma.passwordReset.findUnique({
    where: { tokenHash: hmac(normaliseCode(token)) },
  });
  if (!reset || reset.usedAt || reset.expiresAt < new Date()) throw invalidCode();
  const passwordHash = await hashPassword(password);

  await prisma.$transaction(async (tx) => {
    const { count } = await tx.passwordReset.updateMany({
      where: { id: reset.id, usedAt: null },
      data: { usedAt: new Date() },
    });
    if (count === 0) throw invalidCode();
    await tx.user.update({ where: { id: reset.userId }, data: { passwordHash } });
    await revokeAllSessions(reset.userId, 'password_reset', tx);
    await audit(
      {
        action: 'auth.password_reset',
        resourceType: 'user',
        resourceId: reset.userId,
        actorId: reset.userId,
        requestId: ctx.requestId,
      },
      tx,
    );
  });
}
