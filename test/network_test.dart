import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/core/config/app_environment.dart';
import 'package:pilogy_app/core/network/api_failure.dart';
import 'package:pilogy_app/services/network/dio_provider.dart';

void main() {
  test(
    'Dio uses configured base, finite timeouts and accepts bodyless 304',
    () {
      final dio = createDio(
        AppEnvironment(apiBaseUrl: 'https://test.example/api/v1'),
      );
      addTearDown(() => dio.close(force: true));
      expect(dio.options.baseUrl, 'https://test.example/api/v1/');
      expect(dio.options.connectTimeout, const Duration(seconds: 10));
      expect(dio.options.sendTimeout, const Duration(seconds: 10));
      expect(dio.options.receiveTimeout, const Duration(seconds: 20));
      expect(dio.options.validateStatus(304), isTrue);
      expect(dio.options.validateStatus(429), isFalse);
    },
  );

  test('network failures retain classification without raw private bodies', () {
    final options = RequestOptions(path: 'numerology/calculate');
    expect(
      ApiFailure.fromDio(
        DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      ).kind,
      ApiFailureKind.timeout,
    );
    expect(
      ApiFailure.fromDio(
        DioException(requestOptions: options, type: DioExceptionType.cancel),
      ).kind,
      ApiFailureKind.cancelled,
    );
    final missingContent = ApiFailure.fromDio(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 500,
          data: {
            'success': false,
            'error': {'code': 'INTERPRETATION_CONTENT_MISSING'},
          },
        ),
      ),
    );
    expect(missingContent.code, 'INTERPRETATION_CONTENT_MISSING');
    expect(missingContent.statusCode, 500);
    final platformFailure = ApiFailure.fromDio(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 429,
          data: '<html>Too many requests</html>',
        ),
      ),
    );
    expect(platformFailure.kind, ApiFailureKind.http);
    expect(platformFailure.code, isNull);
  });
}
