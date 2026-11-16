import { api } from '../helpers/app';
import { signAccessToken } from '../../src/modules/auth/tokens';

describe('app shell', () => {
  it('reports health with a request id', async () => {
    const res = await api().get('/health').expect(200);
    expect(res.body).toMatchObject({ success: true, data: { status: 'ok' } });
    expect(res.headers['x-request-id']).toBe(res.body.meta.requestId);
  });

  it('returns a standard error for unknown routes', async () => {
    const res = await api().get('/api/v1/does-not-exist').expect(404);
    expect(res.body).toMatchObject({ success: false, error: { code: 'ROUTE_NOT_FOUND' } });
  });

  it('rejects malformed JSON without leaking details', async () => {
    const res = await api()
      .post('/api/v1/anything')
      .set('content-type', 'application/json')
      .send('{"broken":');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('MALFORMED_JSON');
  });

  it('protects staff endpoints by role', async () => {
    await api().get('/api/v1/admin/audit-events').expect(401);
    const patient = signAccessToken('00000000-0000-0000-0000-000000000001', 'PATIENT', 'sid');
    await api()
      .get('/api/v1/admin/audit-events')
      .set('authorization', `Bearer ${patient}`)
      .expect(403);
  });

  it('rejects tampered tokens', async () => {
    const token = signAccessToken('00000000-0000-0000-0000-000000000001', 'ADMIN', 'sid') + 'x';
    await api()
      .get('/api/v1/admin/audit-events')
      .set('authorization', `Bearer ${token}`)
      .expect(401);
  });
});
