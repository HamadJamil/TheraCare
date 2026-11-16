import type { RouteModule } from './app';
import { activationsRouter } from './modules/activations/activations.routes';
import { assessmentsRouter } from './modules/assessments/assessments.routes';
import { auditRouter } from './modules/audit/audit.routes';
import { authRouter } from './modules/auth/auth.routes';
import { exercisesRouter } from './modules/exercises/exercises.routes';
import { consentsRouter } from './modules/consents/consents.routes';
import { patientsRouter } from './modules/patients/patients.routes';
import { questionnairesRouter } from './modules/questionnaires/questionnaires.routes';
import { treatmentsRouter } from './modules/treatments/treatments.routes';

/** Single registry of feature modules mounted under /api/v1. */
export const routeModules: RouteModule[] = [
  { path: '/auth', router: authRouter },
  { path: '/patients', router: patientsRouter },
  { path: '/consents', router: consentsRouter },
  { path: '/exercises', router: exercisesRouter },
  { path: '/questionnaires', router: questionnairesRouter },
  { path: '', router: activationsRouter },
  { path: '', router: treatmentsRouter },
  { path: '', router: assessmentsRouter },
  { path: '', router: auditRouter },
];
