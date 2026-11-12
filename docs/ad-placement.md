# Ad placements

The complete Stitch reference remains preserved in design_preference/design_pilogy.txt. The user's 2026-11-10 request authorizes a fixed bottom banner across all eight approved routes, superseding the earlier Discover-only scrolling placement.

| Screen | Banner | Full-screen presentation |
| --- | --- | --- |
| V01 Welcome | Shared fixed footer | None |
| V02 Profile input | Shared fixed footer; hidden with keyboard | None |
| V03 Discover | Shared fixed footer | Eligible detail return / background resume only |
| V04 Analysis | Shared fixed footer | Eligible detail return / background resume only |
| V05 Interpretation | Shared fixed footer | Never while reading; completed visit may count on return |
| V08 Profiles | Shared fixed footer | None |
| V09 Settings | Shared fixed footer | None |
| V10 Privacy/data | Shared fixed footer | None |

PilogyScaffold places StickyAdBanner outside the Expanded scrolling body, inside SafeArea and above existing bottom navigation/actions. The banner reserves its actual adaptive height when loaded; content scrolls in the remaining space. A divider and Quảng Cáo label separate it from content. No permanent empty slot remains after failure. The original Discover inline placement is removed, so it cannot duplicate the footer. This uses the SDK's anchored adaptive size for a fixed placement, consistent with [Google's banner guide](https://developers.google.com/admob/flutter/banner).

All routes still require ADS_ENABLED, a valid configured banner unit, SDK initialization, UMP eligibility, a returning session and foreground state. The first session launched without a selected profile stays ad-free on every screen, including Welcome and profile creation. A returning session can show the footer on all eight routes. Banner eligibility is now independent of calculation availability; calculation loading/error states still block full-screen presentation. Startup/unknown routes remain excluded.

The footer hides for the keyboard, non-current routes, consent, dialogs and full-screen ads. No IDs enter feature widgets. Full-screen triggers, frequency limits, native configuration and production readiness defaults are unchanged.

Verification: policy regression tests and a widget test for fixed position, navigation separation, scrolling and keyboard visibility were added. On 2026-11-10, pub get, format, analyze and tests were attempted but blocked by SDK cache write permissions in the agent environment. No passing Flutter tests/build or device screenshots are claimed for this change. The user confirmed that the preceding test-ad APK displayed an ad on Discover; the new all-screen placement still needs a rebuilt APK/device check at 360/390/430dp.

Offline AdMob source checks passed. Foundation checks confirmed preserved design/Firebase files, native identifiers and parsed native metadata, then stopped at its existing whitespace-sensitive `GoRoute(path:` assertion because router declarations are formatted across multiple lines. A whitespace-tolerant read-only count confirmed exactly eight GoRoute declarations. The foundation script was not changed.

## Native Advanced content placements

The user confirmed customAd is Native Advanced. Discover has one labelled small template after core numbers; Analysis has one between core/supporting groups. These are inline content placements, separate from the sticky footer. Both require loaded calculation content, a returning session, foreground state, UMP eligibility and no keyboard/dialog/fullscreen ad. Templates collapse on failure or at available width below 320dp. ADS_NATIVE_ENABLED=false disables them independently. Existing fullscreen triggers and eight routes are unchanged. Device verification remains outstanding; see [the implementation and verification notes](ad-monetization-plan.md#native-advanced-implementation).
