import express, { type Express, type Router } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import pinoHttp from 'pino-http';
import { env } from './config/env';
import { logger } from './config/logger';
import { requestId } from './middleware/request-id';
import { errorHandler, notFoundHandler } from './middleware/error-handler';
import { ok } from './common/http';
import { docsRouter } from './docs';

export type RouteModule = { path: string; router: Router };

/**
 * Builds the Express application. Feature modules are passed in so the app
 * shell stays closed for modification when modules are added (OCP).
 */
export function createApp(modules: RouteModule[]): Express {
  const app = express();
  app.disable('x-powered-by');
  app.set('trust proxy', 1);

  app.use(requestId);
  app.use(helmet());
  app.use(
    cors({
      origin: env.CORS_ORIGINS ? env.CORS_ORIGINS.split(',').map((o) => o.trim()) : false,
    }),
  );
  app.use(express.json({ limit: '200kb' }));
  app.use(
    pinoHttp({
      logger,
      genReqId: (_req, res) => res.getHeader('x-request-id') as string,
      serializers: { req: (req) => ({ method: req.method, url: req.url }) },
    }),
  );

  app.get('/health', (_req, res) => ok(res, { status: 'ok' }));
  app.use('/api/docs', docsRouter());
  for (const { path, router } of modules) app.use(`/api/v1${path}`, router);

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
