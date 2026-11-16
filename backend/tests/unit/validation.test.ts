import { z } from 'zod';
import { AppError } from '../../src/common/errors';
import { parse } from '../../src/common/validation';

describe('parse', () => {
  const schema = z.object({ age: z.number().min(18, 'Too young.') }).strict();

  it('returns typed data for valid input', () => {
    expect(parse(schema, { age: 30 })).toEqual({ age: 30 });
  });

  it('throws field-level validation errors', () => {
    expect.assertions(2);
    try {
      parse(schema, { age: 3 });
    } catch (err) {
      expect(err).toBeInstanceOf(AppError);
      expect((err as AppError).fields).toEqual({ age: 'Too young.' });
    }
  });

  it('rejects unknown fields', () => {
    expect(() => parse(schema, { age: 30, admin: true })).toThrow(AppError);
  });
});
