import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/services/ads/ad_configuration.dart';
import 'package:pilogy_app/services/ads/ad_consent_service.dart';
import 'package:pilogy_app/services/ads/ad_mob_service.dart';
import 'package:pilogy_app/services/ads/banner_ad_controller.dart';
import 'ad_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeAds sdk;
  late FakeConsent ump;
  late AdConsentService consent;
  late AdMobService service;
  late DateTime now;
  Future<void> start({bool returning = true}) async {
    sdk = FakeAds();
    ump = FakeConsent();
    consent = AdConsentService(ump);
    now = DateTime(2026);
    service = AdMobService(
      config: configuration(),
      consent: consent,
      gateway: sdk,
      now: () => now,
    );
    service.context(
      screen: 'discover',
      calculationBusy: false,
      dialogOpen: false,
    );
    await service.start(returning: returning);
    await Future<void>.delayed(Duration.zero);
  }

  void completeVisit() {
    service.context(
      screen: 'numberDetail',
      calculationBusy: false,
      dialogOpen: false,
    );
    service.beginInterpretation();
    service.interpretationReady();
    now = now.add(const Duration(seconds: 11));
    final visit = service.endInterpretation();
    service.context(
      screen: 'discover',
      calculationBusy: false,
      dialogOpen: false,
    );
    service.finishInterpretation(visit);
  }

  tearDown(() {
    service.dispose();
    consent.dispose();
  });
  test(
    'third completed detail, dismissal and duplicate display coordination',
    () async {
      await start();
      now = now.add(const Duration(minutes: 3));
      completeVisit();
      completeVisit();
      expect(sdk.ads[AdFormat.interstitial]!.shows, 0);
      completeVisit();
      await Future<void>.delayed(Duration.zero);
      expect(sdk.ads[AdFormat.interstitial]!.shows, 1);
      service.paused();
      now = now.add(const Duration(minutes: 6));
      service.resumed();
      expect(sdk.ads[AdFormat.appOpen]!.shows, 0);
      sdk.ads[AdFormat.interstitial]!.close!();
      sdk.ads[AdFormat.interstitial]!.close!();
      expect(service.policy.presenting, isFalse);
      expect(service.policy.canPresent, isFalse);
    },
  );
  test(
    'first experience, failed/short visits and unsafe screens are excluded',
    () async {
      await start(returning: false);
      now = now.add(const Duration(minutes: 10));
      completeVisit();
      completeVisit();
      completeVisit();
      expect(sdk.loads, isEmpty);
      expect(service.policy.actions, 0);
    },
  );
  test(
    'short background skipped, long background shown once, reading blocked',
    () async {
      await start();
      service.paused();
      now = now.add(const Duration(minutes: 1));
      service.resumed();
      expect(sdk.ads[AdFormat.appOpen]!.shows, 0);
      service.paused();
      now = now.add(const Duration(minutes: 5));
      service.resumed();
      service.resumed();
      await Future<void>.delayed(Duration.zero);
      expect(sdk.ads[AdFormat.appOpen]!.shows, 1);
      sdk.ads[AdFormat.appOpen]!.close!();
      service.context(
        screen: 'numberDetail',
        calculationBusy: false,
        dialogOpen: false,
      );
      service.paused();
      now = now.add(const Duration(minutes: 6));
      service.resumed();
      expect(sdk.ads[AdFormat.appOpen]!.shows, 1);
    },
  );
  test(
    'preload is deduplicated and expired app-open skips the resume',
    () async {
      await start();
      await Future.wait([
        service.preload(AdFormat.appOpen),
        service.preload(AdFormat.appOpen),
      ]);
      expect(sdk.loads[AdFormat.appOpen], 1);
      service.paused();
      now = now.add(const Duration(hours: 5));
      service.resumed();
      await Future<void>.delayed(Duration.zero);
      expect(sdk.ads[AdFormat.appOpen]!.shows, 0);
      expect(sdk.ads[AdFormat.appOpen]!.disposals, 1);
      expect(service.policy.presenting, isFalse);
    },
  );
  test(
    'unloaded/short detail and dialog transitions do not count or show',
    () async {
      await start();
      now = now.add(const Duration(minutes: 3));
      service.beginInterpretation();
      expect(service.endInterpretation(), isNull);
      service.context(
        screen: 'numberDetail',
        calculationBusy: false,
        dialogOpen: false,
      );
      service.beginInterpretation();
      service.interpretationReady();
      expect(service.endInterpretation(), isNull);
      expect(service.policy.actions, 0);
      service.context(
        screen: 'discover',
        calculationBusy: false,
        dialogOpen: true,
      );
      service.paused();
      now = now.add(const Duration(minutes: 6));
      service.resumed();
      expect(service.policy.presenting, isFalse);
    },
  );
  test(
    'show failure releases coordination without consuming action count',
    () async {
      await start();
      sdk.ads[AdFormat.interstitial]!.fail = true;
      now = now.add(const Duration(minutes: 3));
      completeVisit();
      completeVisit();
      completeVisit();
      await Future<void>.delayed(Duration.zero);
      expect(service.policy.presenting, isFalse);
      expect(service.policy.actions, 3);
      expect(sdk.ads[AdFormat.interstitial]!.disposals, 1);
    },
  );
  test(
    'unavailable ad never blocks completion and retries are bounded',
    () async {
      await start();
      sdk.ads[AdFormat.interstitial]!.close = null;
      consent.allowed = false;
      consent.notifyListeners();
      sdk.fail = true;
      consent.allowed = true;
      consent.notifyListeners();
      await Future<void>.delayed(Duration.zero);
      now = now.add(const Duration(minutes: 3));
      completeVisit();
      completeVisit();
      completeVisit();
      expect(service.policy.presenting, isFalse);
    },
  );
  test(
    'banner creates once, failure collapses and late load is disposed',
    () async {
      await start();
      final banner = BannerAdController(service);
      await banner.load(320);
      await banner.load(320);
      expect(sdk.bannerLoads, 1);
      expect(banner.ad, isNotNull);
      banner.dispose();
      expect(sdk.banner.disposals, 1);
      sdk.bannerWait = Completer();
      final pendingBanner = BannerAdController(service);
      final pending = pendingBanner.load(360);
      pendingBanner.dispose();
      sdk.bannerWait!.complete(sdk.banner);
      await pending;
      expect(sdk.banner.disposals, 2);
      sdk.bannerWait = null;
      sdk.fail = true;
      final failing = BannerAdController(service);
      await failing.load(320);
      await failing.load(320);
      expect(failing.ad, isNull);
      expect(sdk.bannerLoads, 3);
      failing.dispose();
    },
  );
  test('banners cover all routes without calculation gating; fullscreen stays restricted', () async {
    await start();
    for (final screen in AdMobService.bannerScreens) {
      service.context(screen: screen, calculationBusy: true, dialogOpen: false);
      expect(service.bannerAllowed, isTrue, reason: screen);
      expect(service.safeOverview, isFalse);
      service.context(screen: screen, calculationBusy: false, dialogOpen: false);
      expect(service.safeOverview, screen == 'discover' || screen == 'analysis');
    }
    service.context(screen: 'startup', calculationBusy: false, dialogOpen: false);
    expect(service.bannerAllowed, isFalse);
    service.context(screen: 'settings', calculationBusy: false, dialogOpen: true);
    expect(service.bannerAllowed, isFalse);
    service.context(screen: 'settings', calculationBusy: false, dialogOpen: false);
    service.policy.presenting = true;
    expect(service.bannerAllowed, isFalse);
    service.policy.presenting = false;
    service.inactive();
    expect(service.bannerAllowed, isFalse);
    service.resumed();
    consent.allowed = false;
    consent.notifyListeners();
    expect(service.bannerAllowed, isFalse);
  });
  test('first session stays banner-free on every route', () async {
    await start(returning: false);
    for (final screen in AdMobService.bannerScreens) {
      service.context(screen: screen, calculationBusy: false, dialogOpen: false);
      expect(service.bannerAllowed, isFalse, reason: screen);
    }
  });
  test('advertiser return skips App Open once, next ordinary return can show', () async {
    await start();
    sdk.onAdClicked!();
    service.paused();
    now = now.add(const Duration(minutes: 6));
    service.resumed();
    expect(sdk.ads[AdFormat.appOpen]!.shows, 0);
    service.paused();
    now = now.add(const Duration(minutes: 6));
    service.resumed();
    await Future<void>.delayed(Duration.zero);
    expect(sdk.ads[AdFormat.appOpen]!.shows, 1);
  });
  test('expired cached ads are replaced during preload without late display', () async {
    await start();
    now = now.add(const Duration(hours: 5));
    await service.preload(AdFormat.appOpen);
    expect(sdk.loads[AdFormat.appOpen], 2);
    expect(sdk.ads[AdFormat.appOpen]!.disposals, 1);
    expect(sdk.ads[AdFormat.appOpen]!.shows, 0);
  });
  testWidgets('banner retries twice with backoff, stops while hidden and after cap', (tester) async {
    await tester.runAsync(() => start());
    sdk.fail = true;
    final banner = BannerAdController(service);
    await banner.load(320);
    expect(sdk.bannerLoads, 1);
    await tester.pump(const Duration(seconds: 29));
    expect(sdk.bannerLoads, 1);
    banner.setVisible(false);
    await tester.pump(const Duration(seconds: 1));
    expect(sdk.bannerLoads, 1);
    banner.setVisible(true);
    await banner.load(320);
    expect(sdk.bannerLoads, 2);
    await tester.pump(const Duration(seconds: 119));
    expect(sdk.bannerLoads, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(sdk.bannerLoads, 3);
    await tester.pump(const Duration(minutes: 10));
    await banner.load(320);
    expect(sdk.bannerLoads, 3);
    banner.dispose();
  });
  test('consent flow and calculation block resumed ads', () async {
    await start();
    consent.busy = true;
    consent.notifyListeners();
    service.paused();
    now = now.add(const Duration(minutes: 10));
    service.resumed();
    expect(service.policy.presenting, isFalse);
    consent.busy = false;
    consent.notifyListeners();
    service.context(
      screen: 'discover',
      calculationBusy: true,
      dialogOpen: false,
    );
    service.paused();
    now = now.add(const Duration(minutes: 10));
    service.resumed();
    expect(service.policy.presenting, isFalse);
  });
}
