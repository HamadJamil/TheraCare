import '../../../core/l10n/l10n.dart';

/// Client-side checks give immediate, localized feedback. The server validates again.
abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(AppLocalizations l10n, String value) =>
      _email.hasMatch(value.trim()) ? null : l10n.validationEmail;

  static String? password(AppLocalizations l10n, String value) => value.length >= 10 ? null : l10n.validationPassword;

  static String? required(AppLocalizations l10n, String value) => value.trim().isEmpty ? l10n.validationRequired : null;

  static String? code(AppLocalizations l10n, String value) =>
      RegExp(r'^\d{6}$').hasMatch(value.trim()) ? null : l10n.validationCode;
}
