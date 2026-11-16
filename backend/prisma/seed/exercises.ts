import type { PrismaClient } from '@prisma/client';

/**
 * Demonstration exercise content. In a real product every text here must be
 * written and approved by the responsible clinical team.
 */
const DEMO_NOTE = {
  de: 'Demo-Inhalt: nicht klinisch geprüft.',
  en: 'Demo content: not clinically reviewed.',
};

const STOP_RULE = {
  de: 'Hören Sie sofort auf, wenn der Schmerz stark zunimmt, in die Beine ausstrahlt oder Taubheit auftritt.',
  en: 'Stop immediately if pain increases strongly, spreads into your legs or you feel numbness.',
};

export const EXERCISES = [
  {
    key: 'pelvic-tilt',
    durationSeconds: 120,
    title: { de: 'Becken kippen', en: 'Pelvic tilt' },
    summary: {
      de: 'Sanfte Bewegung für den unteren Rücken im Liegen.',
      en: 'Gentle lower-back movement while lying down.',
    },
    steps: [
      {
        de: 'Legen Sie sich auf den Rücken. Die Knie sind gebeugt.',
        en: 'Lie on your back with your knees bent.',
      },
      {
        de: 'Drücken Sie den unteren Rücken sanft in die Unterlage.',
        en: 'Gently press your lower back into the floor.',
      },
      {
        de: 'Halten Sie 5 Sekunden. Atmen Sie ruhig weiter.',
        en: 'Hold for 5 seconds. Keep breathing calmly.',
      },
      { de: 'Lösen Sie die Spannung. Wiederholen Sie 8-mal.', en: 'Relax. Repeat 8 times.' },
    ],
  },
  {
    key: 'knee-to-chest',
    durationSeconds: 120,
    title: { de: 'Knie zur Brust', en: 'Knee to chest' },
    summary: { de: 'Dehnt den unteren Rücken.', en: 'Stretches the lower back.' },
    steps: [
      { de: 'Legen Sie sich auf den Rücken.', en: 'Lie on your back.' },
      {
        de: 'Ziehen Sie ein Knie mit beiden Händen zur Brust.',
        en: 'Pull one knee towards your chest with both hands.',
      },
      { de: 'Halten Sie 15 Sekunden.', en: 'Hold for 15 seconds.' },
      { de: 'Wechseln Sie das Bein. Je Seite 3-mal.', en: 'Switch legs. 3 times on each side.' },
    ],
  },
  {
    key: 'seated-rotation',
    durationSeconds: 90,
    title: { de: 'Drehung im Sitzen', en: 'Seated rotation' },
    summary: {
      de: 'Mobilisiert die Wirbelsäule auf einem Stuhl.',
      en: 'Mobilises the spine on a chair.',
    },
    steps: [
      {
        de: 'Setzen Sie sich aufrecht auf einen stabilen Stuhl.',
        en: 'Sit upright on a stable chair.',
      },
      {
        de: 'Drehen Sie den Oberkörper langsam nach rechts.',
        en: 'Slowly turn your upper body to the right.',
      },
      {
        de: 'Halten Sie 5 Sekunden und kehren Sie zur Mitte zurück.',
        en: 'Hold for 5 seconds and return to the centre.',
      },
      {
        de: 'Wiederholen Sie zur anderen Seite. Je Seite 5-mal.',
        en: 'Repeat on the other side. 5 times each side.',
      },
    ],
  },
  {
    key: 'bridge',
    durationSeconds: 150,
    title: { de: 'Brücke', en: 'Bridge' },
    summary: {
      de: 'Kräftigt Gesäß und unteren Rücken.',
      en: 'Strengthens buttocks and lower back.',
    },
    steps: [
      {
        de: 'Legen Sie sich auf den Rücken. Die Füße stehen hüftbreit.',
        en: 'Lie on your back with feet hip-width apart.',
      },
      { de: 'Heben Sie das Becken langsam an.', en: 'Slowly lift your hips.' },
      { de: 'Halten Sie 5 Sekunden.', en: 'Hold for 5 seconds.' },
      {
        de: 'Senken Sie das Becken langsam ab. Wiederholen Sie 8-mal.',
        en: 'Lower slowly. Repeat 8 times.',
      },
    ],
  },
  {
    key: 'cat-cow-seated',
    durationSeconds: 90,
    title: { de: 'Katzenbuckel im Sitzen', en: 'Seated cat-cow' },
    summary: {
      de: 'Bewegt die Wirbelsäule rund und gerade.',
      en: 'Moves the spine between round and straight.',
    },
    steps: [
      {
        de: 'Sitzen Sie aufrecht. Die Hände liegen auf den Knien.',
        en: 'Sit upright with your hands on your knees.',
      },
      {
        de: 'Machen Sie den Rücken beim Ausatmen rund.',
        en: 'Round your back as you breathe out.',
      },
      { de: 'Richten Sie sich beim Einatmen wieder auf.', en: 'Straighten up as you breathe in.' },
      { de: 'Wiederholen Sie 8-mal in Ihrem Tempo.', en: 'Repeat 8 times at your own pace.' },
    ],
  },
  {
    key: 'easy-walk',
    durationSeconds: 600,
    title: { de: 'Lockeres Gehen', en: 'Easy walk' },
    summary: {
      de: '10 Minuten Gehen in angenehmem Tempo.',
      en: '10 minutes of walking at a comfortable pace.',
    },
    steps: [
      { de: 'Wählen Sie einen sicheren, ebenen Weg.', en: 'Choose a safe, level path.' },
      {
        de: 'Gehen Sie in einem Tempo, bei dem Sie sprechen können.',
        en: 'Walk at a pace where you can still talk.',
      },
      { de: 'Machen Sie Pausen, wann immer Sie möchten.', en: 'Take breaks whenever you like.' },
    ],
  },
];

export async function seedExercises(prisma: PrismaClient) {
  const versions: Record<string, string> = {};
  for (const exercise of EXERCISES) {
    const parent = await prisma.exercise.upsert({
      where: { key: exercise.key },
      create: { key: exercise.key },
      update: {},
    });
    const version = await prisma.exerciseVersion.upsert({
      where: { exerciseId_version: { exerciseId: parent.id, version: 1 } },
      create: {
        exerciseId: parent.id,
        version: 1,
        status: 'PUBLISHED',
        publishedAt: new Date(),
        title: exercise.title,
        summary: exercise.summary,
        steps: exercise.steps,
        safetyNotes: [STOP_RULE, DEMO_NOTE],
        durationSeconds: exercise.durationSeconds,
        transcript: {
          de: exercise.steps.map((s) => s.de).join(' '),
          en: exercise.steps.map((s) => s.en).join(' '),
        },
      },
      update: {},
    });
    versions[exercise.key] = version.id;
  }
  return versions;
}
