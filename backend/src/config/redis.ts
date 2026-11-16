import Redis from 'ioredis';
import { env } from './env';

/** Redis is optional: without REDIS_URL the API falls back to in-memory rate limiting. */
export const redis = env.REDIS_URL
  ? new Redis(env.REDIS_URL, { lazyConnect: true, maxRetriesPerRequest: 2 })
  : null;
