import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_failure.dart';
import '../../features/numerology/domain/api_models.dart';
import 'dio_provider.dart';

/// No payload logging or automatic retries. Every call may be cancelled.
class ApiClient {
  ApiClient(this.dio);
  final Dio dio;
  DateTime? _blockedUntil;

  Future<Json> request(
    String path, {
    Json? body,
    Json? query,
    CancelToken? cancelToken,
  }) async {
    final blocked = _blockedUntil;
    if (blocked != null && blocked.isAfter(DateTime.now())) {
      throw ApiFailure(
        ApiFailureKind.http,
        statusCode: 429,
        retryAfter: blocked.difference(DateTime.now()),
      );
    }
    try {
      final response = await dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        cancelToken: cancelToken,
        options: Options(
          method: body == null ? 'GET' : 'POST',
          responseType: ResponseType.plain,
        ),
      );
      final raw = response.data;
      final envelope = object(raw is String ? jsonDecode(raw) : raw);
      if (envelope['success'] != true) schemaError();
      return object(envelope['data']);
    } on DioException catch (e) {
      final failure = ApiFailure.fromDio(e);
      if (failure.statusCode == 429) {
        _blockedUntil = DateTime.now().add(
          failure.retryAfter ?? const Duration(seconds: 30),
        );
      }
      throw failure;
    } on FormatException {
      throw const ApiFailure(ApiFailureKind.malformed);
    }
  }
}

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);
