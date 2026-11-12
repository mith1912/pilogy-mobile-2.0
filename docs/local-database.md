# Local database (M02)

`lib/services/storage/local_database.dart` lazily opens **pilogy_v1_local.db**, schema version **1**, through sqflite on Android/iOS. Tests inject a DatabaseFactory and temporary filesystem path using sqflite_common_ffi. This is a distinct namespace from M01's pilogy.db and unknown published-app databases. No legacy file is opened, removed, renamed, or migrated.

All foreign keys are enabled in onConfigure before schema creation. onCreate runs in sqflite's creation transaction. Unknown upgrade/downgrade paths fail closed; implement tested incremental migrations before increasing schemaVersion. Database opening is shared between concurrent callers, failures permit a later retry, and disposal closes the handle. A closed instance is not reopened; create a fresh LocalDatabase instance.

## Schema

SQL source is the canonical full schema. All IDs below are TEXT. Profile/cache/context/revision IDs use UUID v4 with explicit CryptoRNG; timestamps use UTC ISO-8601. Birth/reference dates are Gregorian date-only values.

| Table | Fields and constraints |
| --- | --- |
| user_profiles | id PRIMARY KEY; full_name, birth_date, created_at, updated_at NOT NULL; birth_date format CHECK |
| calculation_cache | id PRIMARY KEY; profile_id NOT NULL FK → user_profiles ON DELETE CASCADE; calculation_version NOT NULL; nullable content_version; reference_date, locale, input_fingerprint, response_json, cached_at NOT NULL; unique profile/version/reference-date/locale/fingerprint |
| interpretation_cache | id PRIMARY KEY; index_type, number_value, locale, content_version, response_json, cached_at NOT NULL; unique index_type/number_value/locale/content_version |
| app_state | singleton id=1; nullable selected_profile_id FK → user_profiles ON DELETE SET NULL |
| profile_cache_revisions | profile_id PRIMARY KEY FK ON DELETE CASCADE; random revision_token NOT NULL |
| calculation_contexts | profile_id PRIMARY KEY FK ON DELETE CASCADE; context_id, input_fingerprint, calculation_version, reference_date, locale NOT NULL |

`user_profiles` has exactly the five requested fields, with no numerology results. Repositories validate real Gregorian dates (including leap years, years 0001–9999) beyond SQLite's lexical format CHECK. Direct raw SQLite writes are not a substitute for repository validation.

## Cache behavior

`CacheStore.prepareCalculation` captures the profile input and revision in one SQLite transaction. Future M03 calls must use context.profile, context.referenceDate and context.locale, not a separately fetched input snapshot. It removes obsolete private cache entries when calculation version, effective reference date, locale or input revision changes. Exact reference dates are used, rather than guessing a month/year cache boundary.

`input_fingerprint` is an opaque cryptographically random local revision UUID, unrelated to name/birth-date bytes. No raw/salted hash, device analytics ID, HMAC secret, or stable cross-installation identity is needed. Editing a name/date rotates the token and deletes calculation/context records atomically. A no-op update leaves cache untouched. This is the task's alternative safe invalidation strategy, not a deterministic digest of inputs.

`saveCalculation`/`readCalculation` compare context ID, version/date/locale and current revision in a transaction. Stale in-flight responses after edit/delete/period changes/cache clear are rejected. Preparing an identical context preserves its result. Only one active calculation context is retained per profile. The raw successful response JSON can contain sensitive data and stays local. M03 must decode/validate successful API envelopes and match metadata before passing them to this store; M02 only checks JSON-object syntax and stores opaque responses.

Interpretations are profile-independent and reusable across all profiles. Saving the same versioned key replaces its body while preserving its UUID; different content versions coexist. Master values remain distinct from base values. Index types match the nine backend camelCase IDs; locale currently vi. `clearCache` removes calculation entries, contexts and interpretations while preserving profiles, selection and revision tokens. Removing contexts prevents late in-flight calculations from repopulating cleared cache.

ETag validator/current-URL metadata and HTTP 304 handling belong to M03; no automatic network fetches or interpretation cache population occur here. A later schema change for validators requires an explicit migration.

## Errors and tests

Repository/cache entry points use LocalDataException with fixed kinds and safe field identifiers. They discard raw SQLite/IO/platform exception messages instead of sending SQL or bound personal data to UI/telemetry. Form/list components display safe Vietnamese messages and preserve input on failure. Native initialization errors also do not disable offline profile storage.

Dart FFI tests cover schema version, CRUD, multiple profiles, reopen persistence, selected profile, invalid names/dates, leap years, Unicode, timestamp behavior, cache invalidation, stale writes, shared articles, foreign keys/cascades, unknown schema protection and legacy-file preservation. They require no Firebase connection. Flutter execution remains blocked by the installed SDK; Python SQLite checks execute the actual schema separately and do not prove Dart repository behavior. See docs/verification/m02/.


## M03 population

Schema remains version 1. NumerologyRepository validates and stores the successful data object as JSON through prepareCalculation/saveCalculation; findCalculation reads only current input revisions for the exact date/locale without guessing a deployed version. InterpretationRepository populates existing versioned article rows and uses latest-article lookup for labelled stale fallback. No new database, table, preferences key or destructive migration is introduced. Public URL validation uses unconditional GET rather than persistent ETags; cache-strategy.md documents this decision. Dart execution remains blocked as recorded in flutter-api-verification.md.
