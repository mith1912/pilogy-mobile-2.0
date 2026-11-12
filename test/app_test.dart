import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:pilogy_app/app/router.dart';
import 'package:pilogy_app/app/startup.dart';
import 'package:pilogy_app/core/design_system/app_colors.dart';
import 'package:pilogy_app/core/design_system/app_theme.dart';
import 'package:pilogy_app/core/design_system/app_typography.dart';
import 'package:pilogy_app/features/profiles/domain/profile_repository.dart';
import 'package:pilogy_app/features/profiles/domain/user_profile.dart';
import 'package:pilogy_app/features/numerology/domain/api_models.dart';
import 'ui_test_support.dart';

void main() {
  sqfliteFfiInit();
  test('light theme follows the Stitch palette and type scale', () {
    final theme = AppTheme.light(useGoogleFonts: false);
    expect(theme.colorScheme.primary, const Color(0xFF3A2B47));
    expect(theme.scaffoldBackgroundColor, AppColors.surface);
    expect(theme.cardTheme.color, AppColors.surfaceContainerLowest);
    expect(theme.textTheme.bodyMedium?.fontSize, 14);
    expect(theme.textTheme.bodyMedium?.height, 22 / 14);
    expect(theme.textTheme.headlineMedium?.fontSize, 26);
    expect(AppTypography.displayNumeral.fontSize, 64);
    expect(AppTypography.labelSmall.letterSpacing, .66);
  });
  test(
    'startup restores selection or profile list and detail parameters fail safely',
    () {
      final profile = UserProfile(
        id: 'local',
        fullName: 'Synthetic',
        birthDate: '1990-05-20',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(
        initialProfileLocation(const ProfileSnapshot([], null)),
        '/welcome',
      );
      expect(
        initialProfileLocation(ProfileSnapshot([profile], profile)),
        '/discover',
      );
      expect(
        initialProfileLocation(ProfileSnapshot([profile], null)),
        '/profiles',
      );
      expect(parseDetailType('personality'), IndexType.personality);
      expect(parseDetailType('excluded'), isNull);
      final router = createRouter();
      addTearDown(router.dispose);
      expect(router.namedLocation('discover'), '/discover');
      expect(router.namedLocation('analysis'), '/analysis');
      expect(router.namedLocation('profiles'), '/profiles');
      expect(router.namedLocation('profileForm'), '/profile-form');
      expect(router.namedLocation('numberDetail'), '/number-detail');
      expect(router.namedLocation('settings'), '/settings');
      expect(router.namedLocation('privacyData'), '/privacy-data');
      expect(router.namedLocation('welcome'), '/welcome');
    },
  );
  testWidgets('first launch opens V01 from local bootstrap without API calls', (
    tester,
  ) async {
    final h = await UiHarness.open();
    addTearDown(h.close);
    await tester.pumpWidget(h.app);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-V01')), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome-start')), findsOneWidget);
    expect(h.adapter.requests, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
