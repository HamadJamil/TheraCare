import 'dotenv/config';
import { z } from 'zod';

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().url(),
  REDIS_URL: z.string().optional(),
  JWT_ACCESS_SECRET: z.string().min(32),
  ACTIVATION_CODE_PEPPER: z.string().min(16),
  TOKEN_PEPPER: z.string().min(16),
  ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(900),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().int().positive().default(30),
  CORS_ORIGINS: z.string().default(''),
  SMTP_HOST: z.string().optional(),
  SMTP_PORT: z.coerce.number().int().positive().optional(),
  MAIL_FROM: z.string().default('TheraCare <no-reply@theracare.local>'),
  RATE_LIMIT_WINDOW_SECONDS: z.coerce.number().int().positive().default(900),
  RATE_LIMIT_AUTH_MAX: z.coerce.number().int().positive().default(20),
  RATE_LIMIT_ACTIVATION_MAX: z.coerce.number().int().positive().default(10),
  STORAGE_DIR: z.string().default('./storage'),
  /** 64 hex chars (32 bytes) used to encrypt generated files at rest. */
  FILE_ENCRYPTION_KEY: z.string().regex(/^[0-9a-f]{64}$/i, 'must be 64 hex characters'),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  // Fail fast: the service must never start with an invalid configuration.
  throw new Error(`Invalid environment configuration: ${parsed.error.message}`);
}

export const env = parsed.data;
export const isTest = env.NODE_ENV === 'test';
