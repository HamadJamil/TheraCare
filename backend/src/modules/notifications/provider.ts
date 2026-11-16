import { randomUUID } from 'node:crypto';
import { logger } from '../../config/logger';

export type PushMessage = { userId: string; title: string; body: string };

/** Delivery abstraction (DIP): swap for FCM/APNs without touching scheduling logic. */
export interface NotificationProvider {
  send(message: PushMessage): Promise<{ providerRef: string }>;
}

/** Development provider: logs only the user reference, never the message content. */
export const consoleProvider: NotificationProvider = {
  async send(message) {
    const providerRef = randomUUID();
    logger.info({ userId: message.userId, providerRef }, 'reminder delivered (console provider)');
    return { providerRef };
  },
};

/**
 * Lock-screen safe wording: no diagnosis, symptom or treatment category.
 */
export const REMINDER_TEXT = {
  de: { title: 'TheraCare', body: 'Sie haben heute eine neue Aufgabe.' },
  en: { title: 'TheraCare', body: 'You have a new task for today.' },
} as const;
