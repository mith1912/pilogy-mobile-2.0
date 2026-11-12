# AdMob testing and release gates

Status: BLOCKED for Dart/device checks. All six commands were attempted; the installed Flutter 3.13.9/Dart 3.1.5 VM aborts before initialization at cpuinfo_macos.cc:42 (SIGABRT, subprocess -6 / shell 134). The declared M06 dependency requires Flutter >=3.27/Dart >=3.6, so an SDK upgrade is required independently of that crash. Package 6.0.0 is declared but not resolved/installed; pubspec.lock/Podfile.lock do not prove M06 installation.

Offline scripts: `python3 scripts/verify_admob.py` validates ID classification, native source mapping, delayed measurement, test guards, SKAdNetwork uniqueness and separation from screen widgets. `python3 scripts/verify_foundation.py` checks existing IDs, Firebase/design integrity, eight routes, relative imports and SQLite constraints. These are source/metadata checks, not Dart tests or ad serving.

Tests under test/ads use fake consent/gateway handles and injectable clocks. They cover disabled/config/test-production mapping, invalid/missing units, UMP errors/duplicate initialization/privacy options, third unique visit and cooldown/lock, first-session exclusion, foreground/background eligibility, show failure/dismissal, banner no duplicate creation/failure/late disposal and a deny-gated Analytics bridge. Existing profile/cache/flow suites remain local fixtures. No tests request live ads or click advertisements.

After restoring a supported SDK and JDK 17:

1. Run python3 scripts/sync_admob_config.py and python3 scripts/verify_admob.py.
2. Run flutter pub get, dart format ., flutter analyze and flutter test. Resolve and commit actual dependency/native lockfiles.
3. Build flutter build apk --debug --dart-define=ADS_ENABLED=true and flutter build ios --simulator --dart-define=ADS_ENABLED=true. Test units are enforced in non-release modes.
4. Use an existing returning profile (the first profile-creation session is ad-free). Verify UMP forms and the Settings privacy action. Verify no consent repeatedly appears on navigation/rebuild.
5. Verify the fixed adaptive footer across all eight routes at 360/390/430dp, including scrolling, keyboard visibility and bottom navigation/actions; no blank failure slot, critical CTA overlay, text clipping or navigation obstruction. Do not click ads automatically.
6. Read/exit three successfully loaded V05 visits after the startup grace and check one interstitial, dismissal/show failure, back repetition and navigation continuity. Wait shared cooldown before another full-screen ad.
7. Test brief background, >=5-minute background, system dialogs, consent, forms, loading calculations and V05 reading. App Open may display only at the eligible resume, never after a late load. Check expired-loaded-ad behavior using fake clocks.
8. Verify offline/no-fill/core profile/API/cache flows, rapid switching and background during an ad. Capture Android/iOS screenshots and sanitized callback traces.

Release is blocked until those checks pass, the SDK migration is validated, actual production unit configuration is supplied, published UMP messages/privacy policy and store disclosures are reviewed, signing is configured and a production-device smoke test is recorded. Defaults remain ADS_ENABLED=false, ADS_USE_TEST_ADS=true, ADS_PRODUCTION_READY=false. No live ad serving is claimed. M07 is not started.

## Opt-in device diagnosis (2026-11-10)

Build with `flutter build apk --release --dart-define=ADS_ENABLED=true --dart-define=ADS_USE_TEST_ADS=true --dart-define=ADS_DIAGNOSTICS=true`.
Install/update the generated APK without clearing local data. Force-stop and reopen with an existing selected profile, open any approved screen and inspect the fixed bottom footer (no scrolling required). Run `adb logcat -v brief | grep PILOGY_ADS` before launching, and share only those filtered lines.

Diagnostics are local console output, off by default. They contain fixed gate/stage labels, format names and numeric SDK error codes only; no SDK error messages, ad identifiers, profile information or calculation content. Consent and first-session restrictions remain enforced. Test units still require UMP eligibility. `consent_update_failed`, `consent_form_failed` and `consent_unavailable` identify a consent blocker; `calculation_blocked` identifies unavailable calculation content; `banner_load_error` provides the numeric SDK failure code. No ad request is inferred solely from build success.

The user reports a successful release APK build with test ads enabled. Serving remains unverified. This agent read cached SDK metadata identifying Flutter 3.47.9 / Dart 3.13.7, but Flutter commands for pub get, format, analyze and tests were blocked by SDK cache write permissions. Direct Dart formatting aborted at cpuinfo_macos.cc:42. AdMob Python source checks passed after diagnostics changes; Dart compilation/tests and device logs remain outstanding. Existing dependency versions and lockfiles were not changed.

## Supplied App Open units (2026-11-10)

The user supplied Android `_androidAdOpen` and iOS `_iosAdOpenId` literals. The adapter now accepts these aliases in addition to canonical `AppOpenId` fields; config/ads_util.dart was preserved byte-for-byte during this change. The verifier validates both supplied App Open units and native App ID mappings; it passed. Dart regression coverage now checks the supplied units, production mapping with explicit readiness, alias handling and canonical precedence. Pub get, format, analyze and tests were attempted again and blocked by SDK cache write permissions. No compilation, test success or production ad serving is claimed. Production readiness remains false by default; test builds continue using official test units. Existing resume/frequency rules are unchanged. iOS banners remain unavailable with the current App ID-shaped banner value.

## Inventory and delivery update (2026-11-10)

The user supplied the corrected iOS banner and both customAd units. Current inventory, delivery changes, test experiment, outstanding custom format question and verification limitations are recorded in [ad-monetization-plan.md](ad-monetization-plan.md). This supersedes the earlier iOS-banner-unavailable notes above. Pub get/format/analyze/tests were attempted and blocked by SDK cache permissions; offline AdMob checks passed.

## Native Advanced follow-up (2026-11-10)

The user confirmed the two customAd formats as Native Advanced. Source integration is complete with official small templates, native test-unit mapping and independent ADS_NATIVE_ENABLED flag. Test both platforms with ADS_ENABLED=true and ADS_USE_TEST_ADS=true; verify one labelled template on loaded Discover/Analysis content, 320/360/400dp template widths, narrower collapse, attribution/AdChoices/CTA visibility, no interaction overlays, consent withdrawal, route/background/keyboard disposal, bounded failure retries and advertiser-return suppression. Do not click live ads. Flutter commands remain blocked in the agent environment; no native build/test/serving success is claimed. The user must rebuild to include the change.


## November 12, 2026 delivery investigation

See [the current investigation](admob-delivery-2026-11-12.md) for release-source provenance, exact mappings and actual tool failures. Opt-in diagnostics now include SDK LoadAdError domain, code, message and responseInfo, plus gate/size/load/impression stages; this supersedes the numeric-only description above. These fields stay in the local console, never Analytics/Crashlytics. Debug Settings includes Ad Inspector behind normal eligibility and Google test-device requirements. No production ad frequency was changed and no live delivery result is claimed.
