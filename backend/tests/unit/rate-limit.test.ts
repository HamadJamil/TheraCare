import express from 'express';
import request from 'supertest';
import { limiter } from '../../src/middleware/rate-limit';
import { errorHandler } from '../../src/middleware/error-handler';

describe('limiter', () => {
  it('throttles after the configured number of requests', async () => {
    const app = express();
    app.get('/x', limiter('unit-test', 2), (_req, res) => {
      res.json({ ok: true });
    });
    app.use(errorHandler);

    await request(app).get('/x').expect(200);
    await request(app).get('/x').expect(200);
    const res = await request(app).get('/x').expect(429);
    expect(res.body.error.code).toBe('RATE_LIMITED');
  });
});
