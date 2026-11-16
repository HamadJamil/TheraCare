import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';

/// Error returned by the API envelope or raised for connectivity problems.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message, this.status, this.fields = const {}});

  final String code;
  final String message;
  final int? status;
  final Map<String, String> fields;

  static const network = 'NETWORK';

  bool get isNetwork => code == network;
  bool get isRetryable => isNetwork || (status != null && status! >= 500);

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      final fields = (error['fields'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const {};
      return ApiException(
        code: '${error['code']}',
        message: '${error['message']}',
        status: e.response?.statusCode,
        fields: fields,
      );
    }
    if (e.response == null) return const ApiException(code: network, message: 'No connection');
    return ApiException(
      code: 'HTTP_${e.response!.statusCode}',
      message: 'Request failed',
      status: e.response!.statusCode,
    );
  }

  @override
  String toString() => 'ApiException($code, $status)';
}

/// Plain-language, localized message for any error.
String messageFor(BuildContext context, Object error) {
  final l10n = context.l10n;
  if (error is! ApiException) return l10n.errorGeneric;
  return switch (error.code) {
    ApiException.network => l10n.errorNetwork,
    'INVALID_CREDENTIALS' => l10n.errorInvalidCredentials,
    'EMAIL_NOT_VERIFIED' => l10n.errorEmailNotVerified,
    'INVALID_CODE' => l10n.errorInvalidCode,
    'RATE_LIMITED' => l10n.errorRateLimited,
    'ACTIVATION_INVALID' => l10n.errorActivationInvalid,
    'ACTIVATION_ALREADY_USED' => l10n.errorActivationUsed,
    'ACTIVATION_EXPIRED' => l10n.errorActivationExpired,
    'ACTIVATION_REVOKED' => l10n.errorActivationRevoked,
    'ACTIVATION_WRONG_PRODUCT' => l10n.errorActivationWrongProduct,
    'ALREADY_ACTIVATED' => l10n.errorAlreadyActivated,
    'ENTITLEMENT_REQUIRED' => l10n.errorEntitlementRequired,
    'CONSENT_REQUIRED' => l10n.errorConsentRequired,
    'ALREADY_SUBMITTED' => l10n.errorAlreadySubmitted,
    'REPORT_NOT_READY' => l10n.errorReportNotReady,
    'VALIDATION_ERROR' => l10n.errorValidation,
    'UNAUTHENTICATED' => l10n.errorSessionExpired,
    _ => l10n.errorGeneric,
  };
}
