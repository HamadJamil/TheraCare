import type { RouteModule } from './app';
import { auditRouter } from './modules/audit/audit.routes';
import { authRouter } from './modules/auth/auth.routes';

/** Single registry of feature modules mounted under /api/v1. */
export const routeModules: RouteModule[] = [
  { path: '/auth', router: authRouter },
  { path: '', router: auditRouter },
];
