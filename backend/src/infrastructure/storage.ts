import { createCipheriv, createDecipheriv, randomBytes, randomUUID } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { env } from '../config/env';

const KEY = Buffer.from(env.FILE_ENCRYPTION_KEY, 'hex');
const root = path.resolve(env.STORAGE_DIR);

/**
 * Minimal protected object storage: files are encrypted with AES-256-GCM and
 * stored under random keys. Swap for a managed object store in production.
 */
export async function putObject(content: Buffer): Promise<string> {
  const key = randomUUID();
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', KEY, iv);
  const encrypted = Buffer.concat([cipher.update(content), cipher.final()]);
  await mkdir(root, { recursive: true });
  await writeFile(path.join(root, key), Buffer.concat([iv, cipher.getAuthTag(), encrypted]));
  return key;
}

export async function getObject(key: string): Promise<Buffer> {
  if (!/^[0-9a-f-]{36}$/.test(key)) throw new Error('invalid storage key');
  const data = await readFile(path.join(root, key));
  const decipher = createDecipheriv('aes-256-gcm', KEY, data.subarray(0, 12));
  decipher.setAuthTag(data.subarray(12, 28));
  return Buffer.concat([decipher.update(data.subarray(28)), decipher.final()]);
}
