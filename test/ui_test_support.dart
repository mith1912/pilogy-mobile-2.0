import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pilogy_app/app/app.dart';
import 'package:pilogy_app/features/numerology/presentation/backend_providers.dart';
import 'package:pilogy_app/features/privacy_data/data/local_data_actions.dart';
import 'package:pilogy_app/services/network/dio_provider.dart';
import 'package:pilogy_app/services/storage/local_database.dart';
import 'package:pilogy_app/core/config/app_environment.dart';
import 'backend_test_support.dart';

class FakeExportDriver implements ProfileExportDriver {
  String? exported;
  @override
  Future<bool> export(String json) async {
    exported = json;
    return true;
  }
}

class UiHarness {
  UiHarness._(
    this.directory,
    this.database,
    this.container,
    this.dio,
    this.exporter,
    this.adapter,
  );
  final Directory directory;
  final LocalDatabase database;
  final ProviderContainer container;
  final Dio dio;
  final FakeExportDriver exporter;
  final TestAdapter adapter;
  static Future<UiHarness> open({
    Directory? directory,
    bool offline = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final root =
        directory ?? await Directory.systemTemp.createTemp('pilogy-m04-ui-');
    final database = LocalDatabase(
      factory: databaseFactoryFfi,
      databasePath: '${root.path}/test.db',
    );
    await database.database;
    final dio = createDio(AppEnvironment());
    final adapter = TestAdapter((options) async {
      if (offline)
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      if (options.path == 'config') return jsonBody(fixture('config'));
      if (options.path == 'numerology/definitions')
        return jsonBody(fixture('definitions'));
      if (options.path == 'numerology/calculate')
        return jsonBody(fixture('calculation'));
      return jsonBody(fixture('article'));
    });
    dio.httpClientAdapter = adapter;
    final exporter = FakeExportDriver();
    final container = ProviderContainer(
      overrides: [
        localDatabaseProvider.overrideWithValue(database),
        dioProvider.overrideWithValue(dio),
        profileExportDriverProvider.overrideWithValue(exporter),
        selectedReferenceDateProvider.overrideWith((ref) => '2026-11-08'),
      ],
    );
    return UiHarness._(root, database, container, dio, exporter, adapter);
  }

  Widget get app => UncontrolledProviderScope(
    container: container,
    child: const PilogyApp(useGoogleFonts: false),
  );
  Future<void> close({bool delete = true}) async {
    container.dispose();
    dio.close(force: true);
    await database.close();
    if (delete) await directory.delete(recursive: true);
  }
}
