import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/core/config/app_environment.dart';
import 'package:pilogy_app/core/network/api_failure.dart';
import 'package:pilogy_app/services/network/api_client.dart';
import 'package:pilogy_app/services/network/dio_provider.dart';
import 'backend_test_support.dart';

void main() {
  late Dio dio;
  late ApiClient client;
  setUp(() {
    dio = createDio(AppEnvironment());
    client = ApiClient(dio);
  });
  tearDown(() => dio.close());
  test('decodes JSON and preserves base API prefix', () async {
    dio.httpClientAdapter = TestAdapter((o) async {
      expect(o.uri.path, '/api/v1/health');
      return jsonBody(fixture('health'));
    });
    expect((await client.request('health'))['status'], 'ok');
  });
  for (final timeout in [
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
  ]) {
    test('maps $timeout safely', () async {
      dio.httpClientAdapter = TestAdapter(
        (o) async => throw DioException(requestOptions: o, type: timeout),
      );
      await expectLater(
        client.request('health'),
        throwsA(isA<ApiFailure>().having((e) => e.isOffline, 'offline', true)),
      );
    });
  }
  for (final status in [400, 404, 413, 415, 422, 500, 502, 503]) {
    test(
      'HTTP $status supports standard JSON and infrastructure HTML',
      () async {
        for (final body in [
          jsonBody({
            'success': false,
            'error': {'code': 'VALIDATION_ERROR'},
          }, status: status),
          ResponseBody.fromString('<html>Unavailable</html>', status),
        ]) {
          dio.httpClientAdapter = TestAdapter((o) async => body);
          await expectLater(
            client.request('health'),
            throwsA(
              isA<ApiFailure>().having((e) => e.statusCode, 'status', status),
            ),
          );
        }
      },
    );
  }
  test(
    '429 respects Retry-After across manual refreshes without a loop',
    () async {
      final adapter = TestAdapter(
        (o) async => ResponseBody.fromString(
          'rate limited',
          429,
          headers: {
            'retry-after': ['120'],
          },
        ),
      );
      dio.httpClientAdapter = adapter;
      await expectLater(
        client.request('health'),
        throwsA(
          isA<ApiFailure>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 120),
          ),
        ),
      );
      await expectLater(client.request('health'), throwsA(isA<ApiFailure>()));
      expect(adapter.requests, hasLength(1));
      expect(
        parseRetryAfter(
          'Mon, 09 Nov 2026 00:01:00 GMT',
          now: DateTime.utc(2026, 11, 9),
        ),
        const Duration(minutes: 1),
      );
      expect(parseRetryAfter('invalid'), isNull);
    },
  );
  test(
    'malformed JSON, missing envelope, schema mismatch and 304 are safe failures',
    () async {
      for (final body in [
        ResponseBody.fromString('{', 200),
        jsonBody({'data': {}}),
        jsonBody({'success': true, 'data': []}),
        ResponseBody.fromString('', 304),
      ]) {
        dio.httpClientAdapter = TestAdapter((o) async => body);
        await expectLater(
          client.request('health'),
          throwsA(
            isA<ApiFailure>().having(
              (e) => e.kind,
              'kind',
              ApiFailureKind.malformed,
            ),
          ),
        );
      }
    },
  );
}
