# M03 verification — 2026-11-09

Implementation is authored; **M03 executable acceptance remains blocked**. No passing Flutter, Dart, APK, iOS, device Firebase or Dart SQLite integration result is claimed.

Installed SDK metadata: Flutter **3.13.9** (`FlutterSDK/flutter/version`); bundled Dart **3.1.5 stable, macos_x64** (VM crash banner). Flutter --version itself aborts. No pubspec.lock or .dart_tool/package_config.json was produced, so actual resolved/locked dependency versions are unavailable. Exact declared direct versions remain in pubspec.yaml; no dependency was added or changed by M03.

| Attempt | Actual outcome |
| --- | --- |
| flutter pub get | SIGABRT before initialization |
| dart format . | SIGABRT before initialization; formatter did not run |
| flutter analyze | SIGABRT before initialization |
| flutter test | SIGABRT before initialization; no Dart test executed |
| flutter build apk --debug | SIGABRT before initialization |
| flutter build ios --simulator | SIGABRT before initialization |
| python3 scripts/verify_foundation.py | Passed scaffold/import/SQL/Firebase preservation checks |
| node scripts/generate_backend_fixtures.cjs | Passed five existing local backend handlers and nine expected values/Master mapping |
| Production HTTP probes | DNS/connection failure before HTTP response; curl confirms unresolved pilogy.vercel.app |

All six SDK commands abort at `../../runtime/vm/cpuinfo_macos.cc:42: unreachable code`. Full logs and machine-readable outcomes are in docs/verification/m03/. The SDK is outside writable workspace roots; no installed SDK replacement was performed. Existing dependency declarations are unresolved, so source inspection is not a substitute for compilation. Recovery requires a functioning supported Flutter/Dart installation in the execution environment, then rerunning all commands and committing the real lockfile. Do not mark M01/M02/M03 runtime acceptance as passed on the strength of Python/Node checks.

## Automated tests authored

- api_client_test.dart: JSON/envelope decoding, base prefix, connection/send/receive timeouts, connection failure, standard and non-JSON HTTP failures (400/404/413/415/422/500/502/503), 429 Retry-After and cooldown, malformed JSON/schema and unexpected 304.
- api_models_test.dart: nine indices, Master/base values, calculation steps, dates, versions, full article sections, strict required keys and date-only rendering.
- backend_repositories_test.dart: synthetic request mapping, SQLite write/read, cached-to-refreshed stream, profile edit/isolation, month/year boundaries, offline with/without cache, version changes, content updates, stale in-flight edit rejection, Master article keys and stale-version fallback.
- backend_providers_test.dart: initial loading, cached refresh/success/error/missing, stream error, selection switch, cancellation and suppression of obsolete responses.
- Existing M01/M02 startup/theme/routes/environment/profile/Firebase tests remain intact; network timeout assertion follows the new 10-second send default.

Dio test adapters replace transport; temporary sqflite FFI files replace platform storage; fake repository streams replace provider networking. No main unit test requires production HTTP or live Firebase. Test assertions have not executed due to the VM blocker.

## Fixture provenance and optional HTTP verification

`node scripts/generate_backend_fixtures.cjs` imports existing sibling backend route handlers via its installed esbuild, bundles into an OS temporary directory and writes five test fixtures. It does not modify backend source, call production, add formulas or generate editorial text. The request is the supplied synthetic Nguyễn Văn An / 1990-05-20 / 2026-11-08 fixture. Fixture articles are verbatim backend content, used only in tests.

Observed local handlers: health/config/definitions/calculation/article all return HTTP Response status 200. All expected index values matched (8,3,1,11,2,7,11,8,1); Personality and Maturity preserve baseValue 2 and Master summary lookup values. Calculation version v1, content version v1.0.0-draft, explicit referenceDate and nine summary keys are present in fixtures. This is direct backend handler verification, **not a deployed HTTP check or Dart mapping/cache execution**.

`python3 scripts/verify_backend_http.py` performs one bounded synthetic check per endpoint and records only safe status/mapping/version metadata in live-http.json. It does not bypass deployment protection. Actual attempts here fail before HTTP; backend availability, deployed response mapping and Flutter SQLite write/read were not verified live.

After SDK recovery, run flutter pub get, dart format ., flutter analyze, flutter test, flutter build apk --debug and flutter build ios --simulator. Record actual SDK output and resolved lockfile. Re-run optional HTTP checks only when DNS/network access is available. Birthday 11/22 content remains absent upstream (404 full article; Calculate can fail 500 for required missing summaries); M03 preserves those errors.

## Files added and changed

Added source: features/numerology/domain/api_models.dart, data/backend_repositories.dart, presentation/backend_providers.dart; services/network/api_client.dart (all beneath lib/).

Changed source: services/network/dio_provider.dart (configurable 10/10/20 defaults), core/network/api_failure.dart (safe Retry-After/offline/UI metadata), services/storage/cache_store.dart (read-only current-revision/latest-article lookups). Schema version remains 1.

Added tests: api_client_test.dart, api_models_test.dart, backend_repositories_test.dart, backend_providers_test.dart, backend_test_support.dart; test/fixtures/{health,config,definitions,calculation,article}.json. Updated test/network_test.dart timeout expectation.

Added scripts: generate_backend_fixtures.cjs, verify_backend_http.py. Added docs/api-models.md, cache-strategy.md, offline-behavior.md, flutter-api-verification.md and verification/m03 evidence. Updated backend-integration.md, architecture.md, local-database.md, README.md and AGENTS.md.

No backend, config/, native configuration/identifiers, design references, profile CRUD, telemetry defaults or screen implementation was changed.

## M04 remaining work

Compose only V01/V02/V03/V04/V05/V08/V09/V10 using existing design tokens and integration providers. Add visible state/refresh controls, actual value-based article navigation, and selected-date composition. Obtain decisions for unsupported Stitch demo content/actions; do not port its local formulas, extra indices, ads or sample interpretations. Resolve the SDK acceptance blocker before relying on these layers. M04 has not started.
