# M04 screens and functional flow

Eight native Flutter screens now connect local profile creation/selection/edit/deletion, backend results, full interpretations and calculation steps, settings, JSON export, cache clear and delete-all. Startup restores the local selection. No extra screen, local numerology engine, auth/cloud profiles, ad SDK or payment flow was added.

Read [screen flows and design gaps](docs/m04-screen-flows.md) and [actual verification/runbook](docs/m04-verification.md). Source is implemented; **runtime acceptance is blocked** by the installed Dart VM initialization crash. No Flutter checks, simulator/emulator flow, native export delivery or pixel comparison are claimed passed. Offline foundation/local backend checks and Swift syntax parsing pass. Installed metadata is Flutter 3.13.9 / Dart 3.1.5; locked dependencies remain unavailable.

Production default: `https://pilogy.vercel.app/api/v1`; override with `--dart-define=API_BASE_URL=...`. After SDK recovery, resolve/lock packages, format/analyze/test, then run `flutter test integration_test/pilogy_flow_test.dart -d <actual-device-id>` and both native builds. The integration test uses synthetic transport and an isolated native SQLite database. See the runbook for production/manual checks. M05 and M06 have not started.

Earlier milestone records follow as history.

# M03 backend integration status

The reusable API/model/repository/provider layer is implemented; Flutter runtime acceptance is blocked by the installed Dart VM crash. No full screens or M04 work were added. All five existing backend endpoint families are integrated with version-aware local SQLite fallback, explicit calendar dates, Master Number preservation and safe errors/429 cooldown.

Start with [backend integration](docs/backend-integration.md), [models](docs/api-models.md), [cache](docs/cache-strategy.md), [offline states](docs/offline-behavior.md), and [actual verification results](docs/flutter-api-verification.md). Production default is https://pilogy.vercel.app/api/v1; override API_BASE_URL with --dart-define for local development. Native identifiers remain mt.numerology and Firebase configuration is preserved.

Required commands were attempted: flutter pub get, dart format ., flutter analyze, flutter test, Android debug and iOS simulator builds. All abort before initialization. Installed metadata is Flutter 3.13.9 / Dart 3.1.5; no resolved dependency versions or lockfile exist. Local Node handler fixtures and Python foundation checks pass; production HTTP and Dart cache execution are unverified. See docs/verification/m03/ for evidence.

The earlier milestone notes below are retained as implementation history; M03 behavior is documented in the links above.

# Pilogy mobile — M02 local profiles and Firebase

Project root: `/Users/sigmasolutions/Documents/Src/PLG/mobile`.
Android applicationId/namespace and iOS Runner Bundle Identifier: **mt.numerology**.

**M02 source is implemented in the existing M01 project. Dependency installation, Dart analysis/tests and native builds remain blocked by the installed Flutter runtime. M03 has not started.**

## Existing foundation and references

`pubspec.yaml`, `lib/main.dart`, `android/`, `ios/`, eight named go_router routes, Riverpod architecture and the reusable Design System exist directly here. The application was not recreated and no nested Flutter project was added.

The design actually resides in `design_preference/design_pilogy.txt`; the requested `design_reference/` directory is absent. The complete reference was read and preserved unchanged. All requested backend files exist under `../api/numerology-api/` and were inspected: docs/openapi.yaml, docs/api-contract.md, lib/types/api.ts, lib/validation/calculate.ts, and the five handlers below app/api/v1/. No backend files were changed or new APIs created.

Original `config/google-services.json` and `config/GoogleService-Info.plist` remain byte-identical. Their application identifiers both match mt.numerology and reference existing Firebase project numerology-857a6. Android and iOS have matching native copies; no remote project/application was created.

## Implemented behavior

- LocalProfileRepository: createProfile, getProfileById, getAllProfiles, updateProfile, deleteProfile, selectProfile and an atomic getSnapshot.
- Strict Gregorian YYYY-MM-DD validation, leap years, preserved Vietnamese names, UUID v4 identifiers, UTC timestamps and safe local storage failures.
- SQLite **pilogy_v1_local.db**, schema **1**: user_profiles, calculation_cache, interpretation_cache, app_state, profile_cache_revisions and calculation_contexts.
- Persisted selected profile: first profile auto-selects; adding another retains selection; deleting the selected one clears it; reopen restores selection.
- CacheStore: opaque saved-response persistence, random input revision tokens, calculation version/reference-date invalidation, transactional stale-response rejection and profile-independent versioned articles. No personal-data hashes or network calls.
- Reusable create/edit form, profile list, selection tile and delete confirmation; the eight full screens remain placeholders for M04.
- Firebase Core startup before runApp, native identity checks, Analytics/Crashlytics configuration, safe fixed-code Dart reporting and disabled collection by default. Offline local storage remains usable when Firebase initialization fails.

No login, cloud profile storage/synchronization, backend calculation formulas, API integration, payments or AdMob. M03 will implement real backend integration; M04 will compose full screens.

## Run after restoring the toolchain

```sh
flutter doctor -v
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug --no-codesign
flutter run
```

Firebase collection defaults off in native configuration and runtime. An explicit validated telemetry run can use `flutter run --dart-define=ENABLE_TELEMETRY=true`. No profile inputs/identifiers are passed to telemetry, and Dart handlers never forward original exceptions, details or input-bearing stacks. Physical-device Firebase delivery/symbolication is unverified.

API_BASE_URL remains configured via --dart-define for later M03 use; this task adds no requests. Runtime Google Fonts fetching still exists from M01: bundle licensed font assets before release for offline visual fidelity. Profile operations themselves have no network dependency.

## SDK and declared package versions

Installed SDK: `/Users/sigmasolutions/FlutterSDK/flutter`; version file Flutter **3.13.9**, revision d211f42860350d914a5ad8102f9ec32764dc6d06. `dart --version` reports **Dart 3.1.5 stable**, macos_x64. Flutter CLI and Dart execution abort with `cpuinfo_macos.cc:42: error: unreachable code` (SIGABRT), so the root cause/toolchain needs repair in the execution environment. Doctor cannot inspect native readiness. No lockfile or successful package installation is fabricated.

| Dependency | Declared version |
| --- | --- |
| flutter_riverpod | 2.4.9 |
| go_router | 12.1.3 |
| dio | 5.4.0 |
| sqflite | 2.3.0 |
| path | 1.8.3 |
| shared_preferences | 2.2.2 |
| google_fonts | 6.1.0 |
| uuid | 4.2.2 |
| diacritic | 0.1.5 |
| firebase_core | 2.24.2 |
| firebase_analytics | 10.8.0 |
| firebase_crashlytics | 3.4.9 |
| flutter_lints (dev) | 2.0.3 |
| sqflite_common_ffi (dev) | 2.3.0 |
| flutter, flutter_localizations, flutter_test | SDK |

Versions target the installed older SDK, rather than claiming the latest available releases. Firebase dependency ranges were inspected in cached manifests. Full transitive/native compatibility remains subject to pub resolution/builds. Commit the application pubspec.lock after successful resolution. Preserve existing Kotlin/Gradle/signing configuration when repairing the toolchain; review compatibility before any SDK/tooling upgrade.

## Actual verification results

| Check | Result |
| --- | --- |
| Required project paths, unchanged app IDs, exactly eight placeholders | PASS, offline scaffold checks |
| Design/config hashes and native Firebase copies | PASS |
| Xcode/plist/XML/asset JSON parsing, Runner Firebase resources | PASS |
| Podfile syntax | PASS |
| Actual SQL schema, selection cleanup, cascades, orphan rejection, article uniqueness | PASS using Python SQLite |
| flutter pub get | BLOCKED: SIGABRT, packages not resolved/installed |
| dart format . | BLOCKED: SIGABRT |
| flutter analyze | BLOCKED: SIGABRT, no analyzer result |
| flutter test | BLOCKED: SIGABRT, no Dart tests executed |
| Android debug APK build | BLOCKED: SIGABRT, no APK |
| iOS simulator debug build | BLOCKED: SIGABRT, no simulator app |
| Physical-device Firebase verification | NOT PERFORMED |

Evidence: [M02 command results](docs/verification/m02/results.json) and adjacent logs. `python3 scripts/verify_foundation.py` repeats offline schema/scaffold/Firebase checks. Those checks do not prove Dart compilation, sqflite platform behavior or repository test success.

Tests are authored for startup/theme/router/environment, temporary SQLite initialization/version/CRUD/reopen/selection, invalid names/dates/leap years/Unicode/timestamps, cache invalidation and stale writes, foreign keys/cascades/shared articles, legacy file preservation and unsupported downgrade; view-model behavior, reusable profile components and fake Firebase startup are also covered. They do not require live Firebase or backend services.

## Migration safety and next work

New storage uses a distinct filename. M01 pilogy.db, unknown published-app databases and existing preference keys are untouched. No guessed migration or destructive recovery exists. Legacy profiles may not appear in the new namespace until real shipped schemas and fixtures support an explicit migration. Application version/signing and a migration plan must be reviewed before a published-app update.

Finish toolchain verification and resolve any actual compiler/test findings before treating M02 as verified. M03 remains deferred: API DTO/repositories, successful-envelope validation, reference-date consistency, backend response population, public ETag metadata/revalidation and bounded retries. M04 owns the final screen flows. No phase was started automatically.

- [Architecture](docs/architecture.md)
- [Design system](docs/design-system.md)
- [Screen mapping](docs/screen-mapping.md)
- [Local database](docs/local-database.md)
- [Profile management](docs/profile-management.md)
- [Firebase setup](docs/firebase-setup.md)
- [Local data migration](docs/local-data-migration.md)
- [Backend integration and M03 handoff](docs/backend-integration.md)

## M05 status (2026-11-09)

Visible brand: **PILOGY**. Display-only Vietnamese text formatting, shared server-step explanations, richer full-content presentation, resume-date checks and duplicate-refresh guards are implemented. Read [numerology experience](docs/numerology-experience.md), [text formatting](docs/text-formatting.md) and [verification evidence](docs/verification/m05/source-checks.json). Earlier phase deferrals in historical sections are superseded by the explicit M05 request. M06 remains deferred.

All six requested Flutter/Dart commands were attempted and exit 134 before initialization (`cpuinfo_macos.cc:42`, Dart 3.1.5 macos_x64). No compilation, automated tests, APK/iOS build or visual verification is claimed. `characters: 1.3.0` is now declared directly, matching the existing transitive lock version; dependency resolution and lockfile classification must be regenerated by a working `flutter pub get`.

## M06 — consent-aware advertisements

M06 is authorized and implemented in source with Banner, Interstitial and App Open controllers, UMP privacy options and shared frequency coordination. Ads default OFF; Debug/Profile force official test units. Read [integration](docs/admob-integration.md), [placement](docs/ad-placement.md), [consent](docs/ad-consent.md), [frequency](docs/ad-frequency-policy.md), [testing](docs/admob-testing.md) and [privacy review](docs/privacy-review.md). Historical M06 deferrals above are superseded.

**SDK migration required:** google_mobile_ads 6.0.0 requires Flutter >=3.27/Dart >=3.6; it is declared, not successfully installed here. The configured old SDK still crashes before startup. Android requires SDK 35/min23/JDK17; iOS targets13.0. Neither native build nor runtime ad serving is verified. Do not ship until the new dependency graph and migration pass tests/builds. Production iOS banners and both App Open formats remain disabled due to invalid/missing source IDs. Original config and icons are preserved. M07 remains deferred.
# pilogy-mobile-2.0
