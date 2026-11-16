import {
  HUMAN_ALPHABET,
  hmac,
  normaliseCode,
  numericCode,
  randomCode,
  safeEqual,
} from '../../src/common/crypto';

describe('crypto helpers', () => {
  it('produces numeric codes of the requested length', () => {
    expect(numericCode(6)).toMatch(/^\d{6}$/);
  });

  it('only uses characters from the given alphabet', () => {
    const code = randomCode(200, HUMAN_ALPHABET);
    expect([...code].every((c) => HUMAN_ALPHABET.includes(c))).toBe(true);
    expect(code).not.toMatch(/[01IO]/);
  });

  it('normalises human-typed codes', () => {
    expect(normaliseCode(' ab12-cd34 ef ')).toBe('AB12CD34EF');
  });

  it('hashes deterministically per pepper', () => {
    expect(hmac('x', 'pepper-one-123456')).toBe(hmac('x', 'pepper-one-123456'));
    expect(hmac('x', 'pepper-one-123456')).not.toBe(hmac('x', 'pepper-two-123456'));
  });

  it('compares safely', () => {
    expect(safeEqual('abc', 'abc')).toBe(true);
    expect(safeEqual('abc', 'abd')).toBe(false);
    expect(safeEqual('abc', 'abcd')).toBe(false);
  });
});
