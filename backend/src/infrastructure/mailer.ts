import nodemailer from 'nodemailer';
import { env, isTest } from '../config/env';
import { logger } from '../config/logger';

export type Mail = { to: string; subject: string; text: string };

/** In tests, mails are captured here instead of being sent. */
export const testOutbox: Mail[] = [];

const transport =
  env.SMTP_HOST && !isTest
    ? nodemailer.createTransport({ host: env.SMTP_HOST, port: env.SMTP_PORT ?? 25 })
    : null;

/** Mail delivery failures never block the calling workflow; they are logged without content. */
export async function sendMail(mail: Mail): Promise<void> {
  if (isTest || !transport) {
    testOutbox.push(mail);
    return;
  }
  try {
    await transport.sendMail({ from: env.MAIL_FROM, ...mail });
  } catch (err) {
    logger.warn({ err: (err as Error).message }, 'mail delivery failed');
  }
}
