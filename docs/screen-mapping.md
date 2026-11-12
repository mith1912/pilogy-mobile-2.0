# Current M04 mapping

The eight paths in the table below remain the complete route scope. [M04 screen flows](m04-screen-flows.md) documents their current implementation and the transitions authorized by the M04 functional-flow request. Start opens V02; save/select opens V03; returning selected profiles open V03, existing unselected profiles V08, empty storage V01. Index cards open V05 with the current selected profile's actual value. Earlier M01 restrictions on unwired transitions below describe historical evidence, not the current M04 authorization.

# V1 screen mapping

Source: `design_preference/design_pilogy.txt`, eight concatenated HTML documents. Source labels use V1-01 etc.; requested IDs below normalize those labels. Routes now host native M04 screen implementations; executable acceptance is blocked. Titles retain the reference's wording; route names are implementation choices, not source URLs.

| ID | Reference title / visible title | Purpose | Path | Route name |
| --- | --- | --- | --- | --- |
| V01 | Chào mừng / Thấu hiểu bản thân qua Thần số học Pythagoras | Introduce app; start action and local saved-profile drawer | `/welcome` | `welcome` |
| V02 | Tạo hồ sơ / Tạo Hồ Sơ Mới | Create or edit name, Gregorian birth date, salutation; local save and delete confirmation | `/profile-form` | `profileForm` |
| V03 | Khám phá (Tab 1) / Xin chào, Minh Anh | Selected-profile overview, life path, core numbers, current cycles | `/discover` | `discover` |
| V04 | Phân tích (Tab 2) / Bản đồ Thần số học | Groups of core, supporting, and deeper indices; detail sheets | `/analysis` | `analysis` |
| V05 | Chi tiết chỉ số / Chi Tiết Chỉ Số Thần Số Học | Detailed meaning, strengths, challenges, advice for an index | `/number-detail` | `numberDetail` |
| V08 | Quản lý hồ sơ / Hồ Sơ | Select, add, edit, delete locally saved profiles; settings/privacy entries | `/profiles` | `profiles` |
| V09 | Cài đặt | Preferences, profile/data links, information, support/legal entries | `/settings` | `settings` |
| V10 | Quyền riêng tư & Dữ liệu / Quyền Riêng Tư & Quản Lý Dữ Liệu | Explain local storage/API; JSON export, cache clear, delete-all confirmation | `/privacy-data` | `privacyData` |

## Original prototype navigation evidence and gaps (historical)

- Bottom tabs explicitly show Khám phá, Phân tích, Hồ sơ: V03, V04, V08. Their anchors mostly use `#` with semantic data-path values; the prototype does not supply production routes.
- V03's analysis CTA explicitly clicks the analysis tab in JavaScript: V03 → V04.
- V08 visibly offers edit, view analysis, add profile, settings, and privacy/data actions. These correspond semantically to V02, V04, V02, V09, V10; links are placeholders, so completion behavior/arguments are unspecified.
- V09 offers saved-profile management and privacy/data, corresponding semantically to V08 and V10. Links are placeholders.
- V02, V05, V10 use `history.back()`; preserve contextual back behavior when implemented.
- V01 start only animates its button; no destination is wired. Its saved-profile action opens an inline drawer, not a separate screen. Do not assume a redirect after start/restore.
- V02 submit shows a toast only; create/edit are demo modes. Post-save destination is unspecified.
- V04 index clicks open a detail bottom sheet. Despite V05 existing, no explicit V04 → V05 route is wired. M01 should expose V05 as a direct placeholder route without inventing a transition.
- V04 birth-chart/cycle actions are sheets, not evidence for extra routes. V05 journal action is a demo alert, not authorization for another screen.
- Initial location `/welcome` is the documented M01 placeholder choice; returning-user redirects, deep-link parameters, invalid-profile handling, tab history, and save/restore transitions need decisions before full implementation.

M01 implements exactly eight minimal feature placeholders with IDs/titles, an unknown-route state, and the explicit V03 → V04 CTA. No speculative transitions, returning-user redirects, tab history, or synthetic profile parameters were added. Each path/name and the CTA have authored widget tests; execution remains blocked by SDK startup.

## Conflicts requiring implementation discipline

Prototype sample dates/numbers vary between screens. V05 includes an internally inconsistent sample reduction (`2 + 0 = 7`); these are not calculation rules or fixtures. V02 JavaScript calculates locally, while V01 claims offline calculation. Follow the task: calculate only through the backend. “Sync” labels must mean content/result refresh, never cloud profile synchronization. Ads, premium unlock copy, journal destination, FAQ/legal destinations, and dark theme details are outside M01. Do not promise encryption, backend retention behavior, or third-party guarantees without verifying them.

## Backend coverage discovered during correction

Read `../api/numerology-api/docs/api-contract.md`, `docs/openapi.yaml`, and `docs/flutter-integration.md`. Backend indices are lifePath (Đường đời), soulUrge (Linh hồn), personality (Nhân cách), expression (Sứ mệnh), birthday (Ngày sinh), attitude (Thái độ), maturity (Trưởng thành), personalYear, personalMonth. V04 also shows balance, karmic debt, missing numbers, birth chart and other visual claims not supplied by this contract. Do not calculate or synthesize them in Flutter. V03 “energy intensity” and V04 “94% harmony” are also unsupported sample metrics. Resolve coverage with product/backend before actual screen implementation. Birthday master 11/22 articles are missing: full lookup returns 404 and calculation can fail with 500 INTERPRETATION_CONTENT_MISSING. Treat that as unavailable content, not a fallback to base-value text.
