import { z } from 'zod';

const isTimeZone = (tz: string) => {
  try {
    new Intl.DateTimeFormat('en', { timeZone: tz });
    return true;
  } catch {
    return false;
  }
};

const clock = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Use the format HH:MM.');

export const updateProfileSchema = z
  .object({
    firstName: z.string().trim().min(1).max(80),
    lastName: z.string().trim().min(1).max(80),
    dateOfBirth: z.coerce
      .date()
      .refine((d) => d < new Date() && d.getUTCFullYear() > 1900, 'Enter a valid date of birth.')
      .nullable(),
    preferredLanguage: z.enum(['de', 'en']),
    timezone: z.string().refine(isTimeZone, 'Choose a valid time zone.'),
  })
  .partial()
  .strict();

export const updatePreferencesSchema = z
  .object({
    textScale: z.number().min(1).max(2),
    highContrast: z.boolean(),
    reducedMotion: z.boolean(),
    remindersEnabled: z.boolean(),
    reminderTime: clock,
    quietHoursStart: clock,
    quietHoursEnd: clock,
  })
  .partial()
  .strict();

export const emailChangeSchema = z
  .object({
    newEmail: z.string().trim().toLowerCase().email('Enter a valid email address.').max(254),
    password: z.string().min(1).max(128),
  })
  .strict();

export const emailConfirmSchema = z
  .object({ code: z.string().regex(/^\d{6}$/, 'Enter the 6-digit code.') })
  .strict();

export const closeAccountSchema = z
  .object({
    password: z.string().min(1).max(128),
    confirm: z.literal(true, {
      errorMap: () => ({ message: 'Please confirm that you want to close your account.' }),
    }),
  })
  .strict();
