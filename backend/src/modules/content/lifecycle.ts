import type { ContentStatus, ReviewAction, Role } from '@prisma/client';

type Transition = { from: ContentStatus[]; to: ContentStatus; roles: Role[] };

/**
 * Release workflow for medical content. Authors, clinical reviewers and release
 * managers (admins) are separate roles; published content is immutable.
 */
export const TRANSITIONS: Record<Exclude<ReviewAction, never>, Transition> = {
  SUBMITTED: { from: ['DRAFT', 'REJECTED'], to: 'IN_REVIEW', roles: ['CONTENT_AUTHOR'] },
  APPROVED: { from: ['IN_REVIEW'], to: 'APPROVED', roles: ['CLINICAL_REVIEWER'] },
  REJECTED: { from: ['IN_REVIEW'], to: 'REJECTED', roles: ['CLINICAL_REVIEWER'] },
  PUBLISHED: { from: ['APPROVED'], to: 'PUBLISHED', roles: ['ADMIN'] },
  RETIRED: { from: ['PUBLISHED'], to: 'RETIRED', roles: ['ADMIN'] },
};

export const EDITABLE: ContentStatus[] = ['DRAFT', 'REJECTED'];

export function nextStatus(
  action: ReviewAction,
  current: ContentStatus,
  role: Role,
): ContentStatus | 'FORBIDDEN' | 'INVALID' {
  const t = TRANSITIONS[action];
  if (!t.roles.includes(role)) return 'FORBIDDEN';
  if (!t.from.includes(current)) return 'INVALID';
  return t.to;
}
