import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pilogy_app/services/ads/ad_configuration.dart';
import 'package:pilogy_app/services/ads/ad_consent_service.dart';
import 'package:pilogy_app/services/ads/ad_gateway.dart';

AdConfiguration configuration({
  bool enabled = true,
  bool release = false,
  bool testAds = true,
  bool ready = false,
  int fullscreenSessionCap = 6,
  Duration backgroundMinimum = const Duration(minutes: 5),
  TargetPlatform platform = TargetPlatform.android,
  Map<AdFormat, String?> units = const {},
}) => AdConfiguration(
  platform: platform,
  // Official sample App ID, not a fabricated production identifier.
  appId: 'ca-app-pub-3940256099942544~3347511713',
  productionUnits: units,
  enabled: enabled,
  release: release,
  testAds: testAds,
  productionReady: ready,
  fullscreenSessionCap: fullscreenSessionCap,
  backgroundMinimum: backgroundMinimum,
);

class FakeConsent implements ConsentGateway {
  int updates = 0, forms = 0, privacyForms = 0;
  bool allowed = true, required = false, fail = false;
  Completer<void>? wait;
  @override
  Future<void> update() async {
    updates++;
    if (fail) throw StateError('unavailable');
    await wait?.future;
  }

  @override
  Future<void> showRequiredForm() async {
    forms++;
  }

  @override
  Future<bool> canRequestAds() async => allowed;
  @override
  Future<bool> privacyOptionsRequired() async => required;
  @override
  Future<void> showPrivacyOptions() async {
    privacyForms++;
  }
}

class FakeFullscreen implements FullscreenAdHandle {
  int shows = 0, disposals = 0;
  bool fail = false;
  VoidCallback? close;
  @override
  Future<void> show({
    required VoidCallback onShown,
    required VoidCallback onClosed,
    required VoidCallback onFailed,
  }) async {
    shows++;
    close = onClosed;
    if (fail) {
      onFailed();
    } else {
      onShown();
    }
  }

  @override
  Future<void> dispose() async {
    disposals++;
  }
}

class FakeBanner implements BannerAdHandle {
  int disposals = 0;
  @override
  int get width => 320;
  @override
  int get height => 50;
  @override
  Widget view() => const SizedBox(key: ValueKey('test-banner-view'));
  @override
  Future<void> dispose() async {
    disposals++;
  }
}

class FakeAds implements AdGateway {
  @override
  VoidCallback? onAdClicked;
  @override
  VoidCallback? onNativeImpression;
  int nativeLoads = 0;
  final native = FakeNative();
  Completer<InlineAdHandle>? nativeWait;
  int starts = 0, bannerLoads = 0;
  final Map<AdFormat, FakeFullscreen> ads = {};
  final Map<AdFormat, int> loads = {};
  bool fail = false;
  final banner = FakeBanner();
  Completer<BannerAdHandle>? bannerWait;
  @override
  Future<void> initialize() async {
    starts++;
  }

  @override
  Future<FullscreenAdHandle> loadFullscreen(
    AdFormat format,
    String unit,
  ) async {
    loads[format] = (loads[format] ?? 0) + 1;
    if (fail) throw StateError('no_fill');
    return ads.putIfAbsent(format, FakeFullscreen.new);
  }

  @override
  Future<InlineAdHandle> loadNative(String unit, int width) async {
    nativeLoads++;
    if (fail) throw StateError('no_fill');
    return nativeWait == null ? native : await nativeWait!.future;
  }
  @override
  Future<BannerAdHandle> loadBanner(String unit, int width) async {
    bannerLoads++;
    if (fail) throw StateError('no_fill');
    return bannerWait == null ? banner : await bannerWait!.future;
  }
}

class FakeNative implements InlineAdHandle {
  int disposals = 0;
  @override
  int get width => 320;
  @override
  int get height => 140;
  @override
  Widget view() => const SizedBox(key: ValueKey('test-native-view'));
  @override
  Future<void> dispose() async { disposals++; }
}
