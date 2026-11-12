import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/services/ads/ad_configuration.dart';
import 'package:pilogy_app/services/ads/ad_consent_service.dart';
import 'package:pilogy_app/services/ads/ad_gateway.dart';
import 'package:pilogy_app/services/ads/ad_mob_service.dart';
import 'package:pilogy_app/services/ads/ad_providers.dart';
import 'package:pilogy_app/services/ads/inline_ad_controller.dart';
import 'package:pilogy_app/services/ads/native_content_ad.dart';
import 'ad_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native deduplicates, records SDK impressions, and rejects late loads after withdrawal', () async {
    final sdk = FakeAds();
    final consent = AdConsentService(FakeConsent());
    final analytics = _RecordingAnalytics();
    final service = AdMobService(
      config: configuration(), consent: consent, gateway: sdk, analytics: analytics,
    );
    service.context(screen: 'analysis', calculationBusy: false, dialogOpen: false);
    await service.start(returning: true);
    final controller = InlineAdController(service, format: AdFormat.nativeAdvanced);
    await controller.load(320);
    await controller.load(320);
    expect(sdk.nativeLoads, 1);
    expect(controller.ad, isNotNull);
    expect(analytics.nativeEvents, ['ad_load_requested', 'ad_loaded']);
    sdk.onNativeImpression!();
    expect(analytics.nativeEvents.last, 'ad_displayed');
    controller.setVisible(false);
    expect(controller.ad, isNull);
    expect(sdk.native.disposals, 1);
    sdk.nativeWait = Completer<InlineAdHandle>();
    controller.setVisible(true);
    final pending = controller.load(320);
    consent.allowed = false;
    consent.notifyListeners();
    sdk.nativeWait!.complete(sdk.native);
    await pending;
    expect(controller.ad, isNull);
    expect(sdk.native.disposals, 2);
    controller.dispose();
    service.dispose();
    consent.dispose();
  });

  test('native is excluded from first session, forms, loading and fullscreen preloads', () async {
    final sdk = FakeAds();
    final consent = AdConsentService(FakeConsent());
    final service = AdMobService(config: configuration(), consent: consent, gateway: sdk);
    service.context(screen: 'discover', calculationBusy: false, dialogOpen: false);
    await service.start(returning: false);
    final controller = InlineAdController(service, format: AdFormat.nativeAdvanced);
    await controller.load(320);
    expect(sdk.nativeLoads, 0);
    service.returningUser = true;
    for (final screen in ['profileForm', 'numberDetail', 'settings', 'privacyData']) {
      service.context(screen: screen, calculationBusy: false, dialogOpen: false);
      expect(service.nativeAllowed, isFalse);
    }
    service.context(screen: 'discover', calculationBusy: true, dialogOpen: false);
    expect(service.nativeAllowed, isFalse);
    service.context(screen: 'discover', calculationBusy: false, dialogOpen: true);
    expect(service.nativeAllowed, isFalse);
    service.context(screen: 'discover', calculationBusy: false, dialogOpen: false);
    service.policy.presenting = true;
    expect(service.nativeAllowed, isFalse);
    service.policy.presenting = false;
    await service.preload(AdFormat.nativeAdvanced);
    expect(sdk.loads.containsKey(AdFormat.nativeAdvanced), isFalse);
    controller.dispose();
    service.dispose();
    consent.dispose();
  });

  testWidgets('native template is labelled, sized, and collapses at narrow widths', (tester) async {
    final sdk = FakeAds();
    final consent = AdConsentService(FakeConsent());
    final service = AdMobService(config: configuration(), consent: consent, gateway: sdk);
    service.context(screen: 'discover', calculationBusy: false, dialogOpen: false);
    await service.start(returning: true);
    final width = ValueNotifier<double>(360);
    await tester.pumpWidget(ProviderScope(
      overrides: [adMobServiceProvider.overrideWith((ref) => service)],
      child: MaterialApp(home: Scaffold(body: Center(
        child: ValueListenableBuilder<double>(
          valueListenable: width,
          builder: (context, value, _) => SizedBox(
            width: value, child: const NativeContentAd(),
          ),
        ),
      ))),
    ));
    await tester.pumpAndSettle();
    final creative = find.byKey(const ValueKey('test-native-view'));
    expect(creative, findsOneWidget);
    expect(find.text('Quảng Cáo'), findsOneWidget);
    expect(tester.getSize(creative).height, 140);
    expect(sdk.nativeLoads, 1);
    width.value = 280;
    await tester.pumpAndSettle();
    expect(creative, findsNothing);
    expect(find.text('Quảng Cáo'), findsNothing);
    expect(sdk.native.disposals, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    width.dispose();
    consent.dispose();
  });
}

class _RecordingAnalytics implements AdAnalyticsService {
  final nativeEvents = <String>[];
  @override
  void event(String name, AdFormat format) {
    if (format == AdFormat.nativeAdvanced) nativeEvents.add(name);
  }
}
