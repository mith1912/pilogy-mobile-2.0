import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:pilogy_app/app/app.dart';
import 'package:pilogy_app/core/config/app_environment.dart';
import 'package:pilogy_app/features/numerology/presentation/backend_providers.dart';
import 'package:pilogy_app/services/network/dio_provider.dart';
import 'package:pilogy_app/services/storage/cache_store.dart';
import 'package:pilogy_app/services/storage/local_database.dart';
import '../test/backend_test_support.dart' show TestAdapter;
import 'fixture_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native SQLite create → overview → Master article → cache', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final directory = await Directory.systemTemp.createTemp(
      'pilogy-device-test-',
    );
    final database = LocalDatabase(
      databasePath: '${directory.path}/pilogy-test.db',
    );
    final dio = createDio(AppEnvironment());
    final adapter = TestAdapter((options) async {
      final key =
          options.path == 'config'
              ? 'config'
              : options.path == 'numerology/definitions'
              ? 'definitions'
              : options.path == 'numerology/calculate'
              ? 'calculation'
              : 'article';
      return ResponseBody.fromString(
        fixtureBodies[key]!,
        200,
        headers: {
          'content-type': ['application/json'],
        },
      );
    });
    dio.httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        localDatabaseProvider.overrideWithValue(database),
        dioProvider.overrideWithValue(dio),
        selectedReferenceDateProvider.overrideWith((ref) => '2026-11-08'),
      ],
    );
    addTearDown(() async {
      container.dispose();
      dio.close(force: true);
      await database.close();
      await directory.delete(recursive: true);
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PilogyApp(useGoogleFonts: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('welcome-start')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('profile-full-name')),
        matching: find.byType(TextFormField),
      ),
      'Nguyễn Văn An',
    );
    for (final part in {'Ngày': '20', 'Tháng': '05', 'Năm': '1990'}.entries) {
      await tester.enterText(
        find.byKey(ValueKey('profile-date-${part.key}')),
        part.value,
      );
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('save-profile')));
    await tester.tap(find.byKey(const ValueKey('save-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-V03')), findsOneWidget);
    expect(find.byKey(const ValueKey('number-lifePath')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('detail-personality')),
    );
    await tester.tap(find.byKey(const ValueKey('detail-personality')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-V05')), findsOneWidget);
    expect(find.text('11/2'), findsOneWidget);
    final stats = await container.read(cacheStoreProvider).statistics();
    expect(stats.calculations, 1);
    expect(stats.articles, 1);
    expect(adapter.requests.last.path, endsWith('/personality/11'));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
