# Local data migration and published-app safety

Android application ID and iOS Bundle Identifier remain mt.numerology. A published app using these IDs may already have private device data. This task does not authorize its deletion or a guessed import.

## Evidence inspected

The legacy sibling ../Numerology/ contains a Flutter app. Searching its lib/ found setting_repo_impl.dart using shared_preferences key PREF_INTERSTITIAL_AD, but no reliable profile SQLite schema, database filenames, or migration documentation. That is not proof that deployed versions never stored profiles: deployed behavior can differ from available source. Do not infer a migration from absent evidence. Backend ../api/numerology-api/ is stateless and cannot restore profiles.

M01's draft schema used pilogy.db, version 1. M02 does not open, drop, overwrite or upgrade that file. It uses the distinct new filename **pilogy_v1_local.db**, version **1**, within the platform database directory. Even M01 test data is left intact. No database scanning, guessed profile import, preference clearing, legacy key reset, or uninstall/reinstall is performed.

## Current safety behavior

Only a fresh new namespace is created. A pre-existing file in that new namespace is opened using its own version; unknown older/newer migrations fail closed without a destructive fallback. Future migrations must be explicit, incremental, transactional, tested against real fixtures, and preserve rollback safety before raising schemaVersion. Do not use onDatabaseDowngradeDelete or deleteDatabase as an error-recovery shortcut.

No automatic conversion from old tables, old selected-profile preferences or old cached numerology responses exists. No legacy preferences are cleared by profile operations. Firebase initialization clears only telemetry user identity after matching existing Firebase configuration, not application preferences/profile data.

## Before a published-app upgrade

Obtain database/preferences schemas and representative fixtures from actual shipped Android/iOS versions, identify authoritative data ownership/versioning, and design an independently reviewed import with backup/recovery and explicit user-visible semantics. Check compatibility with any previous Firebase collection settings and existing signing/application versions. Until that evidence exists, legacy profiles remain untouched and may not appear in the new local profile list.

Tests author a sibling legacy file with a marker and verify it survives operations in the new file. Unknown-future-schema tests check refusal without deletion. Their Flutter execution is currently blocked; offline Python tests verify current schema constraints only, not installed-device migration behavior.
