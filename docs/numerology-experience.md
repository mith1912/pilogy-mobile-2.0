# M05 numerology experience

Status: IMPLEMENTED_NOT_VISUALLY_VERIFIED. Dart compilation and automated tests are BLOCKED by the local SDK crash documented under `verification/m05/`.

The eight approved Stitch layouts remain in place. V05 and reusable calculation expansions share `CalculationExplanation`, which renders server steps in returned order. Known backend component/operation labels have Vietnamese headings. Expressions only join returned input values and display the returned result: Flutter never adds, reduces, or reconstructs numerology. Optional input labels and empty steps are handled. Read-only, wrapping text preserves long expressions. The final value uses the central `formatIndexValue` formatter.

11/2, 22/4 and 33/6 preserve actual backend value/baseValue. Full interpretation requests continue to use the actual value (11, 22, 33), never baseValue. Ordinary numbers remain unchanged.

V05 maps title/keywords to short-heading formatting; subtitle, tagline and article paragraphs use sentence formatting. Summary and essence are display-deduplicated. Strengths/challenges retain their title/description structure; advice includes relationships, careerAndGrowth, lifeLesson, affirmation and optional periodFocus using Vietnamese labels. Articles are not truncated. Required backend fields still follow the verified contract; absent periodFocus is omitted. No interpretation text is generated locally.

Current local date is checked every 30 seconds and immediately on app resume. Explicit selected dates remain date-only strings and bypass the clock. Exact profile revision, referenceDate, locale and expected versions continue to govern cache use. No schema or backend changes were made.

Duplicate calculation refreshes are ignored while loading/refreshing. Successful article loads are retained in Riverpod for five minutes by type/value/locale/contentVersion; failures remain retryable. V05 pull refresh avoids restarting an article fetch already triggered by changed contentVersion/value. The existing three-second update notice remains transition-driven and does not fire merely because of a rebuild.

Remaining M06: AdMob integration is not implemented or initialized. Restore working Flutter tooling, resolve dependencies, run tests/builds and inspect emulator screenshots before release. Existing excluded features and screens remain out of scope.
