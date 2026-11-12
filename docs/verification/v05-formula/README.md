# V05 formula GlobalKey report

Status: defensive mitigation implemented; root cause and device fix unconfirmed.

Source inspection found no explicit GlobalKey in V05, its formula expansion, or shared formula renderer. The only application-created GlobalKey belongs to the profile form state. Formula step ValueKeys are local keys; repeated local key values in separate parents are not themselves a duplicate GlobalKey cause.

Formula rows previously mounted SelectableText, which owns internal EditableText GlobalKey state. They now render read-only, soft-wrapping Text inside the existing ExpansionTile. This removes editable selection state from the formula subtree without changing server inputs/results, ordering, Master formatting, article content or navigation. After the reported Scrollable/FocusInheritedScope trace, full V05 interpretation paragraphs also render as read-only Text. They remain untruncated and scroll with the page; per-paragraph text selection is no longer provided. The regression asserts no EditableText children and one page Scrollable before and after expansion. This is a scoped mitigation, not a reproduced root-cause diagnosis. A first exception/stack trace was requested because a GlobalKey message can follow an earlier error.

Regression coverage added in test/formula_expansion_test.dart: repeated real V05 article expansion/collapse, rebuild during animation, and widget disposal at 360dp. Calculation renderer tests now assert Text formula rows. Tests were attempted but cannot execute: installed Dart VM aborts before initialization at cpuinfo_macos.cc:42 (exit 134). pub get, format and analyze also abort; see adjacent logs. Delimiter balance and scripts/verify_foundation.py pass as source-only checks.

Device follow-up: restart the app and repeatedly open/close the formula. If the error remains, capture the first Flutter exception and stack trace (without profile data); it is needed to distinguish internal selection issues from an earlier layout/lifecycle error. No visual or runtime success is claimed.
