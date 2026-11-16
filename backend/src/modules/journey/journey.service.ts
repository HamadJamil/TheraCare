import type { JourneyState } from '@prisma/client';
import { prisma, type Tx } from '../../config/database';
import { Errors } from '../../common/errors';

/** Forward order of the patient journey (ACCOUNT_CLOSED is terminal and handled separately). */
export const JOURNEY_ORDER: JourneyState[] = [
  'ACCOUNT_PENDING_VERIFICATION',
  'ENTITLEMENT_PENDING',
  'ENTITLEMENT_ACTIVE',
  'PRIVACY_COMPLETE',
  'ONBOARDING_IN_PROGRESS',
  'BASELINE_ASSESSMENT_COMPLETE',
  'TREATMENT_ACTIVE',
  'FINAL_ASSESSMENT',
  'TREATMENT_COMPLETED',
];

/** What the client should show next for each state. */
const NEXT_STEP: Record<JourneyState, string> = {
  ACCOUNT_PENDING_VERIFICATION: 'VERIFY_EMAIL',
  ENTITLEMENT_PENDING: 'ENTER_ACTIVATION_CODE',
  ENTITLEMENT_ACTIVE: 'REVIEW_PRIVACY',
  PRIVACY_COMPLETE: 'START_ONBOARDING',
  ONBOARDING_IN_PROGRESS: 'COMPLETE_BASELINE_ASSESSMENT',
  BASELINE_ASSESSMENT_COMPLETE: 'START_TREATMENT',
  TREATMENT_ACTIVE: 'TODAY',
  FINAL_ASSESSMENT: 'COMPLETE_FINAL_ASSESSMENT',
  TREATMENT_COMPLETED: 'VIEW_REPORT',
  ACCOUNT_CLOSED: 'NONE',
};

export const rank = (state: JourneyState) => JOURNEY_ORDER.indexOf(state);

/** Moves the journey forward; never backwards, never out of ACCOUNT_CLOSED. */
export async function advanceJourney(userId: string, to: JourneyState, tx: Tx = prisma) {
  const user = await tx.user.findUniqueOrThrow({ where: { id: userId } });
  if (user.journeyState === 'ACCOUNT_CLOSED') throw Errors.forbidden('This account is closed.');
  if (rank(to) <= rank(user.journeyState)) return user.journeyState;
  await tx.user.update({ where: { id: userId }, data: { journeyState: to } });
  return to;
}

export async function getJourney(userId: string) {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: userId } });
  return { state: user.journeyState, nextStep: NEXT_STEP[user.journeyState] };
}
