# M06 AdMob integration

Status: PARTIAL; source is IMPLEMENTED_NOT_DEVICE_VERIFIED. Package resolution, compilation, tests, and device ad serving are BLOCKED here.

## Dependency decision

`google_mobile_ads: 6.0.0` is declared, not successfully installed. Its published constraints require Flutter >=3.27.0 and Dart >=3.6.0. Its native dependencies are Android GMA 24.1.0 / UMP 3.2.0 and iOS GMA ~12.2.0. These native major versions remain supported at the 2026-11-09 review. Version 9.2.0 is newer but requires Dart >=3.10; it was not selected blindly. The configured local SDK remains Flutter 3.13.9/Dart 3.1.5 and crashes before initialization. There is no maintained solution compatible with that old SDK: v4 has sunset native dependencies, while v5's transitive WebView dependencies already require newer Flutter.

The project now declares the minimum supported SDK for v6. This is a required migration target, not evidence the SDK was installed. Restore/upgrade the local Flutter SDK before building. Android was prepared for compileSdk 35, minSdk 23, AGP 8.6.1, Gradle 8.7 and Kotlin 1.9.24 (JDK 17 required). The modern Flutter plugin loader replaces removed imperative loading. iOS targets 13.0. CardThemeData and SDK-pinned path/characters constraints were adjusted. Existing lockfiles remain unregenerated; do not treat them as a resolved M06 dependency graph.

## Single configuration source

`config/ads_util.dart` remains byte-for-byte unchanged. It is bundled as an asset and `AdSourceIdentifiers` reads only named literal constants; it never evaluates Dart source. `main` loads the small asset with a bounded timeout, then overrides `adConfigurationProvider`. Test/screenshot app hosts default to an unconfigured disabled provider. IDs never enter feature widgets or telemetry. The App Open parser accepts `AppOpenId`, `AdOpenId`, then `AdOpen` field suffixes in that order to support the supplied platform-specific names.

Android Gradle derives its manifest App ID from that source at build time. `scripts/sync_admob_config.py` projects only the iOS App ID into Info.plist; rerun when the source changes. That native field is a derived build projection, not a second editable authority. `scripts/verify_admob.py` checks it against the source without printing IDs.

| Supplied field | Android | iOS |
| --- | --- | --- |
| App ID (`~`) | Valid shape | Valid shape |
| Banner unit (`/`) | Valid shape | Valid shape; corrected to supplied iOS banner |
| Interstitial unit (`/`) | Valid shape | Valid shape |
| App Open unit | Valid shape (`_androidAdOpen`) | Valid shape (`_iosAdOpenId`) |
| Native Advanced (`customAd`) | Valid shape | Valid shape |

Shape checks do not prove account ownership, approval or serving. All three implemented formats now have supplied unit-shaped identifiers on both platforms. App Open units are now mapped on both platforms, subject to the existing production-readiness, consent and lifecycle gates. Debug test units allow those formats to be exercised without inventing production identifiers.

## Architecture

`lib/services/ads/`: configuration, UMP service, injectable consent/SDK gateways, Google SDK adapter, banner controller/widget, session frequency policy, shared full-screen coordinator (`AdMobService`), navigation observer, lifecycle runtime, Riverpod providers and optional Firebase event bridge. Widgets never construct SDK ad objects. Core routes never await consent, initialization, loading or display. Banner/ad instances are disposed on failure, withdrawal, stale callbacks, replacement and controller disposal.

## Build flags

Default: ADS_ENABLED=false, ADS_USE_TEST_ADS=true, ADS_PRODUCTION_READY=false. Banner/interstitial/app-open flags default true but have no effect until ads and consent permit requests. ADS_ACTION_THRESHOLD defaults 3, ADS_FULLSCREEN_COOLDOWN_SECONDS 120, ADS_APP_OPEN_COOLDOWN_SECONDS 300. The shared cooldown has a 120-second minimum. ADS_FULLSCREEN_SESSION_CAP defaults to 6 confirmed fullscreen displays per process session. ADS_BACKGROUND_MINIMUM_SECONDS defaults to 300, with environment values clamped to 60–86400 seconds. The user confirmed customAd as Native Advanced; ADS_NATIVE_ENABLED defaults true behind existing ads/consent/readiness gates, using one small template on Discover and Analysis. See [the current monetization plan](ad-monetization-plan.md). Debug AND Profile always use official test units even if ADS_USE_TEST_ADS=false.

For test builds after SDK recovery: `flutter run --dart-define=ADS_ENABLED=true`. For screenshots/default unit tests use ADS_ENABLED=false. Production requires release mode, ADS_ENABLED=true, ADS_USE_TEST_ADS=false, ADS_PRODUCTION_READY=true, valid supplied units and an eligible UMP state. Do not enable production readiness before completing the checklist in admob-testing.md.

## Sources checked

- [v6 package constraints](https://github.com/googleads/googleads-mobile-flutter/blob/v6.0.0/packages/google_mobile_ads/pubspec.yaml)
- [v6 native Android dependencies](https://github.com/googleads/googleads-mobile-flutter/blob/v6.0.0/packages/google_mobile_ads/android/build.gradle)
- [Android SDK support schedule](https://developers.google.com/admob/android/deprecation), [iOS SDK schedule](https://developers.google.com/admob/ios/deprecation)
- [Official UMP guide](https://developers.google.com/admob/flutter/privacy)
- [Official test units](https://developers.google.com/admob/flutter/test-ads)
