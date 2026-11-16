import type { PrismaClient, QuestionnairePurpose, QuestionType } from '@prisma/client';

type L = { de: string; en: string };
type QuestionSeed = {
  key: string;
  type: QuestionType;
  prompt: L;
  help?: L;
  required?: boolean;
  options?: { value: number | string; label: L }[];
  min?: number;
  max?: number;
};

const DIFFICULTY_SCALE = [
  { value: 0, label: { de: 'Keine Schwierigkeiten', en: 'No difficulty' } },
  { value: 1, label: { de: 'Leichte Schwierigkeiten', en: 'Slight difficulty' } },
  { value: 2, label: { de: 'Mittlere Schwierigkeiten', en: 'Moderate difficulty' } },
  { value: 3, label: { de: 'Große Schwierigkeiten', en: 'Severe difficulty' } },
  { value: 4, label: { de: 'Nicht möglich', en: 'Not possible' } },
];

const likert = (key: string, de: string, en: string): QuestionSeed => ({
  key,
  type: 'LIKERT',
  prompt: { de, en },
  options: DIFFICULTY_SCALE,
});

/**
 * "TheraCare Rücken-Check": a self-made demo instrument (not a licensed or
 * validated questionnaire). Score = sum of items, range 0–34.
 */
const BACK_CHECK: QuestionSeed[] = [
  {
    key: 'pain-now',
    type: 'NUMERIC',
    prompt: {
      de: 'Wie stark sind Ihre Rückenschmerzen gerade?',
      en: 'How strong is your back pain right now?',
    },
    help: {
      de: '0 = keine Schmerzen, 10 = stärkste vorstellbare Schmerzen',
      en: '0 = no pain, 10 = worst pain imaginable',
    },
    min: 0,
    max: 10,
  },
  likert(
    'sitting',
    'Wie schwer fällt Ihnen längeres Sitzen?',
    'How hard is sitting for a longer time?',
  ),
  likert(
    'walking',
    'Wie schwer fällt Ihnen Gehen (15 Minuten)?',
    'How hard is walking for 15 minutes?',
  ),
  likert(
    'sleeping',
    'Wie sehr stört der Schmerz Ihren Schlaf?',
    'How much does pain disturb your sleep?',
  ),
  likert(
    'lifting',
    'Wie schwer fällt Ihnen leichtes Heben (z. B. Einkaufstasche)?',
    'How hard is light lifting (e.g. a shopping bag)?',
  ),
  likert('chores', 'Wie schwer fällt Ihnen Hausarbeit?', 'How hard are household chores?'),
  likert(
    'worry',
    'Wie sehr beunruhigt Sie Ihr Rücken im Alltag?',
    'How much does your back worry you in daily life?',
  ),
];

const WEEKLY: QuestionSeed[] = [
  {
    key: 'week-overall',
    type: 'SINGLE_CHOICE',
    prompt: { de: 'Wie ging es Ihrem Rücken diese Woche?', en: 'How was your back this week?' },
    options: [
      { value: 'better', label: { de: 'Besser', en: 'Better' } },
      { value: 'same', label: { de: 'Gleich', en: 'About the same' } },
      { value: 'worse', label: { de: 'Schlechter', en: 'Worse' } },
    ],
  },
  {
    key: 'week-exercises-ok',
    type: 'YES_NO',
    prompt: {
      de: 'Konnten Sie die Übungen gut durchführen?',
      en: 'Could you do the exercises well?',
    },
  },
  {
    key: 'week-helped',
    type: 'MULTI_CHOICE',
    required: false,
    prompt: {
      de: 'Was hat Ihnen geholfen? (mehrere möglich)',
      en: 'What helped you? (choose any)',
    },
    options: [
      { value: 'exercises', label: { de: 'Übungen', en: 'Exercises' } },
      { value: 'walking', label: { de: 'Spaziergänge', en: 'Walks' } },
      { value: 'rest', label: { de: 'Pausen', en: 'Breaks' } },
      { value: 'heat', label: { de: 'Wärme', en: 'Heat' } },
    ],
  },
  {
    key: 'week-note',
    type: 'LONG_TEXT',
    required: false,
    prompt: { de: 'Möchten Sie noch etwas notieren?', en: 'Would you like to note anything else?' },
    help: {
      de: 'Freiwillig. Bitte keine Notfälle melden.',
      en: 'Optional. Please do not report emergencies here.',
    },
  },
];

const QUESTIONNAIRES: {
  key: string;
  purpose: QuestionnairePurpose;
  title: L;
  description: L;
  scoringAlgorithm: string;
  questions: QuestionSeed[];
}[] = [
  {
    key: 'back-check-baseline',
    purpose: 'BASELINE',
    title: { de: 'Rücken-Check zu Beginn', en: 'Starting back check' },
    description: {
      de: '7 kurze Fragen zu Ihrem Rücken. Es gibt keine falschen Antworten.',
      en: '7 short questions about your back. There are no wrong answers.',
    },
    scoringAlgorithm: 'sum_v1',
    questions: BACK_CHECK,
  },
  {
    key: 'weekly-check-in',
    purpose: 'ROUTINE',
    title: { de: 'Wochen-Rückblick', en: 'Weekly check-in' },
    description: {
      de: 'Ein kurzer Rückblick auf Ihre Woche.',
      en: 'A short look back at your week.',
    },
    scoringAlgorithm: 'none_v1',
    questions: WEEKLY,
  },
  {
    key: 'back-check-final',
    purpose: 'FINAL',
    title: { de: 'Rücken-Check zum Abschluss', en: 'Final back check' },
    description: {
      de: 'Die gleichen Fragen wie zu Beginn, damit Sie Ihren Verlauf sehen.',
      en: 'The same questions as at the start, so you can see your progress.',
    },
    scoringAlgorithm: 'sum_v1',
    questions: BACK_CHECK,
  },
];

export async function seedQuestionnaires(prisma: PrismaClient) {
  for (const q of QUESTIONNAIRES) {
    const exists = await prisma.questionnaire.findUnique({
      where: { key_version: { key: q.key, version: 1 } },
    });
    if (exists) continue;
    await prisma.questionnaire.create({
      data: {
        key: q.key,
        version: 1,
        purpose: q.purpose,
        status: 'PUBLISHED',
        publishedAt: new Date(),
        title: q.title,
        description: q.description,
        scoringAlgorithm: q.scoringAlgorithm,
        scoringVersion: `${q.scoringAlgorithm}@1`,
        questions: {
          create: q.questions.map((question, order) => ({
            key: question.key,
            order,
            type: question.type,
            prompt: question.prompt,
            help: question.help,
            required: question.required ?? true,
            options: question.options,
            min: question.min,
            max: question.max,
          })),
        },
      },
    });
  }
}
