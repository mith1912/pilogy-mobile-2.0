# Android AdMob delivery investigation — November 12, 2026

Report supplied by user; no AdMob Console or production logcat access. Changes in this investigation add diagnostics and a debug inspector only. No IDs, request targeting, consent eligibility, retries, cooldowns, placements or production frequency were changed. No delivery regression has been reproduced.

## Verified report arithmetic and limits

| Version | Requests | Matched | Impressions | Match rate | Impressions / matched |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1.0.11 | 66 | 64 | 34 | 96.97% | 53.13% |
| 1.0.12 | 14 | 2 | 1 | 14.29% | 50.00% |

The twelve unmatched requests in 1.0.12 are all attributed to customAd. Interstitial matched and displayed; App Open matched but did not record an impression. A matched App Open request is not evidence that a display opportunity occurred. Zero banner requests must be investigated separately from native no fill. These small, differently composed samples do not establish a regression, account restriction, consent failure, or No Fill error code.

## Two different source implementations share this version number

This workspace has no Git repository. Its pubspec is pilogy_app 1.0.12+13 and it has the newer Riverpod/UMP/ad-policy implementation.

Read-only inspection of ../Numerology/.git found historical release snapshots:

- `370b560` (2024-07-09): pubspec 1.0.11+12; google_mobile_ads constraint ^2.2.0, lock 2.4.0.
- `cffd1cd` (2025-07-21, commit subject `[Release][Android]: 1.0.12(13)`): pubspec 1.0.12+13; google_mobile_ads constraint `any`, lock 4.0.0.

These are available source snapshots, not authenticated provenance of the APKs in the November 2026 report. Version names alone cannot identify which implementation is installed. Obtain the Play artifact/build provenance and matching release-device callback logs before attributing the report to either implementation. No old repository was modified.

Evidence: [legacy diff](verification/admob-2026-11-12/legacy-ad-diff.log), [1.0.11 snapshot](verification/admob-2026-11-12/legacy-370b560.log), [1.0.12 snapshot](verification/admob-2026-11-12/legacy-cffd1cd.log).

### Legacy release comparison

- `lib/utils/ads_util.dart`, App Open manager and lifecycle reactor have no differences between these snapshots. All Android production IDs are identical to the current configuration.
- Banner widget changes only remove the old language-version comment and change its field to `late`. It still constructs a 320x50 BannerAd and calls load after one second. BasePage still mounts it when containBannerAd is true; native-detail page still returns true for useAdBanner. No confirmed banner removal was found.
- BaseState native loading still uses NativeAd, small native template and the customAd unit. Detail-page initState invokes createAdNative. This is an inline native advertisement beside interpretation content, not a banner, rewarded ad or custom full-screen format.
- Interstitial changes mostly add nullable access. Both snapshots preload in BaseState.initState, load again in showInterstitialAd, immediately retry up to three failures, and reload on dismissal/show failure. Awaiting the SDK load method does not guarantee that onAdLoaded has fired; this existing race is not a demonstrated 1.0.12 regression. The separate HomeScreen path shows directly inside onAdLoaded, before its show method installs lifecycle callbacks.
- Both App Open snapshots preload at startup; the first foreground event is skipped by the counter. Subsequent foreground events attempt display. If not ready they load and return; a later successful load does not automatically show. Dismissal reloads; load/show failures do not immediately reload, and there is no age expiry check. These unchanged behaviors can produce loaded but unshown ads.
- No UMP/Consent calls were found in legacy lib. This is a legacy integration gap, not evidence that it caused the twelve failed matches. The newer workspace already implements UMP.
- SDK upgrade (locked 2.4.0 → 4.0.0), compile/target SDK 33 → 35, Java 8 → 17 and a broad null-safety migration are real release differences. Source comparison does not establish any as the cause. The legacy interstitial request contains placeholder keywords/contentUrl in both snapshots; current workspace does not.

## Exact current Android mapping

Source: immutable config/ads_util.dart, parsed as literal constants by AdSourceIdentifiers; its getters are not executed.

| Purpose / SDK format | Source field | Runtime production identifier |
| --- | --- | --- |
| Application ID, manifest | _androidAppId | ca-app-pub-1578425271408021~1229517112 |
| num-banner / BannerAd | _androidBannerId | ca-app-pub-1578425271408021/6573343131 |
| num-inerstial / InterstitialAd | _androidInterstitialId | ca-app-pub-1578425271408021/2634098121 |
| appOpen / AppOpenAd | _androidAdOpen | ca-app-pub-1578425271408021/4389220110 |
| customAd / NativeAd, Native Advanced | _androidCustomAdId | ca-app-pub-1578425271408021/1894918711 |

The report labels are associated with the supplied configuration; the SDK requests IDs, not Console display names. Console-side registered formats/ownership/status cannot be independently verified here. No App ID/unit ID confusion, platform swap or native/banner swap was found. Android Gradle derives the manifest App ID from this configuration. Source verification passes; it does not prove the installed artifact uses these values.

Current NativeContentAd placements are Discover and Analysis. All current formats use a non-personalized AdRequest with 15-second HTTP timeout and no profile/calculation targeting. Non-personalized requests still require UMP eligibility.

Production units require release mode, ADS_ENABLED=true, ADS_USE_TEST_ADS=false, ADS_PRODUCTION_READY=true and the per-format flag. Debug/Profile always select official Google test units. Public-live-ads build script explicitly enables all four formats; flags used for the actual installed artifact are unknown.

## Current consent, banner and full-screen paths

UMP updates once per process startup and shows a required form; Mobile Ads initializes after eligibility. Requests also require a returning session, initialized SDK, allowed/non-busy consent and foreground state. The first profile-creation session stays ad-free. Consent errors fail closed even if previously stored UMP consent might have permitted requests. No consent bypass or fallback was added. Analytics remains independently denied.

StickyAdBanner is mounted by PilogyScaffold, outside the scrolling list and above navigation, on the eight approved screens. It hides when its route is covered or keyboard is visible. Banner gate requires an approved screen, no app dialog and no full-screen presentation; it does not require a successful calculation. It obtains anchored adaptive size before BannerAd.load. A missing/failed size can therefore produce an application load attempt without an SDK banner request. Disabled/missing banner configuration, visibility, eligibility and exhausted per-controller backoff can also prevent requests. None is confirmed in the production artifact. Since native had requests, a global ads/consent blocker alone cannot explain the entire aggregate pattern, although sessions/times may differ.

Current interstitial and App Open preload after SDK initialization and on context/foreground changes. A cached or in-flight ad suppresses duplicate loads. Three consecutive failures exhaust that format's service retry budget, with 30s then 120s retry delays. Success resets the failure counter; dismissal/show failure schedules a reload. Interstitial expires at one hour; App Open at four hours. Expired ads are discarded when checked. Full-screen displays share at least 120s startup/display/end cooldown and a default six-display session cap. Interstitial needs three completed distinct detail visits (at least ten seconds reading each) and a safe overview. App Open needs an eligible overview resume after at least five minutes background, plus its five-minute cooldown. Advertiser returns are suppressed. A late preload never displays over an active session. These policies were preserved.

## Diagnostic changes and how to interpret them

All new logs are local console only, gated by ADS_DIAGNOSTICS=true, default off. They are never forwarded to Firebase. SDK failure diagnostics deliberately now include SDK message and response metadata, superseding the older numeric-only diagnostic documentation. Do not pass app exceptions, personal data, API bodies or SQLite information to this logger.

- All four SDK load callbacks log format, LoadAdError code/domain/message/responseInfo as escaped JSON. Null responseInfo remains explicit. SDK invocation errors and load timeouts have fixed stage labels, without raw application exceptions.
- Existing service stages record configured/unconfigured, test/production, consent, requested, loaded, failed, displayed and closed states. Banner now records its SDK impression callback, not just successful loading.
- Banner footer mount, visibility, deduplicated gate skips, adaptive-size start/failure/success and actual SDK load invocation distinguish absence of requests from load failure. Native has the same inline gate diagnostics.
- App Open resume skip labels distinguish advertiser return, no background, unsafe overview and policy. Full-screen show skips identify no loaded ad or policy/gate rejection.
- Settings has an Ad Inspector entry only in Debug. Its handler also checks debug mode, test configuration, normal request eligibility and no active full-screen/dialog. It marks the inspector as a dialog while open. It does not initialize ads or load an ad to bypass gates. Google additionally requires a test device.

No production callback logs were supplied or captured. There is no observed LoadAdError code=3, invalid-request error, restriction message or failed banner callback to quote. New log formats are instrumentation, not evidence that those events already happened.

## Actual verification

[Source checks](verification/admob-2026-11-12/source.log) pass. Existing SDK metadata now identifies Flutter 3.47.9 / Dart 3.13.7, and current pubspec.lock records google_mobile_ads 6.0.0. These supersede historical SDK descriptions but do not prove a successful build in this investigation.

Required pub get, dart format ., flutter analyze, flutter test, focused ad tests with diagnostics, and Google-test-ad debug APK build were attempted. Flutter/Dart wrappers fail writing the read-only SDK cache:

    update_engine_version.sh: line 71: ...engine.stamp.tmp...: Operation not permitted
    update_engine_version.sh: line 78: ...engine.realm: Operation not permitted

Direct cached Dart reports version 3.13.7 but formatter/analyzer abort before initialization:

    ../../runtime/vm/cpuinfo_macos.cc: 42: error: unreachable code

ADB 1.0.41 / 33.0.2 cannot start its daemon:

    could not install *smartsocket* listener: Operation not permitted
    adb: failed to check server version: cannot connect to daemon

See [verification logs](verification/admob-2026-11-12/). No Dart analysis/test/build or device test passed. Added a diagnostic test covering default-off behavior and escaped code/domain/message/null responseInfo; execution remains blocked.

## Device validation after tool access is restored

Run pub get, format/analyze and the full suite, then:

    flutter test --dart-define=ADS_DIAGNOSTICS=true test/ads
    flutter run --debug --dart-define=ADS_ENABLED=true --dart-define=ADS_DIAGNOSTICS=true
    adb logcat -v time PILOGY_ADS:V flutter:I '*:S'

Filter captured output to PILOGY_ADS lines locally before sharing. Do not clear storage/consent or automate clicks. Use a returning local profile and complete ordinary UMP UI. Current Android sample units are banner /6300978111, interstitial /1033173712, App Open /9257395921 and native /2247696110 under Google's ca-app-pub-3940256099942544 publisher. Settings → Ad Inspector (Debug) requires an emulator or registered physical test device. Do not distribute this debug build to production.

For banner, follow footer_mounted → configured → consent_allowed/sdk_initialized → gate/visibility → ad_load_requested → adaptive_size_ready → sdk_load_called → ad_loaded → ad_displayed, or capture the exact failure. Visit Discover/Analysis for native; use normal detail reading and background intervals for full-screen tests without shortening policy intervals or manufacturing requests. Record all four test formats' callbacks and screenshots only when actually observed.

A successful official-test-unit run would verify much of the app/SDK/device path, but cannot establish production inventory or account eligibility. If test ads work while production fails, inspect the exact production LoadAdError and Ad Inspector results, then Console app/unit approval, Policy Center/ad-serving limits, app/store association, app-ads.txt status, regional/privacy configuration and mediation configuration. No Console restrictions were verified here. Standard Android com.google.android.gms.ads code 3 describes no fill; classify by domain AND message and response details, not the integer or match rate alone. Code 0/1/2 or another domain can indicate a different condition. Never respond to serving limits by increasing traffic, rotating IDs or bypassing consent.

Official references: [load errors](https://developers.google.com/admob/flutter/ad-load-errors), [test ads](https://developers.google.com/admob/flutter/test-ads), [UMP](https://developers.google.com/admob/flutter/privacy), [Ad Inspector](https://developers.google.com/admob/flutter/ad-inspector).
