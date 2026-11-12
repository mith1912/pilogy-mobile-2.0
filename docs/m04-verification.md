# M04 verification — 2026-11-09

M04 source and tests are authored, but runtime acceptance is **blocked**. No passing Flutter unit/widget/integration test, APK/iOS build, screenshot comparison, native file-export delivery or Firebase device delivery is claimed.

| Check | Actual result |
| --- | --- |
| flutter pub get | SIGABRT before initialization |
| dart format . | SIGABRT; formatter did not execute |
| flutter analyze | SIGABRT before initialization |
| flutter test | SIGABRT; no tests executed |
| flutter test integration_test/pilogy_flow_test.dart -d ios | SIGABRT before device selection/execution |
| flutter build apk --debug | SIGABRT; no APK produced |
| flutter build ios --simulator | SIGABRT; no simulator build produced |
| python3 scripts/verify_foundation.py | Pass: reference/Firebase bytes, native IDs/XML/plists, exactly eight routes, relative imports, existing SQL constraints/cascades |
| node scripts/generate_backend_fixtures.cjs | Pass: existing local backend handlers and nine expected synthetic values/Master mapping |
| swiftc -parse ios/Runner/AppDelegate.swift | Pass: Swift syntax only; not type checking/linking against Flutter/UIKit |
| xcrun simctl list devices available | Failed: CoreSimulatorService connection unavailable/operation not permitted; no simulator runtime execution |
| SDK download-host reachability | Failed DNS for storage.googleapis.com; no SDK replacement downloaded |

Installed metadata remains Flutter 3.13.9 / Dart 3.1.5 macos_x64. All seven Flutter/Dart attempts abort at cpuinfo_macos.cc:42. No lockfile or resolved dependency versions exist. M04 adds only the SDK-provided integration_test development dependency; existing production dependency declarations remain unchanged. Logs and preserved-file hashes are under docs/verification/m04/.

## Tests added or updated

- app_test.dart: design tokens, first-run local bootstrap, selected/unselected returning-user destination, eight named routes and safe detail parsing.
- screen_flow_test.dart + ui_test_support.dart: injected Dio fixtures with real temporary sqflite FFI storage; create/save/select/results/Master detail/steps; no duplicate calculation POST on tab change; offline restart and edit invalidation; actual-profile export through a fake system driver; clear-cache preserving profiles; confirmed delete-all; eight views at 320px with text scale 2.
- local_database_test.dart: transactional delete-all, selection/private-cache cascade, shared article preservation and stale-context rejection.
- Existing M01–M03 environment/profile/model/transport/provider/Firebase tests remain. Profile component fake implements the extended delete-all interface; default reusable form behavior remains compatible.
- integration_test/pilogy_flow_test.dart: emulator/simulator smoke test using the real sqflite platform plugin, isolated temporary database, mocked preferences, fixture Dio and full create → overview → Master detail → SQLite assertions. It deliberately avoids live API/Firebase and never touches the app's normal database or clears real preferences.
- integration_test/fixture_data.dart is generated from test fixtures by scripts/generate_flutter_test_fixtures.py. Synthetic backend content exists only in test sources, not production lib/ or assets.

These are authored assertions, not observed passing tests. Foundation/Node/Swift parsing checks do not prove Dart compilation or runtime behavior.

## Recovery and device runbook

With a functioning Flutter SDK and available platform runtimes:

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter devices
flutter test integration_test/pilogy_flow_test.dart -d <actual-device-id>
flutter build apk --debug
flutter build ios --simulator
flutter run -d <actual-device-id> --dart-define=API_BASE_URL=https://pilogy.vercel.app/api/v1
```

Replace the device placeholder with the reported Android Emulator/iOS Simulator ID. For a local backend, use 10.0.2.2:3000/api/v1 on Android Emulator or localhost:3000/api/v1 on a same-host iOS Simulator; native cleartext policy still applies. Physical devices require a reachable host. Never disable certificate validation. Production endpoints were not verified during M04; earlier DNS failures do not establish backend availability.

Manually verify: first-launch V01; valid/invalid profile creation; all tab transitions without repeat POSTs; full article and complete steps; contextual/system back; profile switch/edit/delete; offline cache/no-cache messages; missing Birthday content; 429 cooldown; persistence after process restart; real native export and cancellation; cache clear without hidden repopulation; delete-all cancellation/confirmation; phone widths and text scaling; route restoration; Firebase initialization with collection disabled. Record screenshots/build and locked SDK/package versions before acceptance.

## Changed files

New application files: lib/app/startup.dart; lib/core/presentation/pilogy_scaffold.dart; lib/features/numerology/presentation/calculation_widgets.dart; lib/features/settings/domain/settings_view_model.dart; lib/features/privacy_data/data/local_data_actions.dart; lib/features/privacy_data/presentation/privacy_view_model.dart.

Replaced all eight existing feature screen widgets. Updated app/app.dart and app/router.dart; profile form component/view model/interface/local repository/UserProfile equality; backend presentation-provider lifecycle; CacheStore statistics; safe missing-content error wording. Updated native MainActivity.kt and AppDelegate.swift for explicit local export only.

Added UI/device tests and fixture-generation script listed above; updated app/profile/storage tests, pubspec.yaml, foundation-check wording, screen mapping/design/architecture/profile/cache docs, README and AGENTS. No database schema change, backend source change or config/design file edit occurred. Android namespace/applicationId and iOS bundle ID remain mt.numerology.

M05/M06 have not started. M04 remains unverified until Flutter compilation, tests and emulator/simulator flows actually execute.
