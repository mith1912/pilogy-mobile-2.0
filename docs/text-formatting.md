# Display text policy

The official visible brand is **PILOGY**. Android label, both iOS bundle names, Flutter app titles and visible brand references use it. Package identifiers remain `mt.numerology`; approved launcher artwork is unchanged.

`lib/core/text/display_text.dart` provides `formatUiTitle`, `formatUiLabel`, and `formatSentence`. Title/label formatting capitalizes Vietnamese words using grapheme clusters (`characters`); sentences capitalize sentence starts without title-casing paragraphs. Punctuation and whitespace remain intact. Known brands/acronyms are canonicalized; unknown uppercase acronyms, camelCase/snake_case identifiers, URLs, email addresses and numeric strings are protected conservatively. Thus an unknown ALL-CAPS backend word may remain uppercase rather than destroying a significant abbreviation.

Personal names are rendered directly, without formatting. For composed text use `protectedTerms` with the exact name. Do not apply these functions in DTO parsers, repositories, serialization, or SQLite writes. Raw JSON remains unchanged. `distinctDisplayParagraphs` removes repeated complete display paragraphs within a section; it does not edit source fields.

All eight V1 presentation features were audited. Static short labels use Title Case; sentences and long content retain natural sentence casing. Audit entries: `verification/m05/text-audit.json`. Runtime formatting is applied at shared button/field/heading components and backend-content render points. Identifiers, filenames, URLs and developer symbols retain their original casing.

Tests cover Vietnamese, decomposed Unicode, emoji, acronyms, protected names, URLs, empty strings, long labels, master strings, and display-only paragraph deduplication. Execution is blocked by the installed Dart VM crash; this is not a passing test report.
