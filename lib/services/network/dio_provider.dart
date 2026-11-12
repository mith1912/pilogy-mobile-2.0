import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';
import '../../core/network/api_failure.dart';

Dio createDio(
  AppEnvironment environment, {
  Duration connectTimeout = const Duration(seconds: 10),
  Duration sendTimeout = const Duration(seconds: 10),
  Duration receiveTimeout = const Duration(seconds: 20),
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: environment.apiBaseUri.toString(),
      connectTimeout: connectTimeout,
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
      headers: {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
      // Public content may return a bodyless cache-validation response.
      validateStatus:
          (status) =>
              status != null &&
              ((status >= 200 && status < 300) || status == 304),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) {
        handler.next(error.copyWith(error: ApiFailure.fromDio(error)));
      },
    ),
  );
  return dio;
}

final dioProvider = Provider<Dio>((ref) {
  final dio = createDio(ref.watch(environmentProvider));
  ref.onDispose(() => dio.close(force: true));
  return dio;
});
