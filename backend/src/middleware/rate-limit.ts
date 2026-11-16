import rateLimit, { type Store } from 'express-rate-limit';
import { RedisStore, type RedisReply } from 'rate-limit-redis';
import { Errors } from '../common/errors';
import { env } from '../config/env';
import { redis } from '../config/redis';

function store(prefix: string): Store | undefined {
  if (!redis) return undefined;
  return new RedisStore({
    prefix: `rl:${prefix}:`,
    sendCommand: (command: string, ...args: string[]) =>
      redis!.call(command, ...args) as Promise<RedisReply>,
  });
}

/** Creates a throttle for abuse-sensitive endpoints (login, recovery, activation). */
export function limiter(name: string, max: number) {
  return rateLimit({
    windowMs: env.RATE_LIMIT_WINDOW_SECONDS * 1000,
    limit: max,
    standardHeaders: 'draft-7',
    legacyHeaders: false,
    store: store(name),
    handler: () => {
      throw Errors.tooManyRequests();
    },
  });
}

export const authLimiter = limiter('auth', env.RATE_LIMIT_AUTH_MAX);
export const activationLimiter = limiter('activation', env.RATE_LIMIT_ACTIVATION_MAX);
