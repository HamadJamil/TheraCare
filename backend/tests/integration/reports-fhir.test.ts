import { randomUUID } from 'node:crypto';
import type { Response } from 'superagent';
import { api } from '../helpers/app';
import { prisma, resetDb } from '../helpers/db';
import { activateAndConsent } from '../helpers/fixtures';
import { backCheckAnswers, questionnaireByKey } from '../helpers/questionnaires';
import { signUp, type TestUser } from '../helpers/users';
import { drainReportJobs } from '../../src/modules/reports/reports.service';
import { validateBundle } from '../../src/modules/fhir/fhir.validation';

let user: TestUser;

beforeEach(async () => {
  await resetDb();
  user = await signUp();
  await activateAndConsent(user);
  const baseline = await questionnaireByKey(user, 'back-check-baseline');
  await post(`/questionnaires/${baseline!.id}/responses`, {
    answers: backCheckAnswers(6, 2),
  }).expect(201);
  await post('/observations', {
    clientId: randomUUID(),
    kind: 'PAIN_INTENSITY',
    value: 5,
    note: 'after the walk',
    effectiveAt: new Date().toISOString(),
  }).expect(201);
});
afterAll(() => prisma.$disconnect());

function post(path: string, body: object = {}, as = user) {
  return api().post(`/api/v1${path}`).set('authorization', as.bearer).send(body);
}
const get = (path: string, as = user) =>
  api().get(`/api/v1${path}`).set('authorization', as.bearer);
const binary = (res: Response, cb: (err: Error | null, body: Buffer) => void) => {
  const chunks: Buffer[] = [];
  res.on('data', (c: Buffer) => chunks.push(c));
  res.on('end', () => cb(null, Buffer.concat(chunks)));
};

describe('treatment summary PDF', () => {
  it('generates asynchronously and downloads a PDF', async () => {
    const created = await post('/reports?lang=en', { kind: 'TREATMENT_SUMMARY_PDF' }).expect(201);
    expect(created.body.data.status).toBe('PENDING');
    await drainReportJobs();

    const status = await get(`/reports/${created.body.data.id}`).expect(200);
    expect(status.body.data.status).toBe('READY');
    const file = await get(`/reports/${created.body.data.id}/download`)
      .buffer(true)
      .parse(binary)
      .expect(200);
    expect(file.headers['content-type']).toBe('application/pdf');
    expect((file.body as Buffer).subarray(0, 5).toString()).toBe('%PDF-');
    expect(await prisma.auditEvent.count({ where: { action: 'export.downloaded' } })).toBe(1);
  });

  it('stores generated files encrypted', async () => {
    const created = await post('/reports', { kind: 'TREATMENT_SUMMARY_PDF' }).expect(201);
    await drainReportJobs();
    const report = await prisma.report.findUniqueOrThrow({ where: { id: created.body.data.id } });
    const raw = await import('node:fs/promises').then((fs) =>
      fs.readFile(`./storage-test/${report.storageKey}`),
    );
    expect(raw.subarray(0, 5).toString()).not.toBe('%PDF-');
  });

  it('is only available to its owner', async () => {
    const created = await post('/reports', { kind: 'TREATMENT_SUMMARY_PDF' }).expect(201);
    await drainReportJobs();
    const other = await signUp();
    await activateAndConsent(other);
    await get(`/reports/${created.body.data.id}/download`, other).expect(404);
    expect((await get('/reports', other).expect(200)).body.data).toHaveLength(0);
  });

  it('retries failed generation safely', async () => {
    const created = await post('/reports', { kind: 'TREATMENT_SUMMARY_PDF' }).expect(201);
    await drainReportJobs();
    await prisma.report.update({
      where: { id: created.body.data.id },
      data: { status: 'FAILED', storageKey: null },
    });
    await get(`/reports/${created.body.data.id}/download`).expect(409);
    await post(`/reports/${created.body.data.id}/export`).expect(200);
    await drainReportJobs();
    expect((await get(`/reports/${created.body.data.id}`).expect(200)).body.data.status).toBe(
      'READY',
    );
  });
});

describe('FHIR export', () => {
  it('publishes a capability statement', async () => {
    const res = await api().get('/api/v1/fhir/metadata').expect(200);
    expect(res.body).toMatchObject({ resourceType: 'CapabilityStatement', fhirVersion: '4.0.1' });
  });

  it('exports a valid bundle with only the patient’s own data', async () => {
    const other = await signUp();
    await activateAndConsent(other);
    await post(
      '/observations',
      { clientId: randomUUID(), kind: 'MOOD', value: 2, effectiveAt: new Date().toISOString() },
      other,
    ).expect(201);

    const created = await post('/fhir/exports').expect(201);
    await drainReportJobs();
    expect((await get(`/fhir/exports/${created.body.data.id}`).expect(200)).body.data.status).toBe(
      'READY',
    );
    const file = await get(`/fhir/exports/${created.body.data.id}/download`)
      .buffer(true)
      .parse(binary)
      .expect(200);
    expect(file.headers['content-type']).toContain('application/fhir+json');
    const bundle = JSON.parse((file.body as Buffer).toString());

    expect(validateBundle(bundle)).toEqual([]);
    const types = bundle.entry.map(
      (e: { resource: { resourceType: string } }) => e.resource.resourceType,
    );
    expect(types).toEqual(
      expect.arrayContaining([
        'Patient',
        'CarePlan',
        'Observation',
        'Questionnaire',
        'QuestionnaireResponse',
      ]),
    );
    const observations = bundle.entry.filter(
      (e: { resource: { resourceType: string } }) => e.resource.resourceType === 'Observation',
    );
    expect(observations).toHaveLength(1);
    expect(observations[0].resource.code.coding[0]).toMatchObject({
      system: 'http://loinc.org',
      code: '72514-3',
    });
    expect(observations[0].resource.valueQuantity).toMatchObject({
      value: 5,
      system: 'http://unitsofmeasure.org',
    });
    const qr = bundle.entry.find(
      (e: { resource: { resourceType: string } }) =>
        e.resource.resourceType === 'QuestionnaireResponse',
    );
    expect(qr.resource.questionnaire).toMatch(/back-check-baseline\|1$/);

    const patientId = (await prisma.user.findUniqueOrThrow({ where: { email: user.email } })).id;
    expect(JSON.stringify(bundle)).not.toContain(
      (await prisma.user.findUniqueOrThrow({ where: { email: other.email } })).id,
    );
    expect(bundle.entry[0].resource.id).toBe(patientId);
    expect(await prisma.auditEvent.count({ where: { action: 'export.requested' } })).toBe(1);
  });

  it('detects broken references and profile violations', () => {
    const issues = validateBundle({
      resourceType: 'Bundle',
      type: 'collection',
      timestamp: new Date().toISOString(),
      meta: { profile: [] },
      entry: [
        {
          fullUrl: 'urn:uuid:x',
          resource: {
            resourceType: 'Observation',
            id: randomUUID(),
            status: 'final',
            code: { coding: [] },
            subject: { reference: `Patient/${randomUUID()}` },
            effectiveDateTime: 'yesterday',
          },
        },
      ],
    });
    expect(issues.map((i) => i.message).join(' ')).toMatch(/Unresolved reference/);
    expect(issues.some((i) => i.resource === 'Bundle')).toBe(true);
    expect(issues.length).toBeGreaterThan(3);
  });
});
