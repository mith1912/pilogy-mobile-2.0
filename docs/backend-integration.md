# Backend integration — M03

M03 implements a reusable data layer, with executable verification blocked as recorded in [verification](flutter-api-verification.md). The source of truth is `../api/numerology-api/`: docs/api-contract.md, docs/openapi.yaml, docs/flutter-integration.md, actual route handlers and validation/types. The optional docs/flutter/api-handoff.md is absent. The actual Stitch file is design_preference/design_pilogy.txt; design_reference/ is absent. No route or screen architecture was changed.

Production uses `https://pilogy.vercel.app/api/v1`. Example overrides:

```sh
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

The first host maps Android Emulator to its host machine; the second is for an iOS Simulator on that host. Physical devices need a reachable HTTPS endpoint. Loopback addresses do not refer to the development computer from a device. Existing environment validation rejects remote HTTP, credentials, queries and fragments. Native cleartext transport policies still apply; this task does not weaken them. TLS certificate checking remains enabled.

`createDio` accepts configurable connect/send/receive Durations, defaulting to 10/10/20 seconds. `apiClientProvider` reuses `dioProvider`, relative paths preserve the /api/v1 prefix, and all operations accept CancelToken. The client decodes the success envelope and emits safe ApiFailure metadata. No interceptor logs bodies, paths containing personal data, names, dates, cached responses, or raw exceptions; no new telemetry calls exist.

| Method and path | Consumer | Typed data |
| --- | --- | --- |
| GET health | ConfigRepository.health | HealthResult |
| GET config | ConfigRepository.config / backendConfigProvider | BackendConfig |
| GET numerology/definitions?locale=vi | ConfigRepository.definitions / definitionsProvider | DefinitionsResult |
| POST numerology/calculate | NumerologyRepository.watch | CalculationResult |
| GET numerology/interpretations/{type}/{value}?locale=vi | InterpretationRepository.watch | ArticleResult |

Only calculation POST transmits transient personal inputs. IDs/revision tokens never leave SQLite. CalculateRequest always supplies an explicit date-only referenceDate. No deprecated targetDate alias is sent.

HTTP 400/404/413/415/422/429/500/502/503 retain status and allowlisted backend error codes. HTML/text gateway or firewall failures do not enter success parsing. Timeout, connection/DNS/TLS, cancellation and malformed schema/JSON are distinct ApiFailureKind values. `apiErrorMessage` supplies safe Vietnamese UI text. Error details/raw server messages are deliberately not retained. 429 retains Retry-After seconds or HTTP-date; the shared API client blocks new requests until that deadline (30 seconds when absent/invalid). No automatic retries exist. UI can offer manual refresh after the deadline; invalid requests never retry automatically.

Public articles and definitions currently use unconditional GET revalidation. No If-None-Match is sent without a persistent validator/body mapping; unexpected bodyless 304 is a safe malformed response. This avoids a schema migration and always gets current version metadata. ETag bandwidth optimization requires a future explicit tested migration. Public config is fetched live and not stored in shared_preferences. API availability failures preserve local profiles and matching cache.

M04 consumers watch selectedProfileCalculationProvider and fullInterpretationProvider. Refresh with refreshSelectedCalculation(ref), or invalidate an article family/config provider. Read freshness, refreshing, error, offline, cachedAt and contentStale as well as data; never label unknown-version cache as current. The selected calculation wrapper strips retained Riverpod values during identity changes. Profile switching/editing, date changes and provider disposal cancel old work; SQLite guards reject writes invalidated by edits/deletion/period changes/cache clear.
