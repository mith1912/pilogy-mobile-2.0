# Offline behavior

Local profiles and selection remain SQLite-owned and available without the API or Firebase. Repositories expose streams of DataSnapshot<T>; Riverpod adds AsyncValue loading and provider-level errors.

| State | Meaning |
| --- | --- |
| AsyncLoading | Waiting for profile/date/storage or first snapshot; previous profile data is suppressed |
| missing + refreshing | No matching local data; requesting backend |
| stale + refreshing | Same-input/date calculation cache, but current versions not yet verified |
| cached + refreshing | Article matches the requested content version; checking mutable URL |
| fresh | Successful validated response from this load |
| stale + error | Cached fallback retained; freshness could not be established |
| missing + error | Required data is unavailable; show error/retry UI |
| missing without error | No selected profile; show an empty state |

`refreshing` does not erase visible matching cached data. `error` is independent of data; offline is true for connection/timeout failures, not proof of device-wide network state. HTTP errors are exposed separately, including missing editorial content. cachedAt records persisted retrieval time; fresh results need not have a cachedAt until read back. contentStale distinguishes outdated/unknown editorial metadata independently of numeric values.

Consumers must render safe application error messages rather than stringify exceptions or payloads. No results or article sections are fabricated. Selecting another profile cancels the previous subscription/request, strips retained AsyncValue data and starts a new cache identity. An explicit refresh performs one attempt; 429 cooldown prevents immediate manual repeats. There is no background automatic retry, connection probe dependency or local calculation engine.

M04 must compose visible loading/offline/stale/missing/error/refresh controls using the existing design system. Exact appearance of those states, missing Birthday 11/22 articles, unsupported Stitch-only indices/charts/journal behavior, and export/restore flows require design/product decisions; no new screen flow is invented here.

## M05 refinement

Same-profile, same-revision, same-date cache remains visible during refresh and transient backend failures. Stale/unknown deployed versions are not represented as fresh. Offline no-cache UI explains that an initial connection is needed for the selected profile/date and offers retry. No previous-month data is substituted. Edits, selection changes and cancelled requests retain the existing identity protections. Article contentVersion changes use distinct cache/provider keys. Successful article provider state is retained for five minutes; unsuccessful loads are not pinned. There is no automatic retry loop. Offline widget/repository test execution remains blocked by the Dart VM startup crash.
