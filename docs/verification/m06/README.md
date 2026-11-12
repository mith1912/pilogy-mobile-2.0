# M06 completion and verification record

Overall: PARTIAL. Executable verification: BLOCKED. No native ad serving, consent UI, screenshots, revenue, or SDK installation is claimed.

| Area | Status | Result |
| --- | --- | --- |
| Preserved assets/metadata | IMPLEMENTED_AND_TESTED | Python checks: 70 protected files unchanged; native IDs/portrait/Firebase/design/8 routes/imports/SQLite constraints pass |
| Dependency | BLOCKED | google_mobile_ads 6.0.0 declared; requires Flutter >=3.27/Dart >=3.6; installed configuration remains 3.13.9/3.1.5 |
| Android preparation | IMPLEMENTED_NOT_DEVICE_VERIFIED | Source-derived manifest App ID, measurement delay, min23/compile35, AGP8.6.1/Gradle8.7/JDK17 target; no ID changes |
| iOS preparation | IMPLEMENTED_NOT_DEVICE_VERIFIED | Source-derived GADApplicationIdentifier, measurement delay, target13, 50 SKAdNetwork entries, existing icons/Firebase preserved |
| Banner | IMPLEMENTED_NOT_DEVICE_VERIFIED | Discover footer only, adaptive width, no persistent failure slot, controller disposal/rebuild guards |
| Interstitial | IMPLEMENTED_NOT_DEVICE_VERIFIED | Every third loaded/read/completed detail return, 120-second startup/cooldown floors, single-use handles, post-transition and safe-route checks |
| App Open | IMPLEMENTED_NOT_DEVICE_VERIFIED | Returning-user resume after >=5 minutes background, shared lock/cooldown, four-hour expiry; protected startup skipped |
| UMP | IMPLEMENTED_NOT_DEVICE_VERIFIED | One updated consent flow per enabled launch, fail closed, required Settings privacy action, no local fabricated consent |
| Analytics | PARTIAL | Fixed-event Firebase bridge deny-gated; Analytics collection remains disabled pending an independent consent choice; no revenue reporting |
| Dart tests/builds | BLOCKED | All six commands SIGABRT (-6; shell134) before initialization at cpuinfo_macos.cc:42 |
| Production configuration | BLOCKED | iOS banner source invalid; both App Open source IDs absent; published UMP messages/store/privacy configuration unverified |

Commands and exit statuses: commands.json. Corresponding stdout/stderr logs are adjacent. Delimiter balance is a source-only script and does not prove valid Dart or passing analysis. Existing APK artifacts are not M06 outputs.

## Files added

- lib/services/ads/ad_configuration.dart
- lib/services/ads/ad_consent_service.dart
- lib/services/ads/ad_frequency_policy.dart
- lib/services/ads/ad_gateway.dart
- lib/services/ads/google_ads_gateway.dart
- lib/services/ads/ad_mob_service.dart
- lib/services/ads/banner_ad_controller.dart
- lib/services/ads/ad_providers.dart
- lib/services/ads/ad_navigation_observer.dart
- lib/services/ads/ad_runtime.dart
- lib/services/ads/ad_banner.dart
- lib/services/ads/ad_analytics.dart
- test/ads/ad_test_support.dart
- test/ads/ad_configuration_test.dart
- test/ads/ad_consent_test.dart
- test/ads/ad_frequency_test.dart
- test/ads/ad_service_test.dart
- test/ads/ad_analytics_test.dart
- scripts/sync_admob_config.py
- scripts/verify_admob.py
- docs/admob-integration.md
- docs/ad-placement.md
- docs/ad-frequency-policy.md
- docs/ad-consent.md
- docs/admob-testing.md
- docs/privacy-review.md
- docs/verification/m06/*

## Existing files modified

pubspec.yaml; lib/main.dart; lib/app/app.dart; lib/app/router.dart; lib/core/design_system/app_theme.dart; lib/services/firebase/firebase_bootstrap.dart; lib/features/discover/presentation/discover_screen.dart; lib/features/number_detail/presentation/number_detail_screen.dart; lib/features/settings/presentation/settings_screen.dart; android/settings.gradle; android/build.gradle; android/app/build.gradle; android/gradle/wrapper/gradle-wrapper.properties; android/app/src/main/AndroidManifest.xml; ios/Podfile; ios/Runner/Info.plist; ios/Runner.xcodeproj/project.pbxproj; README.md; AGENTS.md.

No backend/model/cache schema/profile storage or approved numerology content was modified. Original config, native Firebase files and launcher artwork remain unchanged. M07 is not started.
