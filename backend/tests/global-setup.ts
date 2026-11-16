import { execSync } from 'node:child_process';

/** Applies pending migrations to the test database once per run (tables are emptied per test file). */
export default function globalSetup() {
  const url =
    process.env.TEST_DATABASE_URL ??
    'postgresql://theracare:theracare@localhost:5433/theracare_test';
  execSync('npx prisma migrate deploy', {
    env: { ...process.env, DATABASE_URL: url },
    stdio: 'ignore',
  });
}
