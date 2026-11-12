import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/app/router.dart';
import 'package:pilogy_app/app/startup.dart';
import 'package:pilogy_app/features/profiles/domain/profile_repository.dart';
import 'package:pilogy_app/services/ads/ad_analytics.dart';
import 'package:pilogy_app/services/ads/ad_navigation_observer.dart';
import 'package:pilogy_app/services/ads/ad_providers.dart';
import 'package:pilogy_app/services/firebase/firebase_bootstrap.dart';

import 'ad_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('launch scope resolves configuration, Analytics, service and router together', () async {
    final gateway = FakeAds();
    final root = ProviderContainer(overrides: [
      adGatewayProvider.overrideWithValue(gateway),
      consentGatewayProvider.overrideWithValue(FakeConsent()),
      startupProvider.overrideWith((ref) async => const ProfileSnapshot([], null)),
    ]);
    final parentConfig = root.read(adConfigurationProvider);
    final parentService = root.read(adMobServiceProvider);
    final parentAnalytics = root.read(adAnalyticsProvider);
    await root.read(startupProvider.future);
    final parentRouter = root.read(routerProvider);
    final config = configuration(enabled: false, release: true, testAds: false);
    final child = ProviderContainer(parent: root, overrides: [
      adConfigurationProvider.overrideWithValue(config),
      firebaseStartupStatusProvider.overrideWithValue(FirebaseStartupStatus.ready),
    ]);
    try {
      final service = child.read(adMobServiceProvider);
      final analytics = child.read(adAnalyticsProvider) as FirebaseAdAnalytics;
      final router = child.read(routerProvider);
      expect(service, isNot(same(parentService)));
      expect(service.config, same(config));
      expect(service.analytics, same(analytics));
      expect(analytics, isNot(same(parentAnalytics)));
      expect(analytics.testing, isFalse);
      expect(analytics.canLog(), isFalse);
      expect(router, isNot(same(parentRouter)));
      expect(router.routerDelegate.builder.observers.whereType<AdNavigationObserver>().single.service, same(service));
      expect(root.read(adConfigurationProvider), same(parentConfig));
      expect(root.read(adMobServiceProvider), same(parentService));
      expect(gateway.starts, 0);
      expect(gateway.bannerLoads, 0);
      expect(gateway.loads, isEmpty);
    } finally {
      child.dispose();
      root.dispose();
    }
  });

  test('Firebase-only scope relocates deferred Analytics gate and dependent ad service', () {
    final root = ProviderContainer(overrides: [
      adGatewayProvider.overrideWithValue(FakeAds()),
      consentGatewayProvider.overrideWithValue(FakeConsent()),
    ]);
    final parentAnalytics = root.read(adAnalyticsProvider);
    final parentService = root.read(adMobServiceProvider);
    final child = ProviderContainer(parent: root, overrides: [
      firebaseStartupStatusProvider.overrideWithValue(FirebaseStartupStatus.unavailable),
    ]);
    try {
      expect(child.read(adAnalyticsProvider), isNot(same(parentAnalytics)));
      expect(child.read(adMobServiceProvider), isNot(same(parentService)));
      expect(root.read(firebaseStartupStatusProvider), FirebaseStartupStatus.unsupportedPlatform);
    } finally {
      child.dispose();
      root.dispose();
    }
  });
}
