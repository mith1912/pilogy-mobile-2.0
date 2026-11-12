# Portrait, V01 and V03 UI fix

Scope: V01 and V03 presentation plus global portrait configuration. No backend, calculation model/repository, SQLite/cache behavior, Firebase configuration, dependency declaration or other screen widget was changed. Shared hooks are optional and preserve existing defaults.

## Reference review

Compared the V01 and V03 HTML/CSS in `design_preference/design_pilogy.txt` with the Flutter source. The reference is preserved byte-for-byte. This directory contains only the text reference, with no screenshots or image assets. The requested alternate spelling `design_peference/` and `design_reference/` do not exist here. This is a source comparison, **not rendered screenshot verification**.

V03 source values used: surface #fef7ff, white cards #ffffff, primary #3a2b47, gold #745a27, container #f3ebf9, outline #7b757d and variant #4a454c. Existing Inter/Playfair typography is reused. The Life Path card uses 24px padding/16px corners; core cards 14px padding/12px corners/10px horizontal gaps; cycle cards 16px padding/12px corners/10px vertical gaps.

## V01

The existing main content stays in the scrollable body. The two CTAs now occupy Scaffold.bottomNavigationBar via an optional bottomActions hook, outside the ListView. SafeArea, bottom padding and keyboard inset padding keep the buttons separate from system UI and scroll content. The primary button has a 52px minimum height; the secondary uses the source's 44px visual minimum and the Material padded touch target. Text scaling can grow buttons instead of clipping text. The source's 8px gap, 12px corners, purple primary and lavender-filled secondary are applied. Existing create and local saved-profile drawer actions are retained.

## V03

- Header: Pilogy/V1 branding, a lavender “Hồ sơ chính” pill for multiple profiles, gold account icon and chevron, and a 32px purple avatar with white person icon. The avatar retains a 48px touch target. Borders are absent as in the source. Press/hover styles use existing tokens. Scrolled-under tint is disabled for this header only.
- The switcher mounts the existing ProfileList. A new optional onSelected callback closes the menu after the existing persisted selection command succeeds. Existing selected-result cancellation/cache guards suppress the previous profile's results; no new selection or networking implementation was added.
- The redundant name/birth-date result block is disabled only in Discover. Greeting formatting follows Nguyễn Minh Anh → Minh Anh; the canonical stored/request name is unchanged. Greeting and reflection remain available while results load or are missing offline.
- Twenty original, non-predictive Vietnamese reflections are selected randomly once in State.initState. Ordinary widget/provider updates do not reroll them; another screen session may choose another reflection.
- Successful refresh transitions produce a small non-interactive “Đã cập nhật” notice above the greeting. It collapses after three seconds, reserves no permanent space, does not appear merely because an already-fresh screen renders, and clears when selection/loading/error changes. The listener requires refreshing → fresh success and deduplicates the snapshot. Timer/subscription work is cleaned up on disposal.
- Pull to refresh reuses refreshSelectedCalculation and waits for the existing presentation stream to complete. Cached/offline/error/version-warning states retain a compact message and manual retry. No automatic retry was added.
- Life Path: white card, subtle source circle, exact “Con Số Đường Đời” heading and original “Năng lượng cốt lõi” header badge, gold number aligned beside the backend title/subtitle, and backend summary with maxLines: 4/ellipsis. Keyword chips are removed. “Xem chi tiết” and its existing navigation remain.
- Core section: exact “Bộ Ba Chỉ Số Cốt Lõi” / “Tổng hòa danh xưng” labels. Three equal-width cards remain in a horizontal row in source order: Linh Hồn (soulUrge), Nhân Cách (personality), Sứ Mệnh (expression). The backend's first keyword provides the short heading and its tagline the brief description; an empty keyword list uses the backend subtitle. All values use the existing Master formatter.
- Cycles: exact “Chu Kỳ Rung Động Hiện Tại” heading, right-aligned Năm {year}, Năm Cá Nhân and Tháng Cá Nhân labels. Year/month come from the displayed result's referenceDate without timezone conversion. Values/taglines come from the backend. Existing detail navigation remains.

## Portrait configuration

Flutter awaits SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]) before Firebase startup/runApp. Android MainActivity declares screenOrientation="portrait". iPhone and iPad supported-orientation arrays contain portrait only. iPad UIRequiresFullScreen is enabled to support the portrait-only policy. Android namespace/applicationId and iOS bundle ID remain mt.numerology. Runtime rotation still needs testing on both platforms; no device rotation test was performed here.

## Changed files

Existing:

- lib/main.dart
- lib/core/presentation/pilogy_scaffold.dart — optional fixed actions/header/pull-refresh hooks
- lib/features/numerology/presentation/calculation_widgets.dart — optional profile/status presentation hooks
- lib/features/profiles/presentation/widgets/profile_list.dart — optional successful-selection callback and stable selection keys
- lib/features/welcome/presentation/welcome_screen.dart
- lib/features/discover/presentation/discover_screen.dart
- android/app/src/main/AndroidManifest.xml
- ios/Runner/Info.plist

New:

- lib/core/config/app_orientation.dart
- lib/features/discover/presentation/discover_cards.dart
- lib/features/discover/presentation/discover_quotes.dart
- test/v01_v03_ui_test.dart
- This report and docs/verification/v01-v03-fix/ evidence

The other six screen files, services, domain/data repositories, config originals and design reference hashes match their pre-fix snapshots. Database schema and random revision-token behavior are untouched.

## Tests and actual verification

Focused widget tests are authored for portrait platform-channel setup; V01 fixed actions at 360/390/430dp on a short screen with safe-area and simulated keyboard insets; V03 horizontal core geometry, Master display, four-line description/no keyword chips; quote stability and three-second notice expiry after refresh; one/multiple profile menus; persisted selection through the real view model with a fake repository; suppression of old in-flight results; offline missing data; and a 2027 reference year/month. These assertions have **not executed** in this environment.

Attempted flutter pub get, dart format ., flutter analyze, flutter test, flutter build apk --debug and flutter build ios --simulator. All abort before initialization with the installed Dart VM cpuinfo_macos.cc:42 failure (Dart 3.1.5; Flutter metadata 3.13.9). Formatting did not execute. No new APK or simulator build was produced by these attempts; existing build artifacts are not verification of this fix.

Unlike the earlier milestone environment, pubspec.lock and .dart_tool/package_config.json now exist from prior work. Their presence is not a successful dependency resolution during this task. Actual lockfile versions are recorded in verification/v01-v03-fix/locked-versions.json; dependency files were not edited.

The Python foundation checks pass, and native XML/plist checks confirm matching portrait declarations. Scope/hash checks confirm configuration/reference preservation and unchanged non-UI data layers/other screens. These source checks do not establish Dart compilation, layout rendering, orientation behavior or device acceptance. Per-command logs and source-checks.json are in the verification folder.

## Remaining visual verification and assets

No screenshots were captured or compared. Exact rendered positions, pressed states, safe areas, three-column text fitting and rotation must be checked on Android/iOS after SDK execution is available. The tests cover the requested widths but remain unrun. Existing unbundled fonts and V01's missing licensed editorial image are unchanged limitations; no substitute image was generated in this task. The source's sample 88% energy meter remains omitted because the API provides no such metric. No ad placement, unsupported metric or other screen was implemented. M05 and remaining-screen fixes have not started.
