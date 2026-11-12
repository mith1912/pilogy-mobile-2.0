# M06 privacy review

Status: PARTIAL; technical safeguards are implemented, legal/store/Console review is not completed.

Profiles/results remain in existing local storage; the backend contract is unchanged. Ad services never receive profile names/IDs, birth dates, index values or interpretations. Requests contain no custom targeting, account identifiers or raw application payloads. Error telemetry is restricted to a fixed six-event whitelist with format and test/production mode; raw SDK errors, IDs, device identifiers and payloads are not recorded by this code. There is no estimated revenue or paid-event revenue reporting.

Non-personalized ad requests still involve Google SDK processing/network data. Review Google's disclosures for the exact resolved native versions, Apple App Privacy, Android Data Safety, ad content ratings, age/audience settings and regional consent messages. No child/under-age classification is guessed from a numerology birth date. Decide the audience setting in the Console before release.

Android removes Advertising ID permission and disables Analytics ad-ID/personalization defaults. iOS does not request ATT; same-app key is disabled. Info.plist contains a dated 50-identifier SKAdNetwork snapshot from Google's privacy guide, including Google's identifier. There are no mediation adapters. Refresh that list and inspect the resolved SDK privacy manifests, required-reason declarations and Xcode privacy report before submitting. The reference config, Firebase originals/native copies and approved icons were not changed.

Firebase Core remains initialized. Analytics collection is disabled pending an independent optional Analytics consent UI; the deny-gated Firebase ad-event bridge is present but not active. Sanitized Crashlytics remains controlled by ENABLE_TELEMETRY. Store disclosures and a real privacy-policy URL remain release blockers; no legal compliance certification is claimed.

Manual sign-off: verify App IDs/units and account/app approval, publish UMP messages, correct the iOS banner source, supply App Open production IDs, review SDK support status at submission, review tracking/ATT, test withdrawal/relaunch, complete store declarations, validate release signing. Never enable ADS_PRODUCTION_READY as a substitute for these reviews.
