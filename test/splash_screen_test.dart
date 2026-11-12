import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pilogy_app/features/profiles/data/local_profile_repository.dart';
import 'profile_components_test.dart' show FakeProfileRepository;
import 'package:pilogy_app/app/launch.dart';
import 'package:pilogy_app/app/startup.dart';
import 'package:pilogy_app/core/design_system/app_theme.dart';
import 'package:pilogy_app/features/profiles/domain/profile_repository.dart';
import 'package:pilogy_app/features/splash/presentation/splash_screen.dart';
import 'package:pilogy_app/services/ads/ad_configuration.dart';
import 'package:pilogy_app/services/firebase/firebase_bootstrap.dart';

void main() {
  Widget host(Widget child) => MaterialApp(theme: AppTheme.light(useGoogleFonts: false), home: child);

  testWidgets('splash shows branding and decorative digits at narrow width and large text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(host(const SplashScreen()));
    await tester.pump(const Duration(milliseconds: 280));
    expect(find.text('PILOGY'), findsOneWidget);
    expect(find.text('NUMEROLOGY & SELF-DISCOVERY'), findsOneWidget);
    expect(find.text('Hiệu chuẩn biểu đồ kim tự tháp...'), findsNothing);
    await tester.ensureVisible(find.text('PILOGY • CHUẨN MỰC CHIÊM NGHIỆM'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('startup failure offers retry and no endless loading indicator', (tester) async {
    var retries = 0;
    await tester.pumpWidget(host(SplashScreen(error: 'Không thể mở dữ liệu trên thiết bị.', onRetry: () => retries++)));
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.ensureVisible(find.text('Thử Lại'));
    await tester.tap(find.text('Thử Lại'));
    expect(retries, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('splash covers services and local bootstrap, then opens the existing welcome route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final services = Completer<LaunchServices>();
    final local = Completer<ProfileSnapshot>();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
        launchServicesProvider.overrideWith((ref) => services.future),
        startupProvider.overrideWith((ref) => local.future),
      ],
      child: const PilogyLaunch(useGoogleFonts: false),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('startup-splash')), findsOneWidget);
    services.complete(LaunchServices(AdConfiguration.environment(), FirebaseStartupStatus.unsupportedPlatform));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('startup-splash')), findsOneWidget);
    local.complete(const ProfileSnapshot([], null));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('startup-splash')), findsNothing);
    expect(find.byKey(const ValueKey('screen-V01')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
