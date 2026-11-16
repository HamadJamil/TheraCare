import type { Request } from 'express';
import type { Locale } from './localized';

/** Resolves the response language from `?lang=` or Accept-Language; German by default. */
export function localeOf(req: Request): Locale {
  const query = typeof req.query.lang === 'string' ? req.query.lang : undefined;
  const header = req.header('accept-language')?.slice(0, 2);
  return (query ?? header) === 'en' ? 'en' : 'de';
}
