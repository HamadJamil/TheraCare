import { prisma } from './config/database';
import { logger } from './config/logger';
import { startJobs } from './jobs/scheduler';
import { runRetention } from './jobs/retention';
import { dispatchDue, scheduleReminders } from './modules/notifications/notifications.service';

const MINUTE = 60_000;

const stop = startJobs([
  { name: 'schedule-reminders', everyMs: 15 * MINUTE, run: () => scheduleReminders() },
  { name: 'dispatch-reminders', everyMs: MINUTE, run: () => dispatchDue() },
  { name: 'retention', everyMs: 60 * MINUTE, run: () => runRetention() },
]);
logger.info('TheraCare worker started');

const shutdown = async () => {
  stop();
  await prisma.$disconnect();
  process.exit(0);
};
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);
