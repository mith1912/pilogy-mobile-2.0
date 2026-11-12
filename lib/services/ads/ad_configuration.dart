import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AdFormat { banner, interstitial, appOpen, nativeAdvanced }

/// Supplied production IDs remain in config/ads_util.dart. Missing formats stay
/// null; in particular an App ID is never accepted as an ad unit ID.
class AdConfiguration {
  const AdConfiguration({
    required this.platform,
    required this.appId,
    required this.productionUnits,
    this.enabled = false,
    this.release = false,
    this.testAds = true,
    this.productionReady = false,
    this.banner = true,
    this.interstitial = true,
    this.appOpen = true,
    this.nativeAds = true,
    this.actionThreshold = 3,
    this.fullscreenSessionCap = 6,
    this.fullscreenCooldown = const Duration(seconds: 120),
    this.appOpenCooldown = const Duration(minutes: 5),
    this.backgroundMinimum = const Duration(minutes: 5),
  });
  static Future<AdConfiguration> load() async {
    if (!const bool.fromEnvironment('ADS_ENABLED'))
      return AdConfiguration.environment();
    try {
      final source = await rootBundle
          .loadString('config/ads_util.dart')
          .timeout(const Duration(seconds: 2));
      return AdConfiguration.environment(source: source);
    } catch (_) {
      return AdConfiguration.environment();
    }
  }

  factory AdConfiguration.environment({String source = ''}) {
    final ids = AdSourceIdentifiers.parse(source, defaultTargetPlatform);
    return AdConfiguration(
      platform: defaultTargetPlatform,
      appId: ids.appId,
      productionUnits: ids.units,
      enabled: const bool.fromEnvironment('ADS_ENABLED'),
      release: kReleaseMode,
      testAds: const bool.fromEnvironment(
        'ADS_USE_TEST_ADS',
        defaultValue: true,
      ),
      productionReady: const bool.fromEnvironment('ADS_PRODUCTION_READY'),
      banner: const bool.fromEnvironment(
        'ADS_BANNER_ENABLED',
        defaultValue: true,
      ),
      interstitial: const bool.fromEnvironment(
        'ADS_INTERSTITIAL_ENABLED',
        defaultValue: true,
      ),
      appOpen: const bool.fromEnvironment(
        'ADS_APP_OPEN_ENABLED',
        defaultValue: true,
      ),
      nativeAds: const bool.fromEnvironment('ADS_NATIVE_ENABLED', defaultValue: true),
      actionThreshold: const int.fromEnvironment(
        'ADS_ACTION_THRESHOLD',
        defaultValue: 3,
      ),
      fullscreenSessionCap: const int.fromEnvironment(
        'ADS_FULLSCREEN_SESSION_CAP',
        defaultValue: 6,
      ),
      backgroundMinimum: Duration(
        seconds: const int.fromEnvironment(
          'ADS_BACKGROUND_MINIMUM_SECONDS',
          defaultValue: 300,
        ).clamp(60, 86400).toInt(),
      ),
      fullscreenCooldown: Duration(
        seconds: const int.fromEnvironment(
          'ADS_FULLSCREEN_COOLDOWN_SECONDS',
          defaultValue: 120,
        ),
      ),
      appOpenCooldown: Duration(
        seconds: const int.fromEnvironment(
          'ADS_APP_OPEN_COOLDOWN_SECONDS',
          defaultValue: 300,
        ),
      ),
    );
  }
  final TargetPlatform platform;
  final String appId;
  final Map<AdFormat, String?> productionUnits;
  final bool enabled,
      release,
      testAds,
      productionReady,
      banner,
      interstitial,
      appOpen,
      nativeAds;
  final int actionThreshold, fullscreenSessionCap;
  final Duration fullscreenCooldown, appOpenCooldown, backgroundMinimum;
  bool get supported =>
      !kIsWeb &&
      (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
  bool get testing => !release || testAds;
  static bool validApp(String value) =>
      RegExp(r'^ca-app-pub-\d{16}~\d{10}$').hasMatch(value);
  static bool validUnit(String? value) =>
      value != null && RegExp(r'^ca-app-pub-\d{16}/\d{10}$').hasMatch(value);
  String? unit(AdFormat format) {
    if (!enabled ||
        !supported ||
        !validApp(appId) ||
        !(switch (format) {
          AdFormat.banner => banner,
          AdFormat.interstitial => interstitial,
          AdFormat.appOpen => appOpen,
          AdFormat.nativeAdvanced => nativeAds,
        }))
      return null;
    if (testing)
      return (platform == TargetPlatform.iOS
          ? _iosTests
          : _androidTests)[format];
    final id = productionUnits[format];
    return productionReady && validUnit(id) ? id : null;
  }

  // Official dedicated test units; never use supplied production units in Debug/Profile.
  static const _androidTests = {
    AdFormat.banner: 'ca-app-pub-3940256099942544/6300978111',
    AdFormat.interstitial: 'ca-app-pub-3940256099942544/1033173712',
    AdFormat.appOpen: 'ca-app-pub-3940256099942544/9257395921',
    AdFormat.nativeAdvanced: 'ca-app-pub-3940256099942544/2247696110',
  };
  static const _iosTests = {
    AdFormat.banner: 'ca-app-pub-3940256099942544/2934735716',
    AdFormat.interstitial: 'ca-app-pub-3940256099942544/4411468910',
    AdFormat.appOpen: 'ca-app-pub-3940256099942544/5575463023',
    AdFormat.nativeAdvanced: 'ca-app-pub-3940256099942544/3986624511',
  };
}

/// Reads only named literal constants from the preserved reference asset. Dart
/// source is never evaluated. Native app IDs are derived from the same file.
class AdSourceIdentifiers {
  const AdSourceIdentifiers(this.appId, this.units, {this.customUnit});
  final String appId;
  final Map<AdFormat, String?> units;

  /// User confirmed both customAd units are Native Advanced.
  final String? customUnit;
  static AdSourceIdentifiers parse(String source, TargetPlatform platform) {
    final values = <String, String>{};
    final pattern = RegExp(r'static const String (_\w+)\s*=\s*"([^"]+)"');
    for (final match in pattern.allMatches(source)) {
      values[match[1]!] = match[2]!;
    }
    final prefix = platform == TargetPlatform.iOS ? '_ios' : '_android';
    return AdSourceIdentifiers(values['${prefix}AppId'] ?? '', {
      AdFormat.banner: values['${prefix}BannerId'],
      AdFormat.nativeAdvanced: values['${prefix}CustomAdId'],
      AdFormat.interstitial: values['${prefix}InterstitialId'],
      AdFormat.appOpen:
          values['${prefix}AppOpenId'] ??
          values['${prefix}AdOpenId'] ??
          values['${prefix}AdOpen'],
    }, customUnit: values['${prefix}CustomAdId']);
  }
}
