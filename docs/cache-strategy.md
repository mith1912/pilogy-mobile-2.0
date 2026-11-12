# Cache strategy

M03 reuses pilogy_v1_local.db schema version 1 and CacheStore. No schema, table, legacy file or preference migration occurs. See local-data-migration.md for safety constraints. Local calculation data is private device cache despite the backend HTTP no-store policy; it never enters a public cache.

Calculations identify profile ID, random revision token, exact referenceDate, locale and calculationVersion; response includes contentVersion independently. findCalculation joins the current revision without assuming a deployed version or mutating context. It permits immediate **stale/unverified** offline fallback for the same date and profile input revision. Corrupt/schema-invalid cache is ignored and a network refresh is attempted.

The repository fetches config and definitions before preparing the request. Once a different calculationVersion is known, old numeric results stop being exposed and prepareCalculation expires the old context/cache. Unknown current versions are never inferred from cached data. A new contentVersion marks interpretation summaries stale independently; valid numerical values remain available while refreshing. A successful Calculate provides both current numbers and summaries. Versions that race between config and calculation fail safely and require manual refresh.

prepareCalculation captures current input and opaque revision in a transaction. Only its captured input goes into CalculateRequest. saveCalculation checks context/revision and rejects a late response after edit, delete, effective date/locale/version change, or clearCache. Profile updates invalidate earlier responses atomically. Cancellation also prevents disposed providers from writing fresh calculation results. One active context per profile is retained, as established by M02.

Articles use actual index value (including 11/22/33), locale and contentVersion. Exact version cache is preferred, with latest locally cached article as a labelled stale fallback if absent. New server content is saved under its returned version, never relabelled as a requested historical version. Old content versions may coexist. Public detail URLs are mutable and revalidated unconditionally on each load. No schema-v1 ETag persistence exists. Definitions/config are session/provider data, not new SQLite tables.

Current calendar date uses device local wall-calendar fields. A watched clock rechecks every 30 seconds and emits only changed dates, covering month/year rollover after resume within that interval. Explicitly selected dates bypass the clock and never undergo UTC conversion. Cache lookup requires the exact date, so earlier months/years cannot masquerade as the requested period. No period numbers are computed locally.


## M04 presentation lifecycle

The single selected calculation stream is retained across tabs to avoid repeated POSTs. Profile revisions, selection/date changes and manual refresh still rebuild its cancellation context. Clear Cache removes persisted bodies and suspends automatic recalculation for the current id/updatedAt identity (not a personal-data hash or cache fingerprint). Views become missing until Refresh, another revision or relaunch. Cached article families are invalidated as well. Database schema and random revision tokens are unchanged.

## M05 freshness and request handling

No schema migration or capitalization rewrite is performed. Raw responses remain intact. Existing schema version 1, random profile revision tokens, profile/date/locale isolation and calculation/content-version invalidation remain authoritative. The calendar provider checks local date immediately on resume and every 30 seconds; explicit dates are unchanged. Refresh taps during an existing calculation load coalesce. Full article success is held in memory for five minutes under the complete request identity, while explicit refresh can invalidate it. Version changes trigger a new request; V05 does not then redundantly invalidate that new load. Failures preserve useful same-identity cache with stale/error status.
