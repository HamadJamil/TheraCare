import type { Prisma, Question, Questionnaire } from '@prisma/client';
import { prisma } from '../../config/database';
import { Errors, type FieldErrors } from '../../common/errors';
import { pickLocale, type Locale } from '../../common/localized';
import { audit } from '../audit/audit.service';
import {
  availablePurposes,
  onSubmitted,
  submittedThisWeek,
} from '../assessments/assessments.service';
import { isEmpty, validateAnswer } from './answer-validation';
import { score, type AnswerMap } from './scoring';

export type AnswerInput = { questionKey: string; value?: unknown }[];

type WithQuestions = Questionnaire & { questions: Question[] };

/** Latest published version of each questionnaire the patient may currently answer. */
async function assignedQuestionnaires(userId: string): Promise<WithQuestions[]> {
  const purposes = await availablePurposes(userId);
  if (purposes.length === 0) return [];
  const published = await prisma.questionnaire.findMany({
    where: { status: 'PUBLISHED', purpose: { in: purposes } },
    include: { questions: { orderBy: { order: 'asc' } } },
    orderBy: { version: 'desc' },
  });
  const latest = new Map<string, WithQuestions>();
  for (const q of published) if (!latest.has(q.key)) latest.set(q.key, q);
  return [...latest.values()];
}

async function requireAssigned(userId: string, questionnaireId: string) {
  const questionnaire = (await assignedQuestionnaires(userId)).find(
    (q) => q.id === questionnaireId,
  );
  if (!questionnaire) throw Errors.notFound('The questionnaire');
  return questionnaire;
}

const findDraft = (userId: string, questionnaireId: string) =>
  prisma.questionnaireResponse.findFirst({
    where: { userId, questionnaireId, status: 'DRAFT' },
    include: { answers: { include: { question: true } } },
  });

export async function listAssigned(userId: string, locale: Locale) {
  const questionnaires = await assignedQuestionnaires(userId);
  return Promise.all(
    questionnaires.map(async (q) => {
      const draft = await findDraft(userId, q.id);
      const submitted = q.purpose === 'ROUTINE' && (await submittedThisWeek(userId, q.id));
      return {
        id: q.id,
        key: q.key,
        version: q.version,
        purpose: q.purpose,
        title: pickLocale(q.title, locale),
        description: pickLocale(q.description, locale),
        questionCount: q.questions.length,
        status: submitted ? 'SUBMITTED' : draft ? 'DRAFT' : 'NOT_STARTED',
      };
    }),
  );
}

export async function getDefinition(userId: string, questionnaireId: string, locale: Locale) {
  const q = await requireAssigned(userId, questionnaireId);
  const draft = await findDraft(userId, q.id);
  return {
    id: q.id,
    key: q.key,
    version: q.version,
    purpose: q.purpose,
    title: pickLocale(q.title, locale),
    description: pickLocale(q.description, locale),
    questions: q.questions.map((question) => ({
      key: question.key,
      type: question.type,
      required: question.required,
      prompt: pickLocale(question.prompt, locale),
      help: question.help ? pickLocale(question.help, locale) : null,
      min: question.min,
      max: question.max,
      options: ((question.options as { value: unknown; label: unknown }[] | null) ?? []).map(
        (o) => ({
          value: o.value,
          label: pickLocale(o.label, locale),
        }),
      ),
    })),
    draft: draft && {
      id: draft.id,
      answers: draft.answers.map((a) => ({ questionKey: a.question.key, value: a.value })),
    },
  };
}

/** Validates answers; `complete` additionally enforces required questions. */
function checkAnswers(q: WithQuestions, answers: AnswerInput, complete: boolean): AnswerMap {
  const byKey = new Map(q.questions.map((question) => [question.key, question]));
  const fields: FieldErrors = {};
  const map: AnswerMap = new Map();

  for (const { questionKey, value } of answers) {
    const question = byKey.get(questionKey);
    if (!question) {
      fields[questionKey] = 'This question does not exist.';
      continue;
    }
    if (isEmpty(value)) continue;
    const error = validateAnswer(question, value);
    if (error) fields[questionKey] = error;
    else map.set(question.id, value);
  }
  if (complete) {
    for (const question of q.questions) {
      if (question.required && !map.has(question.id) && !fields[question.key]) {
        fields[question.key] = 'Please answer this question.';
      }
    }
  }
  if (Object.keys(fields).length > 0) throw Errors.validation(fields);
  return map;
}

function answerRows(responseId: string, answers: AnswerMap) {
  return [...answers].map(([questionId, value]) => ({
    responseId,
    questionId,
    value: value as Prisma.InputJsonValue,
  }));
}

export async function saveDraft(userId: string, questionnaireId: string, answers: AnswerInput) {
  const q = await requireAssigned(userId, questionnaireId);
  const map = checkAnswers(q, answers, false);
  return prisma.$transaction(async (tx) => {
    const existing = await tx.questionnaireResponse.findFirst({
      where: { userId, questionnaireId, status: 'DRAFT' },
    });
    const draft =
      existing ?? (await tx.questionnaireResponse.create({ data: { userId, questionnaireId } }));
    await tx.questionnaireAnswer.deleteMany({ where: { responseId: draft.id } });
    await tx.questionnaireAnswer.createMany({ data: answerRows(draft.id, map) });
    return { id: draft.id, status: draft.status, savedAnswers: map.size };
  });
}

/** Submits an immutable response with its questionnaire and scoring version. */
export async function submit(
  userId: string,
  questionnaireId: string,
  answers: AnswerInput,
  requestId?: string,
) {
  const q = await requireAssigned(userId, questionnaireId);
  const map = checkAnswers(q, answers, true);
  const total = score(q.scoringAlgorithm, q.questions, map);

  return prisma.$transaction(async (tx) => {
    const draft = await tx.questionnaireResponse.findFirst({
      where: { userId, questionnaireId, status: 'DRAFT' },
    });
    const response =
      draft ?? (await tx.questionnaireResponse.create({ data: { userId, questionnaireId } }));
    await tx.questionnaireAnswer.deleteMany({ where: { responseId: response.id } });
    await tx.questionnaireAnswer.createMany({ data: answerRows(response.id, map) });
    const submitted = await tx.questionnaireResponse.update({
      where: { id: response.id },
      data: {
        status: 'SUBMITTED',
        submittedAt: new Date(),
        score: total,
        scoringVersion: q.scoringVersion,
      },
    });
    const outcome = await onSubmitted(tx, q.purpose, {
      userId,
      responseId: submitted.id,
      questionnaireId,
      score: total,
    });
    await audit(
      {
        action: 'questionnaire.submitted',
        resourceType: 'questionnaire_response',
        resourceId: submitted.id,
        actorId: userId,
        requestId,
        sourceContext: { key: q.key, version: q.version, purpose: q.purpose },
      },
      tx,
    );
    return {
      id: submitted.id,
      status: submitted.status,
      questionnaire: { key: q.key, version: q.version },
      score: total,
      scoringVersion: q.scoringVersion,
      submittedAt: submitted.submittedAt,
      ...outcome,
    };
  });
}
