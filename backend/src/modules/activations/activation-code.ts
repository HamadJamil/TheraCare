import { HUMAN_ALPHABET, hmac, normaliseCode, randomCode } from '../../common/crypto';
import { env } from '../../config/env';

/** Codes are stored only as a peppered hash of their normalised form. */
export const hashActivationCode = (code: string) =>
  hmac(normaliseCode(code), env.ACTIVATION_CODE_PEPPER);

/** 12-character high-entropy demo code, displayed as XXXX-XXXX-XXXX. */
export function generateActivationCode(): string {
  return randomCode(12, HUMAN_ALPHABET).match(/.{4}/g)!.join('-');
}
