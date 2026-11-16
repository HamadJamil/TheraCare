// Test environment: isolated database, no Redis, deterministic secrets.
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL =
  process.env.TEST_DATABASE_URL ?? 'postgresql://theracare:theracare@localhost:5433/theracare_test';
process.env.REDIS_URL = '';
process.env.JWT_ACCESS_SECRET = 'test-access-secret-test-access-secret-0000';
process.env.ACTIVATION_CODE_PEPPER = 'test-activation-pepper';
process.env.TOKEN_PEPPER = 'test-token-pepper-0000';
process.env.RATE_LIMIT_AUTH_MAX = '1000';
process.env.RATE_LIMIT_ACTIVATION_MAX = '1000';
process.env.STORAGE_DIR = './storage-test';
process.env.FILE_ENCRYPTION_KEY = '1'.repeat(64);
