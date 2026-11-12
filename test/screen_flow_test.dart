import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pilogy_app/app/router.dart';
import 'package:pilogy_app/features/profiles/presentation/profiles_view_model.dart';
import 'package:pilogy_app/features/numerology/presentation/backend_providers.dart';
import 'package:pilogy_app/features/privacy_data/presentation/privacy_view_model.dart';
import 'package:pilogy_app/services/storage/cache_store.dart';
import 'ui_test_support.dart';

Future<void> tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  sqfliteFfiInit();
  testWidgets(
    'create, calculate, switch tabs, open Master article and read steps',
    (tester) async {
      final h = await UiHarness.open();
      addTearDown(h.close);
      await tester.pumpWidget(h.app);
      await tester.pumpAndSettle();
      await tapKey(tester, 'welcome-start');
      expect(find.byKey(const ValueKey('screen-V02')), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('profile-full-name')),
          matching: find.byType(TextFormField),
        ),
        'Nguyễn Văn An',
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile-date-Ngày')),
        '20',
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile-date-Tháng')),
        '05',
      );
      await tester.enterText(
        find.byKey(const ValueKey('profile-date-Năm')),
        '1990',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapKey(tester, 'save-profile');
      expect(find.byKey(const ValueKey('screen-V03')), findsOneWidget);
      expect(find.byKey(const ValueKey('number-lifePath')), findsOneWidget);
      final posts =
          h.adapter.requests
              .where((r) => r.path == 'numerology/calculate')
              .length;
      await tapKey(tester, 'tab-analysis');
      expect(find.byKey(const ValueKey('screen-V04')), findsOneWidget);
      expect(
        h.adapter.requests
            .where((r) => r.path == 'numerology/calculate')
            .length,
        posts,
      );
      await tapKey(tester, 'detail-personality');
      expect(find.byKey(const ValueKey('screen-V05')), findsOneWidget);
      expect(find.text('11/2'), findsOneWidget);
      expect(h.adapter.requests.last.path, endsWith('/personality/11'));
      await tapKey(tester, 'steps-personality');
      expect(find.text('5 + 7 + 7 + 5 + 4 + 5 + 5 = 38'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'returning user restores cached results offline; edits invalidate them',
    (tester) async {
      var h = await UiHarness.open();
      final directory = h.directory;
      final model = h.container.read(profilesViewModelProvider.notifier);
      final profile = await model.saveAndSelect(
        fullName: 'Nguyễn Văn An',
        birthDate: '1990-05-20',
      );
      await tester.pumpWidget(h.app);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-V03')), findsOneWidget);
      expect(
        (await h.container.read(cacheStoreProvider).statistics()).calculations,
        1,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await h.close(delete: false);
      h = await UiHarness.open(directory: directory, offline: true);
      addTearDown(h.close);
      await tester.pumpWidget(h.app);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('number-lifePath')), findsOneWidget);
      expect(find.text('Không có kết nối · Dữ liệu đã lưu'), findsOneWidget);
      await h.container
          .read(profilesViewModelProvider.notifier)
          .updateProfile(
            id: profile.id,
            fullName: 'Lê An',
            birthDate: '1990-05-20',
          );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('number-lifePath')), findsNothing);
      expect(
        (await h.container.read(cacheStoreProvider).statistics()).calculations,
        0,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'privacy exports real profiles; cache clear retains them; delete-all clears selection',
    (tester) async {
      final h = await UiHarness.open();
      addTearDown(h.close);
      await h.container
          .read(profilesViewModelProvider.notifier)
          .saveAndSelect(fullName: 'Nguyễn Văn An', birthDate: '1990-05-20');
      await tester.pumpWidget(h.app);
      await tester.pumpAndSettle();
      h.container.read(routerProvider).push('/privacy-data');
      await tester.pumpAndSettle();
      await tapKey(tester, 'export-profiles');
      await tapKey(tester, 'confirm-local-action');
      final data = jsonDecode(h.exporter.exported!) as Map<String, dynamic>;
      expect((data['profiles'] as List).single['full_name'], 'Nguyễn Văn An');
      await tapKey(tester, 'clear-cache');
      await tapKey(tester, 'confirm-local-action');
      expect(
        (await h.container.read(cacheStoreProvider).statistics()).calculations,
        0,
      );
      expect(
        h.container.read(profilesViewModelProvider).value!.profiles.length,
        1,
      );
      expect(h.container.read(calculationSuspensionProvider), isNotNull);
      await tapKey(tester, 'delete-all-profiles');
      await tapKey(tester, 'confirm-local-action');
      expect(
        h.container.read(profilesViewModelProvider).value!.selectedProfile,
        isNull,
      );
      expect(
        h.container.read(profilesViewModelProvider).value!.profiles,
        isEmpty,
      );
      expect(h.container.read(privacyViewModelProvider).value!.failed, false);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets('small phone and large text render without overflow', (
    tester,
  ) async {
    final h = await UiHarness.open();
    addTearDown(h.close);
    await tester.binding.setSurfaceSize(const Size(320, 700));
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    await h.container
        .read(profilesViewModelProvider.notifier)
        .saveAndSelect(fullName: 'Nguyễn Văn An', birthDate: '1990-05-20');
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();
    for (final path in [
      '/welcome',
      '/profile-form',
      '/profiles',
      '/settings',
      '/privacy-data',
      '/discover',
      '/analysis',
      '/number-detail?type=personality',
    ]) {
      h.container.read(routerProvider).go(path);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: path);
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
