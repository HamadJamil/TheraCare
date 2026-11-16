import { createHmac, randomBytes, randomInt, timingSafeEqual } from 'node:crypto';
import { env } from '../config/env';

/** Keyed hash used for codes and tokens that must be looked up but never stored raw. */
export function hmac(value: string, pepper = env.TOKEN_PEPPER): string {
  return createHmac('sha256', pepper).update(value).digest('hex');
}

export function randomToken(bytes = 32): string {
  return randomBytes(bytes).toString('base64url');
}

/** Uniformly random code over the given alphabet. */
export function randomCode(length: number, alphabet: string): string {
  return Array.from({ length }, () => alphabet[randomInt(0, alphabet.length)]).join('');
}

/** Unambiguous characters for codes people type by hand (no 0/O, 1/I). */
export const HUMAN_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

export const numericCode = (length = 6) => randomCode(length, '0123456789');

/** Uppercases and strips separators so "ab12-cd34" and "AB12CD34" match. */
export const normaliseCode = (code: string) => code.toUpperCase().replace(/[^A-Z0-9]/g, '');

export function safeEqual(a: string, b: string): boolean {
  const left = Buffer.from(a);
  const right = Buffer.from(b);
  return left.length === right.length && timingSafeEqual(left, right);
}
