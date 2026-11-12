# Design system specification

Status: source implemented in lib/core/design_system/; Flutter compilation and visual/widget validation remain blocked by SDK startup. All palette constants were extracted directly from the shared Tailwind configuration. Typography is exposed through AppTypography and mapped to Material text roles by AppTheme.

Read all eight HTML documents, including their scripts and shared Tailwind configuration. The reference remains unchanged. Reference SHA256: `b0bbc581e6e54b5955a4818e652c473eb321921ab804f9a554828a81102b91e9`.

## Palette

Stitch uses a pale lavender surface (`#fef7ff`), rather than an exact warm cream. Preserve these explicit source values; choosing a warmer cream requires a later design decision. Primary is deep purple and secondary is muted gold.

AppColors constants:

| Stitch token | Exact value |
| --- | --- |
| background | `#fef7ff` |
| error | `#ba1a1a` |
| error-container | `#ffdad6` |
| inverse-on-surface | `#f6eefc` |
| inverse-primary | `#d4bfe3` |
| inverse-surface | `#332f39` |
| on-background | `#1e1a23` |
| on-error | `#ffffff` |
| on-error-container | `#93000a` |
| on-primary | `#ffffff` |
| on-primary-container | `#c3aed2` |
| on-primary-fixed | `#231531` |
| on-primary-fixed-variant | `#50405e` |
| on-secondary | `#ffffff` |
| on-secondary-container | `#795f2b` |
| on-secondary-fixed | `#261900` |
| on-secondary-fixed-variant | `#5a4311` |
| on-surface | `#1e1a23` |
| on-surface-variant | `#4a454c` |
| on-tertiary | `#ffffff` |
| on-tertiary-container | `#bbb5af` |
| on-tertiary-fixed | `#1e1b17` |
| on-tertiary-fixed-variant | `#4a4641` |
| outline | `#7b757d` |
| outline-variant | `#ccc4cd` |
| primary | `#3a2b47` |
| primary-container | `#51415f` |
| primary-fixed | `#f0dbff` |
| primary-fixed-dim | `#d4bfe3` |
| secondary | `#745a27` |
| secondary-container | `#ffdb9b` |
| secondary-fixed | `#ffdea5` |
| secondary-fixed-dim | `#e4c284` |
| surface | `#fef7ff` |
| surface-bright | `#fef7ff` |
| surface-container | `#f3ebf9` |
| surface-container-high | `#eee5f3` |
| surface-container-highest | `#e8dfed` |
| surface-container-low | `#f9f1ff` |
| surface-container-lowest | `#ffffff` |
| surface-dim | `#dfd7e5` |
| surface-tint | `#695877` |
| surface-variant | `#e8dfed` |
| tertiary | `#34312c` |
| tertiary-container | `#4b4742` |
| tertiary-fixed | `#e8e1da` |
| tertiary-fixed-dim | `#ccc5bf` |

## Typography

AppTypography uses Inter for body/labels and Playfair Display for headings/numerals through google_fonts. Source imports Inter 400/500/600 and Playfair Display 500/600 plus italic 500. Bundle licensed font assets before release for reliable offline rendering; no font assets were supplied or installed. Runtime google_fonts fetching is enabled for the application; tests explicitly use system font fallbacks to avoid network access. Runtime downloads are not an offline guarantee.

| Token | Family | Size / line height | Weight | Letter spacing |
| --- | --- | --- | --- | --- |
| label-md | Inter | 13 / 18 | 500 | 0.02em |
| label-sm | Inter | 11 / 14 | 600 | 0.06em |
| body-md | Inter | 14 / 22 | 400 | 0 |
| body-lg | Inter | 16 / 26 | 400 | -0.01em |
| body-sm | Inter | 12 / 18 | 400 | 0.01em |
| headline-lg | Playfair Display | 32 / 40 | 600 | -0.01em |
| headline-lg-mobile | Playfair Display | 26 / 34 | 600 | -0.01em |
| headline-md | Playfair Display | 22 / 30 | 600 | 0 |
| headline-sm | Playfair Display | 18 / 26 | 600 | 0.01em |
| display-numeral | Playfair Display | 64 / 72 | 500 | -0.02em |
| display-numeral-mobile | Playfair Display | 48 / 56 | 500 | -0.01em |

Convert em letter spacing to Flutter logical pixels (font size × em); TextStyle.height is line height / font size. Tailwind base assumes 16px per rem; use equivalent logical pixel values.

## Layout and components

- AppSpacing: xs 4, sm 8, md/gutter 16, margin 20, lg 24, xl 36. Cards also use local 12/14/20 padding in the source; do not flatten those differences.
- AppRadius: default 4, lg 8, xl 12, full pill/circle. Main cards and inputs typically use 12.
- Safe-area aware vertical scroll layouts, full-width sections, 20 side margins, 64 header content height. Do not port the browser's fixed 884px minimum height into Flutter.
- Primary CTA 52 high; name input 54 high; edit actions 48 high; salutation segments 46 high. Header icon buttons are 44 square; adapt interactive hit targets to at least 48 in Flutter.
- Premium surfaces: white cards, low lavender panels, subtle shadow, purple hero panels, gold accents, circular number badges, uppercase tracked eyebrow labels, serif section headings, body copy with generous leading.
- Form: label, helper/error text, trailing icon, segmented date selectors; rounded selection pills. Prototype mode toggles are demo controls, not a new screen.
- Implemented widgets: AppButton (primary/secondary, disabled/loading), AppInputField, AppCard, AppSectionHeader, AppLoadingState, AppErrorState with optional retry, AppEmptyState. Loading/error/empty content is not fully specified in Stitch; use neutral minimal patterns without invented domain claims.
- AppTheme: Material 3 light ColorScheme and consistent input/button/card themes. Settings shows light/dark/auto options, but no complete dark palette is supplied. Dark styling remains unresolved.
- Source interactions include 150ms CTA feedback, 200ms segment transitions, 300ms sheet/card changes, 2.4s toast. Mock sync delays are demos, not real progress contracts. Respect reduced motion in future implementation.
- Source icons use Material Symbols Outlined, generally 14–24px, with some filled variants. Use actual Material icons with documented equivalents; do not use emoji. Common families: explore/grid_view/person tabs, arrow_back, edit, person_add, delete, settings, shield, calendar_today, auto_stories, sync, chevron_right. Confirm Symbols/Flutter icon equivalence before screen implementation.
- Birth chart/cycle explanations and detail sheets, deletion confirmation dialogs, local profile drawer, selected-profile context, cards with trailing chevrons, and inline status/toast feedback are shared patterns.

External editorial image URLs and decorative inline SVG appear in the source. Asset licensing, bundling, and production availability are unresolved. Do not use sample interpretation prose as authoritative backend content. Exclude ad banners and premium/payment actions from M01.

## Implementation locations

`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_radius.dart`, `app_theme.dart`, and `widgets/app_components.dart` live in `lib/core/design_system/`. Inputs include label/helper/validation hooks, 54 minimum height, and focus styling. Buttons include primary/secondary, icon, disabled and loading states. Cards use the shared radius and surface. Theme is light-only until a dark palette is approved. Placeholder screens use these components; full Stitch layouts are intentionally deferred.

## M02 profile components

ProfileInputForm, ProfileSelectionTile, ProfileList and confirmProfileDeletion reuse these tokens and components. Segmented date entry uses day/month/year fields, forms show safe local validation/errors, selection/deletion have no fabricated numerology badges, and parent components own navigation. They remain separate from the full screen placeholders until M04.


## M04 composition

PilogyScaffold, EditorialPanel, InfoPanel and ActionRow provide shared native layouts; NumberCard/DataStatus/CalculationContent/CalculationSteps connect result UI. All eight feature screens now use those components and the existing AppColors/AppTheme. The 20px side margin, 12px panels, 16/20px padding, purple hero and gold accents follow the source. Headers/navigation grow for large text; numeric badges scale to their bounds while surrounding text wraps. Screens scroll within safe areas and respect keyboard insets.

External source images are represented by native decorative panels/icons until licensed bundled assets are supplied. Unsupported metrics/indices and demo controls are not rendered as real data. Ads leave no misleading production placeholder. Font assets, visual screenshot comparison and on-device scaling verification remain unverified release work. See m04-screen-flows.md for all intentional deviations; no pixel-perfect claim is made.
