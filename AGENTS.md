# Pilogy mobile instructions

Work directly in this directory; do not nest another Flutter application.
Preserve all content in `design_preference/` and `design_reference/` if present. The current reference is `design_preference/design_pilogy.txt`.
Read the complete reference before changing the screen architecture.

Only V01, V02, V03, V04, V05, V08, V09, and V10 are in scope. M04 is explicitly authorized: implement the eight selected native Stitch screens and connect local/API flows. Preserve M01–M03 models, repositories, Firebase setup and profile components. Do not automatically start M05 or M06. No AdMob, payments, authentication, cloud profile synchronization, or excluded screens.

Use feature-first MVVM and repositories with Riverpod, go_router, Dio, sqflite, shared_preferences, path, and google_fonts. Keep business logic out of widgets. Backend alone calculates numerology and supplies Vietnamese interpretations. Profiles live locally; never add backend profile persistence.

Use API_BASE_URL via --dart-define. Do not log names, birth dates, requests, or cached interpretations. Exact Stitch values take precedence over approximate styling; use production icons, not emoji. Document missing design behavior rather than inventing flows.

Android/iOS scaffolding and Dart foundation exist directly here; do not recreate over them. Android ID/namespace and iOS Runner Bundle Identifier must remain mt.numerology. Preserve all Firebase files in config/ byte-for-byte; M02 authorizes Firebase Core/Analytics/Crashlytics using these existing configurations only; do not create Firebase projects/apps. Keep profiles local and do not send personal data to telemetry.

Actual backend is ../api/numerology-api/; read docs/api-contract.md, docs/openapi.yaml, and docs/flutter-integration.md there before implementing API behavior. Current Flutter CLI crashes before initialization. See README and docs/verification/ for evidence. Dependency versions are declared but not resolved; no passing Flutter checks are claimed. Restore tooling and run required checks before marking M01 complete.

Once executable code exists, run flutter pub get, dart format ., flutter analyze, and flutter test. Test startup, theme, routes, environment validation, and initial rendering. Record actual SDK and locked dependency versions.


M02 storage lives in pilogy_v1_local.db, schema version 1. Never delete/overwrite legacy databases (including M01 pilogy.db) or clear shared_preferences. Read docs/local-data-migration.md before schema changes. Use explicit tested migrations; fail closed for unknown versions. Profiles, selection and private result cache are SQLite-owned. Input fingerprints are cryptographically random per-profile revision tokens, never personal-data hashes or analytics IDs.

Firebase Core/Analytics/Crashlytics use the existing matching mt.numerology configurations. Keep config/ originals intact; native copies must match. Collection defaults off; ENABLE_TELEMETRY is explicit. Never send raw exceptions, SQL, profile IDs/names/birth dates or payloads to analytics/crash reporting. No Firebase project/app provisioning, authentication or cloud data services.

M03 API models/repositories and M04 screens are implemented in source. M05 explanation refinements and M06 advertising are not authorized by this task. Local tests inject temporary SQLite factories and fake Firebase drivers; no live Firebase is needed. Do not describe blocked Flutter checks or device Firebase delivery as passed.


M03 implementation uses features/numerology/{domain,data,presentation} and the existing Dio/CacheStore providers. See docs/backend-integration.md, docs/api-models.md, docs/cache-strategy.md, docs/offline-behavior.md and docs/flutter-api-verification.md. Unknown deployed versions remain visibly stale; reference dates are exact calendar strings. Never replace Master lookup values with baseValue. Use selectedProfileCalculationProvider to suppress retained values during profile switches; refreshSelectedCalculation invalidates its private stream. Public content is revalidated with unconditional GET until a tested validator metadata migration exists. No automatic retry loops; API client enforces 429 cooldown.

All M03 Flutter commands still abort at VM initialization; no lockfile, analysis/test/build success is claimed. Synthetic fixtures generated from existing local backend route handlers pass Node checks; production HTTP probes fail DNS, and Dart SQLite round trips remain unexecuted. Fix tooling and run acceptance checks before marking runtime verification complete. M04 is now authorized by the current task; do not automatically proceed to M05/M06.


M04 uses app/startup.dart for local preferences/profile bootstrap, core/presentation/pilogy_scaffold.dart for shared layout/navigation, and numerology/presentation/calculation_widgets.dart for typed result states. See docs/m04-screen-flows.md and docs/m04-verification.md for current behavior, explicit navigation decisions and design gaps. Exactly eight routes remain. M04 may show real locally stored profile inputs and backend content in UI, never in logs or telemetry. V05 derives the actual lookup value from the current selected profile/result. Keep calculation steps server-provided.

Cache clearing suspends automatic result repopulation for the current profile revision until explicit refresh, revision change or relaunch. Delete-all is an explicit confirmed UI action implemented as one SQLite profile deletion transaction; it never deletes database files or clears preferences. JSON export is user-triggered through the native save/share bridge, with fixed safe errors. Reminder settings store preference only and must not be described as scheduled notifications. No dark palette, external destinations, extra metrics/indices, journal or ad flow is fabricated.

Flutter pub get/format/analyze/tests/device integration/APK/iOS checks still abort before initialization; CoreSimulator access is also blocked. Swift parsing and offline foundation/local backend fixture checks pass but do not prove runtime behavior. Record actual SDK/lockfile/device results after recovery; do not claim M04 accepted or start M05/M06 automatically.

## Explicit M05 authorization and current rules

The user's M05 request supersedes historical phase deferrals above. Preserve the eight approved layouts and official visible name PILOGY. Apply Unicode display formatting only at presentation boundaries; never alter raw response/cache bodies or user-entered names for casing. Backend remains the only numerology engine. Preserve approved icons, config files, package IDs and portrait settings. Do not begin M06/AdMob. M05 Flutter verification is blocked by the installed VM startup crash; logs are in docs/verification/m05. Do not claim passing Dart analysis/tests/builds or screenshots from source-only checks.

## Explicit M06 authorization

The M06 request supersedes prior ad deferrals. Ad code lives in lib/services/ads and must remain behind ADS_ENABLED (default false), UMP eligibility and centralized full-screen policy. Debug/Profile always use test units. config/ads_util.dart is immutable and authoritative; it is parsed as an asset, never executed. Android derives its App ID at build time; sync_admob_config.py projects the native iOS value and verify_admob.py checks it. Do not copy unit IDs into widgets or invent missing IDs. No rewarded ads or M07.

The M06 dependency target is google_mobile_ads6.0.0 with Flutter>=3.27/Dart>=3.6; the configured local3.13.9 SDK has not been upgraded and crashes before initialization. Actual dependency resolution and native migration are unverified. Keep production readiness false until the documented release gates pass. Analytics remains disabled until independent Analytics consent exists; UMP ad eligibility is not Analytics or ATT consent. No profile/calculation data enters ads or telemetry. Preserve original config/Firebase files, icons, IDs, approved eight layouts and portrait behavior.
