export type FieldErrors = Record<string, string>;

/** Domain error with a stable machine-readable code and a plain-language message. */
export class AppError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly fields?: FieldErrors,
  ) {
    super(message);
  }
}

export const Errors = {
  validation: (fields?: FieldErrors) =>
    new AppError(400, 'VALIDATION_ERROR', 'Please check the information you entered.', fields),
  unauthenticated: () => new AppError(401, 'UNAUTHENTICATED', 'Please sign in to continue.'),
  invalidCredentials: () =>
    new AppError(401, 'INVALID_CREDENTIALS', 'The email address or password is not correct.'),
  forbidden: (message = 'You do not have permission to do this.') =>
    new AppError(403, 'FORBIDDEN', message),
  notFound: (what = 'The requested item') =>
    new AppError(404, 'NOT_FOUND', `${what} was not found.`),
  conflict: (code: string, message: string) => new AppError(409, code, message),
  precondition: (code: string, message: string) => new AppError(412, code, message),
  tooManyRequests: () =>
    new AppError(
      429,
      'RATE_LIMITED',
      'Too many attempts. Please wait a few minutes and try again.',
    ),
};
