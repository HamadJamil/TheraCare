import { z } from 'zod';

const email = z.string().trim().toLowerCase().email('Enter a valid email address.').max(254);
const password = z
  .string()
  .min(10, 'Use at least 10 characters.')
  .max(128, 'Use at most 128 characters.');

export const registerSchema = z
  .object({
    email,
    password,
    firstName: z.string().trim().min(1, 'Enter your first name.').max(80),
    lastName: z.string().trim().min(1, 'Enter your last name.').max(80),
    language: z.enum(['de', 'en']).default('de'),
  })
  .strict();

export const loginSchema = z
  .object({
    email,
    password: z.string().min(1).max(128),
    deviceLabel: z.string().max(80).optional(),
  })
  .strict();

export const verifyEmailSchema = z
  .object({
    email,
    code: z.string().regex(/^\d{6}$/, 'Enter the 6-digit code.'),
    deviceLabel: z.string().max(80).optional(),
  })
  .strict();

export const emailOnlySchema = z.object({ email }).strict();
export const refreshSchema = z.object({ refreshToken: z.string().min(20).max(200) }).strict();
export const resetPasswordSchema = z
  .object({ token: z.string().trim().min(8).max(64), password })
  .strict();
export const sessionIdParams = z.object({ id: z.string().uuid() });
