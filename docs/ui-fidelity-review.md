# UI fidelity review — M04.3

Scope: V04, V05, genuinely shared V03 header/refresh presentation, and native launcher icons. Source changes are implemented; **Flutter runtime/visual acceptance is blocked**. No pixel-perfect claim, device screenshot comparison or successful APK/iOS build is made.

## Authoritative reference and assets

Read `design_preference/design_pilogy.txt`, including the `V1-04: Phân tích (Tab 2)` and `V1-05: Chi tiết chỉ số` documents, their HTML layout, Tailwind tokens, inline SVG and prototype scripts. Original bytes are unchanged. There are no V04/V05 screenshots or standalone illustrations under design_preference/. Existing V03, shared design system, eight-route configuration and Riverpod calculation/article providers were inspected.

The source uses surface #fef7ff, white cards, purple #3a2b47, primary-container #51415f, gold #745a27, 20px page margins, 12px standard corners, Inter body/labels and Playfair Display headings/numbers. These existing tokens are reused. Native Material icon equivalents are used, without emoji. No production interpretation text was copied from design samples.

## V04 — Phân tích

Purpose: selected-profile numerology map with grouped indices and quick access to personal cycles.

Flutter: `lib/features/analysis/presentation/analysis_screen.dart` and `analysis_cards.dart`.

| Original difference | Correction |
| --- | --- |
| Generic header without profile switching | Shared Pilogy/V1 title, source-colored selector/avatar, real local selection |
| Persistent large update block | Event-driven three-second notice, compact fallback/error state, pull-to-refresh |
| Missing Pythagoras badge and selected identity hierarchy | Gold-dot badge, “Bản đồ Thần số học”, person icon/name/birth-date row |
| Missing two-card quick hub | White rounded “Biểu đồ ngày sinh” and gold-accented “Chu kỳ cá nhân” cards |
| Missing purple editorial highlight | Source-colored “TỔNG LUẬN NĂNG LƯỢNG CHÍNH” panel, with truthful unavailable content |
| Generic number cards | 56px/48px badges, source core/supporting labels, counts, spacing, white surfaces and smaller secondary copy |
| Separate cycle list absent from V04 source | Removed from page body; both actual cycle values remain available in the quick-access sheet |
| Missing deeper-index group | Source group and three labels shown as unavailable, never sample/locally calculated values |
| Simplified footer note | Source “Lời nhắc nhở Pythagoras” panel and static educational wording |

Order: profile/title → quick hub → editorial highlight → Nhóm Chỉ số Cốt lõi (Đường đời, Linh hồn, Nhân cách, Sứ mệnh) → Nhóm Chỉ số Bổ trợ (Ngày sinh, Thái độ, Trưởng thành) → Chỉ số Tiềm thức & Tâm linh → educational note. Counts and row labels match the source. Actual index values/base values and title/tagline/keywords come from existing typed responses. Master Numbers retain the existing formatter.

Index rows retain navigation to V05. Cycle quick access opens an in-scope sheet that watches the live selected-profile provider, rather than retaining a captured profile result. Both Personal Year and Personal Month can open their existing detail route. No ninth screen was added.

### V04 remaining data gaps

The API has no birth-chart matrix, combined-number editorial summary, harmony percentage, balance, karmic debt or missing-number output. Source geometry/labels are preserved where feasible, with explicit unavailable states and inactive unsupported controls. No sample 94%, sample numbers, fabricated prose or local formulas are used. The combined-summary CTA is not exposed without content. This is a deliberate functional difference, not a completed backend feature. Ads and premium unlocks remain excluded.

## V05 — Chi tiết chỉ số

Purpose: full Vietnamese article for the current selected profile's exact index value, with server-provided calculation steps.

Flutter: `lib/features/number_detail/presentation/number_detail_screen.dart` and `interpretation_article.dart`.

| Original difference | Correction |
| --- | --- |
| Generic header/body profile block | Contextual back/title, source overflow/avatar colors, “Hồ sơ chiêm nghiệm” context row |
| No multi-profile control | Shared selector in the profile-context row; this retains the source's title/back header rather than replacing it with V03 branding |
| Formula before number hero | Centered hero first, formula recap second |
| Plain oversized numeral | 96px gradient circle, serif numeral, original geometric ornament, centered backend title/subtitle/tagline |
| Generic chips | Source-style rounded keyword pills with actual backend keywords |
| Many unrelated outer section cards | Source's four outer sections: Ý Nghĩa Cốt Lõi & Sứ Mệnh; Điểm Mạnh Vượt Trội; Thách Thức Cần Cân Bằng; Lời Khuyên Pythagoras |
| Incorrect section surfaces/icons | 20px white section cards, source 32px icon tiles, pale strength rows, higher-lavender challenge rows, purple-container advice |
| Large persistent status | Shared transient article-update notice near the top; small retry/fallback presentation |

The profile-context spacing is 8px through an optional scaffold parameter; other callers keep their previous 24px default. V05 has no bottom tabs, matching its source. Contextual/system back and exact-type routes are preserved.

The formula recap expands all backend input/result steps. It never copies the source's mathematically inconsistent sample reduction or recomputes sums. The unverified “Bậc 1 chuẩn hóa” label is not asserted. Backend summary/essence/reflection are preserved in the meaning section; strengths/challenges retain full items. Advice retains suggestedAction and all remaining relationships, careerAndGrowth, lifeLesson, affirmation and optional periodFocus paragraphs, grouped within the source advice surface instead of adding unrelated outer cards. **No article paragraph has maxLines/ellipsis.** Only the source's profile-context text may truncate. Real article lengths naturally differ from the short prototype samples.

### V05 remaining assets and behavior gaps

The source's 144px editorial photo (“A peaceful minimalist scholar workspace at twilight…”, Google-hosted img in the meaning card) is not available as a local approved asset. It is omitted and recorded here; no unrelated image was generated or substituted. The geometric hero SVG is implemented natively using the source's circles/triangle coordinates. The journal demo has no specified persistence or route: its source card remains non-interactive with “Chức năng ghi chép chưa có sẵn.” No journal feature, new screen or storage schema was invented. Ads remain absent.

## Shared behavior and functional preservation

`profile_header.dart` extracts V03's existing profile sheet, pill, avatar and branding. `refresh_status.dart` extracts its compact state, transient update notice and refresh orchestration. V03 uses these shared components with the same labels, keys, colors, spacing, quote lifecycle and cards; it was not redesigned. V01/V02/V08/V09/V10 widgets are unchanged.

Notices require refreshing → fresh success, never merely a fresh value on normal render/navigation. They deduplicate a response event, collapse after three seconds, reserve no permanent space, clear on loading/error/identity changes and cancel timers on disposal. V04 listens to calculation refresh; V05 listens to article refresh to avoid duplicate calculation/article success banners. Cached/offline/error information remains visible independently of notices. Retry controls are separate from success status; there is no automatic retry loop.

SQLite/profile repositories, API models/client/repositories, cache/version/fingerprint logic, Firebase startup/configuration, application IDs, portrait settings and routes are unchanged. Profile switches still cancel/suppress old calculations. V05 derives the returned value anew and keys article presentation by profile revision/date/type; old requests cannot replace the new profile's numerical context. Public articles remain shareable by their existing type/value/locale/content-version identity.

## Launcher icon

Selected: `config/Assets.xcassets/AppIcon.appiconset/ItunesArtwork@2x.png` — opaque square 1024×1024, explicitly named app-icon artwork. It was visually inspected alongside config/logo.png; both use the same supplied Pythagoras/galaxy brand image. The square app-icon version avoids the rounded transparent corners in logo.png. All config originals remain byte-identical.

`scripts/generate_launcher_icons.py` mechanically resizes this approved artwork with macOS sips, without stretching, cropping, generative edits or a new Flutter dependency.

- Android: replaced all five legacy mipmap/ic_launcher.png files (48/72/96/144/192px); generated five 108dp-equivalent foreground densities; added mipmap-anydpi-v26/ic_launcher.xml plus inset/background resources. Foreground inset is 16.666667% per edge (72dp artwork region within 108dp) to protect important marks under adaptive masks. Background #18193E is sampled from the approved image's corner. Manifest already references @mipmap/ic_launcher and was preserved.
- iOS: replaced all 15 unique files used by the 19 AppIcon catalog entries, including the 1024px marketing icon. Each size is checked against Contents.json; every output is opaque RGB, with no alpha/tRNS. The 1024px icon is byte-identical to the approved source. Existing AppIcon build settings remain correct.
- Outdated Flutter icons were overwritten; no config asset was deleted. Identifiers remain mt.numerology. Generated PNGs were inspected as assets; launcher appearance on an actual device is not verified.

## Testing and verification

Authored `test/v04_v05_ui_test.dart` covers 360/390/430dp layouts; V04 source section order/counts/quick cycle access; V05 hero-first order/full untruncated paragraphs/steps/no tabs; one/multiple profiles; real view-model selection using injected fake repositories; stale result/article suppression; exact Master values; and three-second notice expiry without rebuild repeats. Existing V01/V03 regression tests retain their keys and assertions. These Flutter tests remain **unexecuted** here.

Actual checks:

| Check | Result |
| --- | --- |
| flutter pub get | Aborted at VM initialization |
| dart format . | Aborted; formatter did not run |
| flutter analyze | Aborted before analysis |
| flutter test | Aborted; no test assertions executed |
| flutter build apk --debug | Aborted; no new APK produced |
| flutter build ios --simulator | Aborted; no new simulator build produced |
| Python foundation checks | Passed identifiers, preserved reference/config/native Firebase copies, eight routes, imports, SQL constraints |
| Mechanical delimiter check | Passed bracket/string balance only, not Dart parsing/type checking |
| Icon packaging/resource checks | Passed all output dimensions, iOS opacity, catalog/manifest links and adaptive XML parsing |
| xcrun simctl list devices available | Failed: CoreSimulatorService unavailable/permission restrictions |

The installed executable still aborts at cpuinfo_macos.cc:42 (Dart 3.1.5, Flutter metadata 3.13.9). Existing pubspec.lock/package configuration is preserved; no dependency upgrade was introduced. Per-command logs, icon-source checksums, catalog filenames and scope checks are under `docs/verification/m04-3/`.

**No V04/V05 screenshots were captured or compared.** Source/CSS comparison and icon-asset inspection do not establish rendered pixel accuracy. Phone-width assertions, safe areas, large text, press states, icon adaptive masks, route restoration and physical-device rotation require execution after SDK/platform recovery. CSS backdrop/inner-blur effects remain approximated by native surfaces, gradients and shadows; the source gold inner blur is not reproduced exactly. Existing unbundled font assets remain a release limitation. Do not treat pre-existing build artifacts as builds of this change.

## Files changed

Modified application sources: analysis_screen.dart, number_detail_screen.dart, discover_screen.dart (shared extraction only), core/presentation/pilogy_scaffold.dart (optional spacing).

New application sources: analysis/presentation/analysis_cards.dart; number_detail/presentation/interpretation_article.dart; numerology/presentation/profile_header.dart; numerology/presentation/refresh_status.dart.

Native resources: five Android legacy PNGs, five new foreground PNGs, three adaptive/background XML files, and fifteen iOS AppIcon PNGs. Contents.json and application identifiers remain unchanged.

Added: scripts/generate_launcher_icons.py, test/v04_v05_ui_test.dart, this review and verification/m04-3 evidence. No backend source, config originals, dependency declaration, Firebase file, profile/schema/API contract or other full-screen implementation was changed. M05 was not started.

## M05 — content and text consistency

The authoritative reference remains `design_preference/design_pilogy.txt`. Existing eight layouts, V01 fixed bottom actions, V03 core row, V04 cards, V05 article hierarchy, shared headers, portrait settings and approved icons are preserved. Only text presentation, server-step labels and existing interpretation content rendering were refined. No new screenshots were captured or compared in M05. Visual status: IMPLEMENTED_NOT_VISUALLY_VERIFIED, including 360/390/430dp overflow and long-content scrolling. Flutter analyze/test/build are BLOCKED before startup (logs in `verification/m05/`). Existing missing/excluded design behaviors recorded above remain unresolved; no substitute full screens were added.
