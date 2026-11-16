import type { RouteModule } from './app';
import { auditRouter } from './modules/audit/audit.routes';

/** Single registry of feature modules mounted under /api/v1. */
export const routeModules: RouteModule[] = [{ path: '', router: auditRouter }];
