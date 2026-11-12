import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/app/router.dart';
import 'package:pilogy_app/features/profiles/presentation/profiles_view_model.dart';
import 'package:pilogy_app/features/profiles/presentation/widgets/profile_management_cards.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'ui_test_support.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('V08 separates selected profile and persists switching; delete requires confirmation', (tester) async {
    final h = await UiHarness.open();
    addTearDown(h.close);
    final model = h.container.read(profilesViewModelProvider.notifier);
    final first = await model.saveAndSelect(fullName: 'Nguyễn Văn An', birthDate: '1990-05-20');
    await model.saveAndSelect(fullName: 'Lê Thu Trang', birthDate: '1998-11-09');
    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();
    h.container.read(routerProvider).go('/profiles');
    await tester.pumpAndSettle();
    expect(find.byType(SelectedProfileCard), findsOneWidget);
    expect(find.byType(OtherProfileCard), findsOneWidget);
    expect(find.text('Lê Thu Trang'), findsOneWidget);
    expect(find.text('2 Hồ Sơ'), findsOneWidget);
    expect(find.text('DANH SÁCH HỒ SƠ KHÁC (1)'), findsOneWidget);
    expect(find.text('09/11/1998'), findsOneWidget);
    final select = find.byKey(ValueKey('select-profile-${first.id}'));
    await tester.ensureVisible(select);
    await tester.tap(select);
    await tester.pumpAndSettle();
    expect((await model.future).selectedProfile?.id, first.id);
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    final other = find.byType(OtherProfileCard);
    final remove = find.descendant(of: other, matching: find.byTooltip('Xóa Hồ Sơ'));
    await tester.ensureVisible(remove);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect((await model.future).profiles.length, 2);
    await tester.tap(find.text('Hủy Bỏ'));
    await tester.pumpAndSettle();
    expect((await model.future).profiles.length, 2);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa Vĩnh Viễn'));
    await tester.pumpAndSettle();
    expect((await model.future).profiles.length, 1);
    expect((await model.future).selectedProfile?.id, first.id);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('V08 wraps long names and actions on a narrow display with large text', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final h = await UiHarness.open();
    addTearDown(h.close);
    final model = h.container.read(profilesViewModelProvider.notifier);
    await model.saveAndSelect(fullName: 'Nguyễn Thị Minh Anh', birthDate: '1995-08-15');
    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();
    h.container.read(routerProvider).go('/profiles');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Xem Phân Tích'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Nguyễn Thị Minh Anh'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
