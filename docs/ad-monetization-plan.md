# Ad inventory and monetization flows — 2026-11-10

The user's supplied Google instructions authorize updating config/ads_util.dart. Both App IDs and all eight ad-unit literals now match that inventory exactly; scripts/verify_admob.py compares every supplied value without printing them. The iOS banner was corrected from an App ID to the supplied banner unit. App Open aliases remain supported. Android derives its native App ID at build time; the iOS native App ID already matches. Firebase, icons, package IDs and SDK dependencies were not changed.

| Format | Android suffix | iOS suffix | Status |
| --- | --- | --- | --- |
| App ID | ~1229517112 | ~3755608109 | Native mapping checked |
| Banner | /6573343131 | /5987019770 | Configured |
| Interstitial | /2634098121 | /9163847454 | Configured |
| App Open | /4389220110 | /9409859923 | Configured |
| Native Advanced (customAd) | /1894918711 | /1351993236 | Configured; one small template on Discover and Analysis |

The user confirmed both customAd units are Native Advanced. They now map to AdFormat.nativeAdvanced. IDs alone do not verify AdMob account approval, fill or serving.

## Implemented delivery improvements

- Banners remain fixed in the shared footer on all eight routes, gated by consent and a returning session. They now dispose when a route is covered or the keyboard is visible. Failed loads retry after 30 seconds then 120 seconds, with a maximum of three attempts per placement/width failure cycle. Hidden/background/ineligible placements do not make retry requests. Successful banner refresh is left to the SDK/AdMob console; there is no app refresh loop.
- Expired fullscreen cache entries are disposed and replaced during subsequent preload opportunities, instead of occupying the ready slot indefinitely. A replacement never causes a late display over active content.
- Click callbacks suppress the next App Open resume opportunity when returning from an advertiser. They do not log click identifiers or profile information.
- A combined fullscreen cap defaults to six SDK-confirmed displays per process session, configurable with ADS_FULLSCREEN_SESSION_CAP (zero disables fullscreen presentation). Failed shows do not consume the cap. The shared 120-second minimum launch grace/cooldown and five-minute App Open cooldown remain.
- ADS_BACKGROUND_MINIMUM_SECONDS now controls the minimum real background interval (default 300, environment value clamped to 60–86400). ADS_ACTION_THRESHOLD already controls completed detail visits (default 3). No defaults were made more aggressive. First experience, consent and reading/form protections remain.

## Optional engagement experiment

A test-only experiment can use two completed detail visits and two minutes in the background, preserving the shared cooldown and six-ad cap:

```sh
flutter build apk --release \
  --dart-define=ADS_ENABLED=true \
  --dart-define=ADS_USE_TEST_ADS=true \
  --dart-define=ADS_ACTION_THRESHOLD=2 \
  --dart-define=ADS_BACKGROUND_MINIMUM_SECONDS=120 \
  --dart-define=ADS_FULLSCREEN_SESSION_CAP=6
```

Interstitial opportunities still require a loaded detail read for at least ten seconds, a real Back/pop, and return to Discover/Analysis. App Open still requires the immediate foreground transition on a safe overview with a ready ad; cold starts and late arrivals remain excluded. A two-minute background threshold is an experimental product setting, not a Google requirement. Evaluate retention and AdMob revenue together before choosing production values. Production readiness remains false by default and is not automatically enabled by adding valid IDs.

## Revenue recommendations

1. Enable Google-optimized banner refresh in the AdMob console where available. Google documents that the SDK respects console refresh settings; app-side loops are unnecessary. [Banner guide](https://developers.google.com/admob/flutter/banner).
2. The confirmed Native Advanced units now use one clearly disclosed native template at a section boundary on Discover and Analysis. Compare performance and retention before expanding placement density. Device layout verification remains required. [Native templates](https://developers.google.com/admob/flutter/native/templates).
3. Configure mediation/bidding for appropriate networks in AdMob, then install and verify only the selected adapters and privacy settings. This requires account-side setup; it has not been configured here. Google describes mediation as a way to improve fill through multiple ad sources. [Mediation guide](https://developers.google.com/admob/flutter/mediation).
4. Compare impressions, match rate, show rate, eCPM, revenue and retention by platform/format in the AdMob console. First fix failed requests and low show rate before lowering frequency limits. Analytics remains independently disabled without consent.

Google recommends interstitials at natural content breaks and App Open ads on opening/resuming, with no conflicting ads or delayed display over active content. The existing centralized coordinator retains these boundaries. [Interstitial guidance](https://support.google.com/admob/answer/6066980?hl=en), [App Open guidance](https://support.google.com/admob/answer/9341964?hl=en).

## Verification

AdMob offline source/metadata checks passed, including exact inventory comparison and native App ID consistency. Added/updated Dart tests cover both banner mappings, reserved custom units, combined session cap, configurable background interval, advertiser return suppression, expired-cache replacement, bounded banner retries and keyboard visibility. Flutter pub get, dart format ., flutter analyze and flutter test were attempted; all stopped because the agent cannot write the installed Flutter SDK cache. These Dart changes have not been compilation/test/device verified. No live ads were requested or clicked. SDK/dependency versions and lockfiles were not changed. Prior user-reported release test-ad serving does not verify this new change.

## Native Advanced implementation

The user confirmed the format after the initial inventory update. GoogleAdsGateway now loads NativeAd with TemplateType.small using the installed v6 API; no custom native factory or new dependency is required. Google templates own attribution, AdChoices, asset rendering and click handling. [Template sizing and integration](https://developers.google.com/admob/flutter/native/templates).

One NativeContentAd is inserted after Discover core numbers and between Analysis core/supporting groups, only inside loaded calculation content. The template is centred, 320–400dp wide and 140dp high, with a separate Quảng Cáo label/dividers and spacing. Below 320dp available width, it collapses instead of clipping. It does not overlay the article or footer. Existing sticky banners remain. There are no native ads on forms/settings/privacy/detail routes.

ADS_NATIVE_ENABLED defaults true behind ADS_ENABLED and all existing gates; set it false to disable this format independently. Debug/Profile and release test mode use official native test units. Release production uses the supplied customAd units only with explicit production readiness. Native loading uses the shared inline controller: deduplication, generation invalidation, disposal on route cover/keyboard/consent/background/fullscreen/loading, and bounded 30s/120s failure retries. SDK impressions, rather than successful loads, emit the existing ad_displayed event through the independently consent-gated analytics bridge. Native clicks participate in advertiser-return suppression. No raw native assets or personal data enter logs/telemetry.

Added native tests cover source/test/production mapping, format disabling, duplicate load prevention, impression callbacks, late-load disposal after consent withdrawal, first-session and route gates, exclusion from fullscreen preload, template size/label and narrow-width collapse. Offline verifier checks passed after this update. Pub get, formatting, analysis and tests were attempted and blocked by SDK cache write permissions. Native Android/iOS build, serving, creative clipping/AdChoices and device interaction remain unverified.
