# Design QA

- Source visual truth: `C:\Users\uchihori\.codex\generated_images\01a01564-ac4e-7ca2-9494-5161b98c791f\exec-b93a0fa4-b7d9-4713-9ac8-60410244f282.png`
- Source pixels: 1398 × 1125
- Reported implementation screenshot: `C:\Users\uchihori\AppData\Local\Temp\codex-clipboard-962480a4-7c15-4e57-80bf-c889f9c4e14d.png`
- Reported implementation pixels: 427 × 608
- Implementation target: production `dist/content.js` bundle
- State: automatic summary completed while contextual explanation was open
- Density normalization: not possible because the source and reported implementation captures use different viewports and crops

## Full-view comparison evidence

The source and reported implementation were both opened and inspected, but a normalized combined comparison could not be captured in the managed browser. The reported screenshot nevertheless provides direct evidence of two state defects: both cards occupy the same right-side region, and Japanese UI contains an English model response.

## Focused region comparison evidence

- Right-side card stack: the summary card overlaps the explanation card vertically.
- Explanation content: headings and actions are Japanese, while the generated meaning and connection are English.
- Lens rail: remains readable and does not collide with the cards in the reported crop.

## Findings and fixes

- [P1] Contextual explanation can fail with the internal error `kErrorUnknown`.
  - Location: shared local-model session lifecycle in `promptModel()` and `explainSelection()`.
  - Evidence: the reported SQLite page capture shows `An unknown error occurred: kErrorUnknown` immediately after selecting a long passage.
  - Impact: the primary contextual-reading action fails and exposes an implementation detail to the user.
  - Fix applied: interrupting automatic summary generation now destroys the affected session before contextual explanation begins. Transient unknown/session errors rebuild the model and retry once, long-page context is capped at 8,000 characters while retaining page summary, outline, selected paragraph, and related excerpts, and raw internal errors are replaced by an actionable localized message.

- [P1] Structured summary response is rendered as visible JSON syntax.
  - Location: `generateSummaryInternal()`, summary response normalization, summary cache.
  - Evidence: the reported summary card displays ` ```json`, `{`, and `"summary": [` as its three bullet lines.
  - Impact: the automatic summary is unreadable even though generation completed successfully.
  - Fix applied: summary generation now uses an explicit three-string JSON schema, unwraps fenced JSON, objects, and arrays before rendering, rejects malformed line counts, and invalidates the affected cache generation.

- [P1] Summary and explanation cards can open simultaneously.
  - Location: `.summary-card`, `.explanation-card`, `generateSummaryInternal()`.
  - Evidence: the reported screenshot shows the explanation card beginning before the summary card ends.
  - Impact: content becomes obscured and the hierarchy between passive summary and active explanation is lost.
  - Fix applied: automatic summary display now checks that no explanation or selection action is active. Opening either card explicitly closes the other card.

- [P1] Explanation ignores the user's preferred language.
  - Location: model initialization, explanation prompt, refinement prompt, summary cache.
  - Evidence: the reported screenshot uses English explanation prose inside an otherwise Japanese interface.
  - Impact: the core explanation task can be unusable for the reader.
  - Fix applied: Chrome's UI language is passed as a BCP-47 requirement in the system prompt and every generation prompt. Japanese, Chinese, Korean, Cyrillic, and Arabic-script outputs receive a script check; a mismatched result is automatically translated and regenerated. Summary cache entries are now language-specific and the old cache is invalidated.

## Required fidelity surfaces

- Fonts and typography: the reported crop is readable; post-fix wrapping still needs a fresh capture.
- Spacing and layout rhythm: overlap was confirmed and fixed in state logic; post-fix visual evidence is pending.
- Colors and visual tokens: cream, dark green, yellow, and green status tokens remain consistent with the selected source.
- Image quality and asset fidelity: the extension overlay contains no custom raster assets; the underlying website remains site-owned.
- Copy and content: UI labels are consistent; generated response language is now bound to Chrome's UI language with a retry guard.

## Primary interactions tested

- TypeScript check: passed after fixes.
- Production build: passed after fixes.
- Automatic summary versus explanation exclusivity: verified statically through shared state guards.
- Preferred-language mismatch retry: covered by the QA fixture with an intentionally English first response and Japanese translation response.
- Model session recovery: TypeScript check and production build passed; live `kErrorUnknown` recovery awaits confirmation in the user's Chrome runtime.
- Browser post-fix interaction test and console check: pending a fresh browser capture.

## Comparison history

1. Initial implementation: browser capture unavailable in the managed environment.
2. User-reported implementation capture: identified P1 overlap and P1 response-language mismatch.
3. Fix pass: added mutually exclusive card state, BCP-47 language requirements, language-specific cache, and mismatch retry.
4. User-reported JSON rendering pass: added structured summary parsing and invalidated the affected cache version.
5. User-reported contextual explanation failure: added safe session replacement, one transient retry, bounded long-page context, and user-facing error copy.
6. Post-fix capture: pending.

## Implementation checklist

1. Reload the unpacked extension from `dist`.
2. Confirm that selecting text closes the summary card and prevents it from reopening when summary generation finishes.
3. Confirm that the explanation follows Chrome's UI language on a page written in another language.
4. On a long page, select text while automatic summary generation is still running and confirm contextual explanation succeeds.
5. Capture the same state again and complete the normalized visual comparison.

## Follow-up polish

- Consider displaying the detected response language in diagnostics only if future model-language issues need troubleshooting.

final result: blocked
