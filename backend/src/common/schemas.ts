import { z } from 'zod';

/** Shared request fragments (DRY across modules). */
export const idParams = z.object({ id: z.string().uuid() });
export const clientId = z.string().uuid('A client-generated UUID is required.');
