import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

enum ApiFailureKind { timeout, connection, cancelled, http, malformed, unknown }

/// Safe presentation metadata. Never stores raw bodies, request data or names.
class ApiFailure implements Exception {
  const ApiFailure(this.kind, {this.statusCode, this.code, this.retryAfter});

  final ApiFailureKind kind;
  final int? statusCode;
  final String? code;
  final Duration? retryAfter;

  bool get isOffline =>
      kind == ApiFailureKind.connection || kind == ApiFailureKind.timeout;

  factory ApiFailure.fromDio(DioException exception) {
    final kind = switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => ApiFailureKind.timeout,
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate => ApiFailureKind.connection,
      DioExceptionType.cancel => ApiFailureKind.cancelled,
      DioExceptionType.badResponse => ApiFailureKind.http,
      DioExceptionType.unknown =>
        exception.error is FormatException
            ? ApiFailureKind.malformed
            : ApiFailureKind.unknown,
    };
    return ApiFailure(
      kind,
      statusCode: exception.response?.statusCode,
      code: _safeCode(exception.response?.data),
      retryAfter: parseRetryAfter(
        exception.response?.headers.value('retry-after'),
      ),
    );
  }

  static String? _safeCode(Object? body) {
    // Platforms can return text/HTML for 429, 404, 405 and other failures.
    if (body is String) {
      try {
        body = jsonDecode(body);
      } on FormatException {
        return null;
      }
    }
    if (body is! Map || body['success'] != false) return null;
    final error = body['error'];
    if (error is! Map) return null;
    final code = error['code'];
    const knownCodes = {
      'INVALID_JSON',
      'VALIDATION_ERROR',
      'INTERPRETATION_NOT_FOUND',
      'PAYLOAD_TOO_LARGE',
      'RATE_LIMIT_EXCEEDED',
      'UNSUPPORTED_MEDIA_TYPE',
      'CALCULATION_RULE_UNSPECIFIED',
      'INTERPRETATION_CONTENT_MISSING',
      'INTERNAL_ERROR',
    };
    return code is String && knownCodes.contains(code) ? code : null;
  }
}

Duration? parseRetryAfter(String? value, {DateTime? now}) {
  if (value == null) return null;
  final seconds = int.tryParse(value.trim());
  if (seconds != null) return seconds >= 0 ? Duration(seconds: seconds) : null;
  try {
    final delay = HttpDate.parse(
      value,
    ).difference((now ?? DateTime.now()).toUtc());
    return delay.isNegative ? Duration.zero : delay;
  } on FormatException {
    return null;
  } on HttpException {
    return null;
  }
}

String apiErrorMessage(ApiFailure failure) {
  if (failure.code == 'INTERPRETATION_CONTENT_MISSING')
    return 'Nội dung luận giải cho hồ sơ này chưa có sẵn.';
  if (failure.statusCode == 429)
    return 'Quá nhiều yêu cầu. Vui lòng chờ trước khi thử lại.';
  if (failure.isOffline)
    return 'Không thể kết nối máy chủ. Vui lòng kiểm tra kết nối.';
  if (failure.statusCode == 404) return 'Nội dung chưa có sẵn.';
  if (failure.statusCode == 400 || failure.statusCode == 422)
    return 'Không thể xử lý dữ liệu này. Vui lòng kiểm tra hồ sơ.';
  return 'Không thể tải dữ liệu. Vui lòng thử lại sau.';
}
