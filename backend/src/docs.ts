import { readFileSync } from 'node:fs';
import path from 'node:path';
import { Router } from 'express';
import swaggerUi from 'swagger-ui-express';
import { parse } from 'yaml';

/** Serves the OpenAPI contract as JSON and as Swagger UI at /api/docs. */
export function docsRouter() {
  const spec = parse(readFileSync(path.join(__dirname, '..', 'openapi', 'openapi.yaml'), 'utf8'));
  const router = Router();
  router.get('/openapi.json', (_req, res) => {
    res.json(spec);
  });
  router.use('/', swaggerUi.serve, swaggerUi.setup(spec));
  return router;
}
