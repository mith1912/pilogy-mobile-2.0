import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/services/ads/ad_configuration.dart';
import 'ad_test_support.dart';

void main() {
  test(
    'supplied config maps each platform and rejects app IDs used as units',
    () {
      final source = File('config/ads_util.dart').readAsStringSync();
      final android = AdSourceIdentifiers.parse(source, TargetPlatform.android);
      final ios = AdSourceIdentifiers.parse(source, TargetPlatform.iOS);
      expect(AdConfiguration.validApp(android.appId), isTrue);
      expect(AdConfiguration.validApp(ios.appId), isTrue);
      expect(android.appId, isNot(ios.appId));
      expect(AdConfiguration.validUnit(android.units[AdFormat.banner]), isTrue);
      expect(AdConfiguration.validUnit(ios.units[AdFormat.banner]), isTrue);
      expect(
        AdConfiguration.validUnit(ios.units[AdFormat.interstitial]),
        isTrue,
      );
      for (final ids in [android, ios]) {
        expect(AdConfiguration.validUnit(ids.customUnit), isTrue);
        expect(ids.units[AdFormat.nativeAdvanced], ids.customUnit);
        expect(AdConfiguration.validUnit(ids.units[AdFormat.appOpen]), isTrue);
        final production = AdConfiguration(
          platform: identical(ids, android) ? TargetPlatform.android : TargetPlatform.iOS,
          appId: ids.appId,
          productionUnits: ids.units,
          enabled: true,
          release: true,
          testAds: false,
          productionReady: true,
        );
        expect(production.unit(AdFormat.appOpen), ids.units[AdFormat.appOpen]);
        expect(production.unit(AdFormat.nativeAdvanced), ids.customUnit);
      }
    },
  );
  test('App Open field aliases are parsed with canonical name precedence', () {
    final sample = configuration().unit(AdFormat.appOpen)!;
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      final prefix = platform == TargetPlatform.android ? '_android' : '_ios';
      for (final suffix in ['AppOpenId', 'AdOpenId', 'AdOpen']) {
        final ids = AdSourceIdentifiers.parse(
          'static const String $prefix$suffix = "$sample";', platform,
        );
        expect(ids.units[AdFormat.appOpen], sample);
      }
      final ids = AdSourceIdentifiers.parse(
        'static const String ${prefix}AppOpenId = "invalid";'
        'static const String ${prefix}AdOpenId = "$sample";', platform,
      );
      expect(ids.units[AdFormat.appOpen], 'invalid');
    }
  });
  test('off by default, formats and unsupported platforms stay off', () {
    expect(configuration(enabled: false).unit(AdFormat.banner), isNull);
    expect(
      configuration(platform: TargetPlatform.macOS).unit(AdFormat.banner),
      isNull,
    );
    final c = AdConfiguration(
      platform: TargetPlatform.android,
      appId: configuration().appId,
      productionUnits: const {},
      enabled: true,
      banner: false,
    );
    expect(c.unit(AdFormat.banner), isNull);
  });
  test('native switch and production readiness gate requests', () {
    final disabled = AdConfiguration(
      platform: TargetPlatform.android, appId: configuration().appId,
      productionUnits: const {}, enabled: true, nativeAds: false,
    );
    expect(disabled.unit(AdFormat.nativeAdvanced), isNull);
    expect(configuration(enabled: false).unit(AdFormat.nativeAdvanced), isNull);
    expect(configuration(release: true, testAds: false).unit(AdFormat.nativeAdvanced), isNull);
  });
  test('Debug ignores production override and uses platform test mapping', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      final c = configuration(platform: platform, testAds: false, ready: true);
      for (final format in AdFormat.values) {
        expect(c.unit(format), startsWith('ca-app-pub-3940256099942544/'));
      }
    }
    expect(
      configuration().unit(AdFormat.banner),
      isNot(configuration(platform: TargetPlatform.iOS).unit(AdFormat.banner)),
    );
  });
  test('release requires readiness and a real unit-shaped value', () {
    expect(
      configuration(release: true, testAds: false).unit(AdFormat.interstitial),
      isNull,
    );
    expect(
      configuration(
        release: true,
        testAds: false,
        ready: true,
        units: {AdFormat.banner: configuration().appId},
      ).unit(AdFormat.banner),
      isNull,
    );
    final sample = configuration().unit(AdFormat.interstitial)!;
    expect(
      configuration(
        release: true,
        testAds: false,
        ready: true,
        units: {AdFormat.interstitial: sample},
      ).unit(AdFormat.interstitial),
      sample,
    );
    expect(
      configuration(
        release: true,
        testAds: false,
        ready: true,
      ).unit(AdFormat.appOpen),
      isNull,
    );
  });
}
