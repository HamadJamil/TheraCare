import request from 'supertest';
import { createApp } from '../../src/app';
import { routeModules } from '../../src/routes';

export const app = createApp(routeModules);
export const api = () => request(app);
