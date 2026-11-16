import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theracare/core/network/api_exception.dart';

void main() {
  final request = RequestOptions(path: '/x');

  test('reads the error envelope', () {
    final e = ApiException.fromDio(
      DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 400,
          data: {
            'success': false,
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'Check',
              'fields': {'email': 'bad'},
            },
          },
        ),
      ),
    );
    expect(e.code, 'VALIDATION_ERROR');
    expect(e.status, 400);
    expect(e.fields, {'email': 'bad'});
    expect(e.isRetryable, isFalse);
  });

  test('treats missing responses as retryable network errors', () {
    final e = ApiException.fromDio(DioException(requestOptions: request, type: DioExceptionType.connectionError));
    expect(e.isNetwork, isTrue);
    expect(e.isRetryable, isTrue);
  });

  test('treats server errors as retryable', () {
    final e = ApiException.fromDio(
      DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 503),
      ),
    );
    expect(e.isRetryable, isTrue);
  });
}
