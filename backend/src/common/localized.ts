/** Content stored as { de, en } JSON. German is the primary language. */
export type Localized = { de: string; en: string };
export type Locale = 'de' | 'en';

export function pickLocale(value: unknown, locale: Locale): string {
  const text = value as Partial<Localized> | null;
  return text?.[locale] ?? text?.de ?? '';
}
