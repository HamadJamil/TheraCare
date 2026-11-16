import pino from 'pino';
import { env } from './env';

/**
 * Structured logger. Sensitive fields are redacted: logs must never contain
 * credentials, tokens, activation codes or health data.
 */
export const logger = pino({
  level: env.NODE_ENV === 'test' ? 'silent' : 'info',
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.cookie',
      '*.password',
      '*.code',
      '*.token',
      '*.refreshToken',
      '*.note',
      '*.value',
    ],
    censor: '[redacted]',
  },
  transport: env.NODE_ENV === 'development' ? { target: 'pino-pretty' } : undefined,
});
