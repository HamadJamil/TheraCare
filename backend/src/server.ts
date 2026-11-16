import { createApp } from './app';
import { env } from './config/env';
import { logger } from './config/logger';
import { prisma } from './config/database';
import { redis } from './config/redis';
import { routeModules } from './routes';

async function main() {
  // Redis connects lazily on first command (the rate-limit store loads its script at startup).
  const app = createApp(routeModules);
  const server = app.listen(env.PORT, () => logger.info(`TheraCare API listening on :${env.PORT}`));

  const shutdown = () => {
    server.close(async () => {
      await prisma.$disconnect();
      redis?.disconnect();
      process.exit(0);
    });
  };
  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

main().catch((err) => {
  logger.fatal({ err }, 'failed to start');
  process.exit(1);
});
