import { nextStatus } from '../../src/modules/content/lifecycle';

describe('content lifecycle', () => {
  it('follows draft → review → approved → published → retired', () => {
    expect(nextStatus('SUBMITTED', 'DRAFT', 'CONTENT_AUTHOR')).toBe('IN_REVIEW');
    expect(nextStatus('APPROVED', 'IN_REVIEW', 'CLINICAL_REVIEWER')).toBe('APPROVED');
    expect(nextStatus('PUBLISHED', 'APPROVED', 'ADMIN')).toBe('PUBLISHED');
    expect(nextStatus('RETIRED', 'PUBLISHED', 'ADMIN')).toBe('RETIRED');
  });

  it('separates roles', () => {
    expect(nextStatus('APPROVED', 'IN_REVIEW', 'CONTENT_AUTHOR')).toBe('FORBIDDEN');
    expect(nextStatus('PUBLISHED', 'APPROVED', 'CLINICAL_REVIEWER')).toBe('FORBIDDEN');
  });

  it('prevents skipping review', () => {
    expect(nextStatus('PUBLISHED', 'DRAFT', 'ADMIN')).toBe('INVALID');
    expect(nextStatus('APPROVED', 'DRAFT', 'CLINICAL_REVIEWER')).toBe('INVALID');
  });
});
