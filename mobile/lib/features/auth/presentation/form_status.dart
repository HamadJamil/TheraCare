import '../../../core/network/api_exception.dart';

/// Small immutable form state shared by the auth screens (DRY).
class FormStatus {
  const FormStatus({this.busy = false, this.error, this.fieldErrors = const {}});
  final bool busy;
  final Object? error;
  final Map<String, String> fieldErrors;

  static FormStatus failed(Object error) =>
      FormStatus(error: error, fieldErrors: error is ApiException ? error.fields : const {});
}
