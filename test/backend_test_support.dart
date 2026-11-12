import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pilogy_app/features/numerology/domain/api_models.dart';

Json fixture(String name) =>
    object(jsonDecode(File('test/fixtures/$name.json').readAsStringSync()));

class TestAdapter implements HttpClientAdapter {
  TestAdapter(this.respond);
  final Future<ResponseBody> Function(RequestOptions) respond;
  final List<RequestOptions> requests = [];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(
  Object? data, {
  int status = 200,
  Map<String, List<String>>? headers,
}) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
    ...?headers,
  },
);
