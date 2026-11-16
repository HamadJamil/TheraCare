import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { signUp, staff } from '../helpers/users';
import { redact } from '../../src/modules/support/support.service';

beforeEach(resetDb);
afterAll(() => prisma.$disconnect());

describe('support', () => {
  it('serves a public localized FAQ covering the key topics', async () => {
    const res = await api().get('/api/v1/support/faq?lang=en').expect(200);
    const categories = res.body.data.map((f: { category: string }) => f.category);
    expect(categories).toEqual(
      expect.arrayContaining([
        'login',
        'activation',
        'exercises',
        'sync',
        'privacy',
        'accessibility',
      ]),
    );
  });

  it('removes activation codes from tickets', () => {
    expect(redact('My code ABCD-EFGH-JKLM does not work')).toBe('My code [removed] does not work');
  });

  it('lets patients create and list their own tickets', async () => {
    const user = await signUp();
    await api()
      .post('/api/v1/support/tickets')
      .set('authorization', user.bearer)
      .send({
        category: 'activation',
        subject: 'Code problem',
        message: 'The code ab12-cd34-ef56 is rejected.',
      })
      .expect(201);
    const mine = await api()
      .get('/api/v1/support/tickets/me')
      .set('authorization', user.bearer)
      .expect(200);
    expect(mine.body.data).toHaveLength(1);
    const stored = await prisma.supportTicket.findFirstOrThrow();
    expect(stored.message).toBe('The code [removed] is rejected.');
  });

  it('lets support agents see tickets but not health endpoints', async () => {
    const user = await signUp();
    await api()
      .post('/api/v1/support/tickets')
      .set('authorization', user.bearer)
      .send({ category: 'sync', subject: 'Sync', message: 'My entries do not appear.' })
      .expect(201);
    const agent = await staff('SUPPORT_AGENT');
    const list = await api()
      .get('/api/v1/admin/support/tickets')
      .set('authorization', agent.bearer)
      .expect(200);
    expect(list.body.data[0]).toMatchObject({ contactEmail: user.email, status: 'OPEN' });
    expect(Object.keys(list.body.data[0])).not.toContain('observations');

    await api()
      .patch(`/api/v1/admin/support/tickets/${list.body.data[0].id}`)
      .set('authorization', agent.bearer)
      .send({ status: 'RESOLVED', agentNote: 'Asked user to update the app.' })
      .expect(200);
    expect(
      await prisma.auditEvent.count({
        where: { action: 'support.ticket_updated', actorRole: 'SUPPORT_AGENT' },
      }),
    ).toBe(1);

    await api().get('/api/v1/observations').set('authorization', agent.bearer).expect(412);
    await api().get('/api/v1/admin/audit-events').set('authorization', agent.bearer).expect(403);
  });

  it('keeps patients out of the staff queue', async () => {
    const user = await signUp();
    await api().get('/api/v1/admin/support/tickets').set('authorization', user.bearer).expect(403);
  });

  it('lets the security auditor read audit events', async () => {
    await signUp();
    const auditor = await staff('SECURITY_AUDITOR');
    const res = await api()
      .get('/api/v1/admin/audit-events?action=auth.email_verified')
      .set('authorization', auditor.bearer)
      .expect(200);
    expect(res.body.data.items).toHaveLength(1);
    expect(res.body.data.items[0]).toMatchObject({
      action: 'auth.email_verified',
      outcome: 'SUCCESS',
    });
  });
});
