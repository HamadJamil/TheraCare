import type { TicketStatus } from '@prisma/client';
import { prisma } from '../../config/database';
import { Errors } from '../../common/errors';
import { pickLocale, type Locale } from '../../common/localized';
import { audit } from '../audit/audit.service';
import { FAQ } from './faq';

export const listFaq = (locale: Locale) =>
  FAQ.map((f) => ({
    category: f.category,
    question: pickLocale(f.question, locale),
    answer: pickLocale(f.answer, locale),
  }));

/** Support must never receive activation codes; anything shaped like one is removed. */
const CODE_LIKE =
  /\b[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}\b|\b(?=[A-Z0-9]*\d)(?=[A-Z0-9]*[A-Z])[A-Z0-9]{12}\b/gi;
export const redact = (text: string) => text.replace(CODE_LIKE, '[removed]');

type TicketInput = { category: string; subject: string; message: string };

const ticketView = (t: {
  id: string;
  category: string;
  subject: string;
  status: TicketStatus;
  createdAt: Date;
  updatedAt: Date;
}) => ({
  id: t.id,
  category: t.category,
  subject: t.subject,
  status: t.status,
  createdAt: t.createdAt,
  updatedAt: t.updatedAt,
});

export async function createTicket(userId: string, input: TicketInput, requestId?: string) {
  const ticket = await prisma.supportTicket.create({
    data: {
      userId,
      category: input.category,
      subject: redact(input.subject),
      message: redact(input.message),
    },
  });
  await audit({
    action: 'support.ticket_created',
    resourceType: 'support_ticket',
    resourceId: ticket.id,
    actorId: userId,
    requestId,
  });
  return ticketView(ticket);
}

export async function myTickets(userId: string) {
  const rows = await prisma.supportTicket.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
  });
  return rows.map(ticketView);
}

/** Staff view: ticket content and contact email only — no health records. */
export async function staffTickets(status?: TicketStatus) {
  const rows = await prisma.supportTicket.findMany({
    where: { status },
    orderBy: { createdAt: 'asc' },
    include: { user: { select: { email: true } } },
    take: 100,
  });
  return rows.map((t) => ({
    ...ticketView(t),
    message: t.message,
    agentNote: t.agentNote,
    contactEmail: t.user.email,
  }));
}

export async function updateTicket(
  ticketId: string,
  data: { status?: TicketStatus; agentNote?: string },
  actor: { userId: string; role: 'SUPPORT_AGENT' | 'ADMIN' },
  requestId?: string,
) {
  const exists = await prisma.supportTicket.findUnique({ where: { id: ticketId } });
  if (!exists) throw Errors.notFound('The ticket');
  const ticket = await prisma.supportTicket.update({ where: { id: ticketId }, data });
  await audit({
    action: 'support.ticket_updated',
    resourceType: 'support_ticket',
    resourceId: ticketId,
    actorId: actor.userId,
    actorRole: actor.role,
    requestId,
    sourceContext: { status: data.status ?? null },
  });
  return ticketView(ticket);
}
