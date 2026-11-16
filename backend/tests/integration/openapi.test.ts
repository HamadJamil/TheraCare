import { api } from '../helpers/app';
import { routeModules } from '../../src/routes';

type Layer = { route?: { path: string; methods: Record<string, boolean> } };

/** Every mounted route must be documented in the OpenAPI contract. */
describe('OpenAPI contract', () => {
  it('documents every route', async () => {
    const res = await api().get('/api/docs/openapi.json').expect(200);
    const documented = new Set<string>();
    for (const [p, ops] of Object.entries(res.body.paths as Record<string, object>)) {
      for (const method of Object.keys(ops)) documented.add(`${method} ${p}`);
    }
    const missing: string[] = [];
    let checked = 0;
    for (const { path: base, router } of routeModules) {
      for (const layer of (router as unknown as { stack: Layer[] }).stack) {
        if (!layer.route) continue;
        const full =
          `${base}${layer.route.path}`.replace(/\/$/, '').replace(/:(\w+)/g, '{$1}') || '/';
        for (const method of Object.keys(layer.route.methods)) {
          checked++;
          if (!documented.has(`${method} ${full}`)) missing.push(`${method.toUpperCase()} ${full}`);
        }
      }
    }
    expect(checked).toBeGreaterThan(60);
    expect(missing).toEqual([]);
  });

  it('serves Swagger UI', async () => {
    await api().get('/api/docs/').expect(200);
  });
});
