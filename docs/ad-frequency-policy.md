# Frequency and lifecycle policy

The shared session policy uses an injectable clock. No profile, birth date, numerology or advertising identifier enters frequency state, which is not persisted.

Interstitials count one action per unique successfully loaded interpretation visit, read for at least 10 seconds and exited using an actual route pop. A visit ID is captured before the pop animation; display is attempted only after that animation and only when the current route is Discover/Analysis. A load/error/retry, ordinary tap, dropdown, scrolling, typing, date selection, profile switch, consent interaction or background refresh does not increment the counter. A short/repeated back action without a new successfully read visit does not count.

Default threshold: 3 completed visits. Minimum launch grace and shared cooldown: 120 seconds. No first-session ads after profile creation. The threshold resets only on the SDK's shown callback. No-ready/failed ads do not block navigation. Failed display releases the reservation and conservatively starts a cooldown too. Cooldown also starts at dismissal to prevent an app-open immediately after a long video. A full-screen lock is acquired before invoking SDK show; only one loaded handle is consumed. Duplicate callbacks are ignored.

App Open only considers returning users on a resumed transition following at least five minutes paused in the background. Inactive/system-dialog changes alone do not qualify. Consent, popups, calculations and V05/form/profile/privacy/settings routes block it. One opportunity per resume is consumed even if an ad is unavailable; an asynchronously loaded ad never appears later over an active session. App Open ads expire at four hours; interstitials conservatively expire at one hour. Shared cooldown and App Open-specific 300-second cooldown both apply.

App Open is suppressed on the next resume following an ad click, so returning from an advertiser cannot immediately trigger another ad. A combined fullscreen cap defaults to six SDK-confirmed displays per process session (ADS_FULLSCREEN_SESSION_CAP); failures do not count. ADS_BACKGROUND_MINIMUM_SECONDS controls the background interval, default 300, environment-clamped to at least 60 seconds. Existing shared cooldown still applies.

Cold start is deliberately skipped: the selected V1 layouts have no dedicated ad loading screen, and startup calculations/consent are protected. The service preloads for a later eligible resume; it never delays core startup to create an ad opportunity.

Preload attempts are serialized per format, max three per failure cycle with 30s then 120s backoff. Dismissal/show failure schedules a delayed reload. No tight no-fill loops. Banner failures retry after 30 seconds then 120 seconds, up to three attempts per placement/width failure cycle. Retries require a visible, foreground, consent-eligible placement. Successful banner refresh is SDK/console-owned. Duplicate rebuilds do not create another banner. Lifecycle pauses do not reset a cooldown; consent changes invalidate loaded/in-flight resources by generation.

See [Google App Open guidance](https://developers.google.com/admob/flutter/app-open) for placement and four-hour expiry. Tests exist but are not executed due to SDK startup failure.
