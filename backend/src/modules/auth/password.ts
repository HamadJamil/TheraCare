import argon2 from 'argon2';
import { isTest } from '../../config/env';

// OWASP-recommended Argon2id baseline; reduced cost only for the automated test suite.
const options = isTest
  ? { type: argon2.argon2id, memoryCost: 1024, timeCost: 1 }
  : { type: argon2.argon2id, memoryCost: 19456, timeCost: 2, parallelism: 1 };

export const hashPassword = (password: string) => argon2.hash(password, options);

export async function verifyPassword(hash: string, password: string): Promise<boolean> {
  try {
    return await argon2.verify(hash, password);
  } catch {
    return false;
  }
}

/** Used for unknown accounts so timing does not reveal whether an email exists. */
export const DUMMY_HASH_PROMISE = hashPassword('timing-equalisation-only');
