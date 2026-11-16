/* Demo seed: synthetic data only. Prints new activation codes once — they are stored hashed. */
import { randomUUID } from 'node:crypto';
import { PrismaClient, type Role } from '@prisma/client';
import { seedReference } from './seed/reference';
import { addDays } from '../src/common/dates';
import {
  generateActivationCode,
  hashActivationCode,
} from '../src/modules/activations/activation-code';
import { hashPassword } from '../src/modules/auth/password';
import { assignTreatment } from '../src/modules/treatments/treatments.service';

const prisma = new PrismaClient();
const DEMO_PASSWORD = 'TheraCare-Demo-2026';

async function upsertUser(email: string, role: Role, firstName: string, lastName: string) {
  const passwordHash = await hashPassword(DEMO_PASSWORD);
  return prisma.user.upsert({
    where: { email },
    update: {},
    create: {
      email,
      passwordHash,
      role,
      status: 'ACTIVE',
      journeyState: 'ENTITLEMENT_PENDING',
      profile: { create: { firstName, lastName } },
      preferences: { create: {} },
    },
  });
}

async function createCodes(productId: string, count: number) {
  const codes: string[] = [];
  for (let i = 0; i < count; i++) {
    const code = generateActivationCode();
    await prisma.activation.create({
      data: { codeHash: hashActivationCode(code), productId, expiresAt: addDays(new Date(), 180) },
    });
    codes.push(code);
  }
  return codes;
}

/** A patient mid-way through treatment, with three weeks of synthetic history for the dashboard. */
async function seedActivePatient(productId: string) {
  const user = await upsertUser('demo.active@theracare.local', 'PATIENT', 'Helga', 'Beispiel');
  if (await prisma.patientTreatment.findFirst({ where: { userId: user.id } })) return;

  const [code] = await createCodes(productId, 1);
  const activation = await prisma.activation.update({
    where: { codeHash: hashActivationCode(code) },
    data: { status: 'REDEEMED', userId: user.id, redeemedAt: addDays(new Date(), -21) },
  });
  await prisma.entitlement.create({
    data: {
      userId: user.id,
      productId,
      activationId: activation.id,
      startsAt: addDays(new Date(), -21),
      endsAt: addDays(new Date(), 69),
    },
  });
  for (const type of await prisma.consentType.findMany({ where: { active: true } })) {
    const consent = await prisma.consent.create({
      data: {
        userId: user.id,
        consentTypeId: type.id,
        policyVersion: type.policyVersion,
        decision: 'GRANTED',
      },
    });
    await prisma.consentEvent.create({
      data: {
        consentId: consent.id,
        userId: user.id,
        decision: 'GRANTED',
        policyVersion: type.policyVersion,
        locale: 'de',
      },
    });
  }
  const treatment = await prisma.$transaction((tx) => assignTreatment(user.id, 18, tx));
  await prisma.patientTreatment.update({
    where: { id: treatment.id },
    data: { startedAt: addDays(new Date(), -21), endsAt: addDays(new Date(), 63) },
  });

  const planExercises = await prisma.planExercise.findMany({
    where: { treatmentVersionId: treatment.treatmentVersionId },
  });
  for (let day = 21; day >= 1; day--) {
    const date = addDays(new Date(), -day);
    if (day % 3 !== 0) {
      for (const pe of planExercises) {
        const completedAt = new Date(date.getTime() + 10 * 3_600_000);
        await prisma.exerciseCompletion.create({
          data: {
            userId: user.id,
            clientId: randomUUID(),
            exerciseVersionId: pe.exerciseVersionId,
            startedAt: new Date(completedAt.getTime() - 180_000),
            completedAt,
            durationSeconds: 180,
          },
        });
      }
    }
    await prisma.observation.create({
      data: {
        userId: user.id,
        clientId: randomUUID(),
        kind: 'PAIN_INTENSITY',
        value: Math.max(1, Math.round(7 - (21 - day) / 5)),
        effectiveAt: new Date(date.getTime() + 19 * 3_600_000),
      },
    });
  }
}

async function main() {
  const { product } = await seedReference(prisma);

  await upsertUser('demo@theracare.local', 'PATIENT', 'Erika', 'Mustermann');
  const staff: [string, Role][] = [
    ['author@theracare.local', 'CONTENT_AUTHOR'],
    ['reviewer@theracare.local', 'CLINICAL_REVIEWER'],
    ['admin@theracare.local', 'ADMIN'],
    ['support@theracare.local', 'SUPPORT_AGENT'],
    ['auditor@theracare.local', 'SECURITY_AUDITOR'],
  ];
  for (const [email, role] of staff) await upsertUser(email, role, 'Demo', role);
  await seedActivePatient(product.id);

  const codes = await createCodes(product.id, 5);
  console.log('\nTheraCare demo data ready (synthetic data only).');
  console.log(`Password for all demo accounts: ${DEMO_PASSWORD}`);
  console.log(
    'Accounts: demo@theracare.local (new patient), demo.active@theracare.local (in treatment),',
  );
  console.log(`          ${staff.map(([email]) => email).join(', ')}`);
  console.log('New activation codes (shown once):');
  for (const code of codes) console.log(`  ${code}`);
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
