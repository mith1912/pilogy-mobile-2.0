# V1-08 Hồ Sơ reference alignment

Reference: design_preference/design_pilogy.txt, V1-08 at lines 777–1040. The reference is unchanged. This change only replaces V08's presentation; the original M02 profile list/form components, repositories, schema and eight routes remain intact.

The screen now follows the reference's content order and spacing: 22px saved-profile heading with a gold count pill, local-storage subtitle, white 16px-radius selected spotlight, 64px purple Life Path badge with a star, actual identity/date, three-column metrics with a white/gold Soul Urge inset, paired edit/analysis buttons, other-profile section with count and selection/edit/delete controls, filled add button, local privacy panel and grouped settings/data links. Header uses the filled 32px person avatar. V08's three-item footer follows the reference's icon/label layout without Material's selection pill. Other screens retain their existing scaffolds and navigation.

Only the selected profile appears in the spotlight; it is excluded from the other-profile list. Selection and deletion still go through ProfilesViewModel and the existing SQLite repository. The delete confirmation is a scrollable bottom sheet; cancellation changes nothing. Selected-profile deletion is available through the spotlight options menu. UI-only busy state prevents duplicate actions; failures use existing fixed safe messages. Input names are rendered exactly as stored. Calendar dates are displayed as DD/MM/YYYY. Typography/casing changes are presentation only.

Backend results supply the spotlight badge, metrics and subtitle; no client-side numerology or sample interpretation was added. Master value/base formatting remains the shared formatIndexValue implementation. Retained values are suppressed through selectedProfileCalculationProvider. Loading, missing, stale, unverified, offline and error states remain visible, with explicit refresh where needed. Fresh successful results do not add an extra status panel absent from the reference.

Explicit reference gaps: unselected profiles have no result supplied by the existing selected-profile calculation flow. They use neutral person badges and real birth dates rather than the prototype's hardcoded numbers/archetypes or additional background calculation requests. The selected badge/metrics show an em dash while no backend result is available. The prototype's restore claim in the privacy link subtitle was replaced with the available export/cache/delete actions. Subtitle text may wrap below the birth date at phone widths to preserve real long names, Vietnamese text and accessibility scaling. The decorative gold atmosphere is a native radial gradient. No screenshot comparison or pixel-perfect claim is made.

Regression coverage in test/v08_ui_test.dart exercises selected/other separation, persisted switching, cancel/confirmed deletion and narrow-screen large-text rendering using the existing local SQLite/backend fixture harness. These tests are authored but unexecuted because Flutter initialization is blocked.

## Release after store version 1.0.11 / build 12

pubspec.yaml is now 1.0.12+13. After completing the existing docs/admob-testing.md device/UMP/live-ad release gates, run from this directory:

```sh
bash scripts/build_play_bundle.sh public-live-ads --build-name=1.0.12 --build-number=13
```

This mode enables live banner, interstitial, App Open and Native Advanced units with the centralized consent, placement and frequency policies. It does not guarantee fill or publish anything. The script now forwards additional Flutter build options and keeps the required checks and signature verifier. Output: build/app/outputs/bundle/release/app-release.aab. Build 13 must still be unused in Play Console; otherwise choose a higher build number.

## Actual verification

Logs: docs/verification/v08-ui/. flutter pub get, dart format ., flutter analyze and flutter test were attempted; each exits before execution because the installed SDK cache is not writable in the agent environment. No passing Dart formatting, analysis, tests, build, screenshots or device UI is claimed. Cached SDK metadata identifies Flutter 3.47.9 / Dart 3.13.7; dependency resolution and existing lockfiles were not changed by this task.

AdMob source checks and bash syntax validation pass. A command-double exercise passes the version/live-ad argument forwarding and verifier invocation; it does not compile a bundle. Foundation checks confirm design/Firebase byte preservation, package IDs and native XML/plist parsing, then fail the existing route text-count assertion (routes were not edited). No full foundation pass is claimed.
