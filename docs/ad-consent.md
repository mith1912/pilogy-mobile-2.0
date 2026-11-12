# UMP consent and ATT

When ads are enabled on a supported platform with a valid source App ID, startup requests UMP consent information once per process launch, then invokes loadAndShowConsentFormIfRequired. Concurrent initialization shares one future. All ad loads require successful UMP canRequestAds, completed consent flow, initialized SDK and foreground eligibility. No country inference or hand-written consent persistence is used. UMP alone stores/reports ad eligibility.

Update/query failures fail closed. Visible forms are not timed out into an eligible state underneath a still-open dialog. Core content is never blocked awaiting this future. Privacy options are exposed in V09 Settings when UMP reports required; the action revokes local request eligibility while showing UMP, discards old ads, then rechecks UMP. Failed privacy forms show only a safe Vietnamese message and keep ads blocked. ADS_ENABLED=false intentionally prevents all UMP/ads SDK calls for automated tests and screenshots.

Requests are non-personalized, carry no name/date/result/content keywords or custom targeting. iOS same-app key is disabled before initialization. Android AD_ID permission is removed and Firebase ad-ID collection disabled. These measures do not mean the SDK performs no processing/storage or that consent is unnecessary.

No ATT prompt is added: this initial integration does not request IDFA authorization, personalized/cross-app targeting or tracking. UMP is not a substitute for ATT. Before changing tracking, adding mediation or enabling production, review actual SDK/network data use and Apple policy; add an accurate usage description and a separate ATT flow if that use requires authorization. Do not equate canRequestAds with ATT or Analytics consent.

Firebase Analytics collection remains off in the native driver until an independent Analytics choice is implemented; ENABLE_TELEMETRY may still enable existing sanitized Crashlytics. The optional ad-event bridge is deny-gated by default. Automatic Analytics ad events are not intentionally enabled. No fabricated analytics consent flag is stored.

Manual AdMob Console work: verify each platform app/package/store association; configure and publish relevant regional Privacy & messaging forms, supported languages and privacy-policy URL; validate required privacy-options behavior. Test regulated-region and returning-consent flows using Google's documented UMP test devices/geography (test code only; never force geography/reset consent in production). There is no Console access or published-message verification in this task.

Sources: [UMP](https://developers.google.com/admob/flutter/privacy), [iOS privacy/ATT and SKAdNetwork](https://developers.google.com/admob/ios/privacy/strategies), [Firebase collection controls](https://firebase.google.com/docs/analytics/android/configure-data-collection).
