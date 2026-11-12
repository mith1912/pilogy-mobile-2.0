# M04 screen flows and implementation

Status: all eight native Flutter screen widgets and their local/API flow wiring are implemented. Dart/Flutter executable verification is blocked; **this is not a tested release build**. The actual reference is `design_preference/design_pilogy.txt`; `design_reference/design_pilogy.txt` does not exist. The complete eight-document reference, shared CSS/tokens, controls and prototype scripts were inspected. It remains unchanged. Backend contracts remain ../api/numerology-api/docs/api-contract.md and docs/openapi.yaml; optional docs/flutter/api-handoff.md is absent.

## Navigation decisions

The Stitch prototype leaves Start, post-save, returning-user and detail routing unwired. M04 explicitly requests functional transitions; the following choices implement that request without adding screens:

- Startup awaits local preferences and an SQLite snapshot. No profiles → V01. A selected profile → V03. Profiles without selection → V08. Local startup failure shows a retry state rather than guessing that the database is empty.
- V01 Start → V02. Its saved-profile action opens a local-profile bottom sheet; selection is persisted and Open leads to V08.
- V02 validates and saves through ProfilesViewModel/ProfileRepository, selects the saved profile, then opens V03. Thus existing profiles added or edited in V02 become the current profile. First save retains M02's local behavior; no profile goes to Firebase.
- Tabs use V03/V04/V08. Detail/form/settings/privacy use push and contextual back; direct-open fallbacks are V04 for detail, V01 for a new form, and V08 for editing/settings/privacy.
- V03/V04 cards open V05 with only a validated index type in the URL. V05 derives the current profile's actual returned value, including Master Numbers, instead of accepting a potentially stale value/result from navigation extras.
- Editing uses a necessary random local profile ID in the edit query; no names, dates, request/response bodies or interpretation text are placed in URLs. Missing edited profiles show an empty state; invalid index types do not make API calls.
- MaterialApp and GoRouter have restoration scopes. Selected profile restoration uses SQLite. Platform route restoration and Android/iOS back gestures still require device execution.

## Per-screen implementation

| Screen | Layout and data | Supported actions |
| --- | --- | --- |
| V01 Chào mừng | Branding, headline, editorial panel, three value cards, two CTAs | Start form; local profile drawer; saved-profile management |
| V02 Tạo/Chỉnh sửa hồ sơ | Accuracy guide, name, three-part Gregorian date, local-storage note, save/cancel/delete | Validation, SQLite save/select, contextual cancel, confirmed deletion |
| V03 Khám phá | Selected identity/date, freshness, purple Life Path hero, inner-profile cards, personal year/month, analysis CTA | Refresh, exact-value detail, analysis/tab navigation |
| V04 Phân tích | Identity/freshness, four core indices, three supporting indices, personal cycles, educational note | Refresh, index detail, tabs |
| V05 Chi tiết chỉ số | Calculation steps expansion, article freshness, number/title/subtitle/tagline/keywords, backend article sections, application advice | Full article fetch/cache/retry, selectable text, step expansion, contextual back |
| V08 Hồ sơ | Count, selected profile spotlight and available actual metrics, local profile cards, add/settings/privacy | Select, add, edit, confirmed delete, view analysis |
| V09 Cài đặt | Selected profile, profile/privacy links, reminder preference, Vietnamese/light status, method expansion and legal/support availability | Persist reminder preference only; profile/privacy navigation; method expansion |
| V10 Quyền riêng tư & Dữ liệu | Local/API explanation, measured SQLite allocation and cache counts, export/cache/delete controls | Confirmed JSON export via native save/share UI; cache clear; transactional delete-all |

All screen widgets live under existing feature directories. PilogyScaffold shares safe-area/scrolling/keyboard dismissal, bounded phone content width, 20px side margins, contextual headers and three-tab navigation. EditorialPanel/InfoPanel/ActionRow reuse the existing palette and text theme. NumberCard, DataStatus, CalculationContent and CalculationSteps share result presentation. Badges fit long Master values; text outside badges wraps and supports system scaling. No raw HTML/WebView, emoji or new color/font palette is used.

## Data and freshness

The existing M03 repositories perform all HTTP/model/cache operations. A kept-alive selected-calculation stream avoids a new POST on each tab change while still rebuilding/cancelling for profile revisions and reference dates. UserProfile value equality avoids refreshes caused solely by reading an unchanged selected record. SQLite random revision/context tokens remain authoritative; object hashCode is not a fingerprint or analytics identity.

CalculationContent strips old results during selection changes and handles no selection, loading, missing cache, errors and usable fallback. DataStatus displays refreshing/current/cached/unverified/offline states and safe Vietnamese messages, with manual refresh. HTTP 429 remains subject to M03 Retry-After cooldown; no automatic retry loop exists. Detailed articles use exact returned values and preserve all Vietnamese sections. Calculation explanation renders server-provided steps, without computing sums or reductions.

Cache clear also clears presentation state and pauses automatic recalculation for the current profile revision, so hidden result views do not immediately refill the cache. Explicit Refresh, a different profile revision, or relaunch permits loading again. Delete-all is one SQLite transaction, with foreign-key cleanup of selected profile and private calculations; public article cache remains until Clear Cache. No legacy file or preferences clearing occurs.

## Export and preferences

Only after confirmation does JSON export serialize the actual local profiles, never fixtures or interpretations. Android uses ACTION_CREATE_DOCUMENT and writes UTF-8 to the selected URI without broad storage permission. iOS uses a temporary protected JSON file and UIActivityViewController, removing the file after completion/cancellation. Both bridges return fixed errors and never log payloads. OS UI file delivery remains untested on a device. No cloud backup/import is claimed.

The reminder switch stores `pilogy.v1.reminder_preference` in shared_preferences. Its subtitle explicitly says nothing is scheduled. It requests no notification permission and sends nothing. Existing preference keys are neither cleared nor repurposed. Startup failure can retry preferences/storage. Firebase startup remains the existing M02 path, collection defaults off; M04 adds no telemetry.

## Explicit design and product gaps

- Exact Stitch colors are pale lavender #fef7ff, deep purple #3a2b47 and muted gold #745a27, rather than replacing them with an approximate cream palette.
- Stitch sample quotes, harmony percentages, energy meters, combined-number narratives, birth chart, balance/karmic/missing-number indices are not supplied by the API. They are not fabricated or exposed as functional features.
- V02 salutation lacks an authorized persistent field. Local storage is required, so a prototype opt-out checkbox and demo create/edit switch are not presented. Name/date and local-storage explanation remain.
- V05 journal is a demo alert with no storage/navigation specification; no journal action or ninth screen is added. M05 can refine Master education and step labels/layout without adding formulas.
- Only light styling and Vietnamese content are specified. Unsupported dark/auto controls are replaced by explicit light status. Reminder preference is persisted but scheduling is not implemented. FAQ/legal/store/share URLs are absent; unavailable content is stated without active broken CTAs or guessed URLs.
- External editorial photos lack bundled/licensed assets and cannot be fetched in this environment. Native decorative panels/icons occupy the visual areas; no claim of pixel-perfect image reproduction is made. Bundled Inter/Playfair assets and visual screenshot comparison remain release work; current google_fonts offline fidelity is not guaranteed.
- AdMob reference was read and preserved, including the iOS banner value that appears to be an app-ID-shaped value. No ID was corrected or copied into UI. No SDK, initialization, ad request, production ad placeholder, payment or premium unlock was added. M06 owns ads.
- Backend Birthday 11/22 articles are still absent upstream; safe errors are shown instead of invented/base-value text. Backend content remains draft.
