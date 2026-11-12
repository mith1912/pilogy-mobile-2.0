# M05 verification, 2026-11-09

PARTIAL: implementation exists; executable verification is BLOCKED.

All requested commands were attempted: flutter pub get, dart format ., flutter analyze, flutter test, flutter build apk --debug, flutter build ios --simulator. Every command exited 134 before initialization with `../../runtime/vm/cpuinfo_macos.cc:42: error: unreachable code`. Logs are adjacent. Tests were attempted again after the new tests were written, with the same failure. No passing Dart formatting, analysis, tests, Android/iOS artifact or visual comparison is claimed.

Installed metadata: Flutter 3.13.9, Dart VM reports 3.1.5 stable macos_x64. Existing lockfile pins Riverpod 2.4.9, Dio 5.4.0, go_router 12.1.3, sqflite 2.3.0 and characters 1.3.0. Adding characters as a direct dependency requires pub get to refresh its lockfile classification; the lockfile was not fabricated.

Python source checks pass: protected files unchanged, PILOGY native names, portrait configuration, parseable XML/plist/asset JSON, eight routes, relative imports, and existing SQLite constraints (scripts/verify_foundation.py). Delimiter balance also passes; it is not a Dart parser or analyzer.

New tests cover Unicode formatting, preserved text, display deduplication, all-nine step rendering, ordinary/master values, native labels and resume month/year changes. Existing suites cover repository success/offline/no-cache/profile isolation/version/period boundaries, request identities and stale responses. These tests are unexecuted here. Existing widget assertions were updated for the deliberate capitalization changes.

Remaining: restore a compatible Flutter SDK; run all six commands; verify long Vietnamese text and calculation expressions at 360/390/430dp; inspect all eight screens, profile switching, offline cache and status timing on Android/iOS; record screenshots. No production API request or device test was performed for M05.
