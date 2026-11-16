import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers/core_providers.dart';

class FaqEntry {
  const FaqEntry(this.category, this.question, this.answer);
  final String category;
  final String question;
  final String answer;
}

class Ticket {
  const Ticket(this.subject, this.status, this.createdAt);
  final String subject;
  final String status;
  final DateTime createdAt;
}

abstract interface class SupportRepository {
  Future<List<FaqEntry>> faq();
  Future<List<Ticket>> myTickets();
  Future<void> createTicket({required String category, required String subject, required String message});
}

class ApiSupportRepository implements SupportRepository {
  ApiSupportRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<FaqEntry>> faq() async =>
      (await _api.get<List<dynamic>>('/support/faq'))
          .cast<Map<String, dynamic>>()
          .map((j) => FaqEntry(j['category'] as String, j['question'] as String, j['answer'] as String))
          .toList();

  @override
  Future<List<Ticket>> myTickets() async =>
      (await _api.get<List<dynamic>>('/support/tickets/me'))
          .cast<Map<String, dynamic>>()
          .map((j) => Ticket(j['subject'] as String, j['status'] as String, DateTime.parse(j['createdAt'] as String)))
          .toList();

  @override
  Future<void> createTicket({required String category, required String subject, required String message}) =>
      _api.post<Object?>('/support/tickets', body: {'category': category, 'subject': subject, 'message': message});
}

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => ApiSupportRepository(ref.watch(apiClientProvider)),
);
final faqProvider = FutureProvider.autoDispose((ref) => ref.watch(supportRepositoryProvider).faq());
final myTicketsProvider = FutureProvider.autoDispose((ref) => ref.watch(supportRepositoryProvider).myTickets());
