import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/core/config/app_environment.dart';

void main() {
  test(
    'default URL retains the API prefix and resolves relative endpoints',
    () {
      final environment = AppEnvironment();
      expect(
        environment.apiBaseUri.resolve('numerology/calculate').path,
        '/api/v1/numerology/calculate',
      );
      expect(environment.apiBaseUri.scheme, 'https');
    },
  );

  test('compile-time API_BASE_URL is respected', () {
    const configured = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: AppEnvironment.defaultApiBaseUrl,
    );
    expect(
      AppEnvironment.fromDartDefines().apiBaseUri,
      AppEnvironment(apiBaseUrl: configured).apiBaseUri,
    );
  });

  test('custom environment and local emulator URLs are normalized', () {
    expect(
      AppEnvironment(
        apiBaseUrl: 'https://staging.example/api/v1///',
      ).apiBaseUri.toString(),
      'https://staging.example/api/v1/',
    );
    expect(
      AppEnvironment(
        apiBaseUrl: 'http://10.0.2.2:3100/api/v1',
      ).apiBaseUri.resolve('health').toString(),
      'http://10.0.2.2:3100/api/v1/health',
    );
  });

  test('invalid and insecure remote endpoints are rejected', () {
    for (final value in [
      '',
      'not a URL',
      'http://remote.example/api/v1',
      'https://user:password@example.com/api/v1',
      'https://example.com/api/v1?token=x',
      'https://example.com/api/v1#fragment',
    ]) {
      expect(() => AppEnvironment(apiBaseUrl: value), throwsFormatException);
    }
  });
}
