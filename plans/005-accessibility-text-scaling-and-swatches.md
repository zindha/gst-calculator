# Plan 005: Accessibility — text scaling to 2.0 and labeled accent swatches

> **Executor instructions**: Follow this plan step by step. Run every
> verification command and confirm the expected result before moving to the
> next step. If anything in the "STOP conditions" section occurs, stop and
> report — do not improvise. When done, update the status row for this plan
> in `plans/README.md` — unless a reviewer dispatched you and told you they
> maintain the index.
>
> **Drift check (run first)**: this workspace has no git repository. Compare
> the "Current state" excerpts below against the live code. If any excerpt
> does not match, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: S (hours)
- **Risk**: LOW — layout guards already exist; changes are clamp value + semantics
- **Depends on**: none
- **Category**: accessibility
- **Planned at**: no VCS — audit date 2026-08-15
- **Issue**: n/a

## Why this matters

Two accessibility gaps on the primary screens:

1. **The calculator clamps system text scaling to 1.3×.** A user who sets
   their device font size to 1.5× or 2.0× (common for low-vision users) gets
   only 1.3× on the app's most important screen. The code comment documents
   this as an overflow safeguard, but the screen already wraps long numbers in
   `FittedBox` (result card) and the segmented controls use `FittedBox` +
   `Flexible` labels, so the clamp can be raised to the platform-standard 2.0×
   without breaking layout.
2. **The accent-color swatches are color-only with no semantics.** The
   settings dialog renders eight colored circles behind a `GestureDetector`
   with no `Semantics` label — TalkBack announces nothing meaningful, and the
   selection itself is conveyed only by color.

This plan lifts the clamp and labels the swatches, and verifies at 2.0× with
the existing overflow-capture harness.

## Current state

- `lib/features/calculator/presentation/screens/gst_calculator_screen.dart`
  line 97: `child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, ...)`
  wraps the whole calculator body (input field, mode toggles, slab chips,
  result card, quick actions).
- Overflow safety already present:
  - `results_breakdown_card.dart` — hero total and GST row use `FittedBox`
    (scale-down) inside `Flexible`/`ConstrainedBox`.
  - `calculation_mode_toggle.dart` — segment labels use `Flexible` +
    `FittedBox(BoxFit.scaleDown)`.
  - `gst_slab_selector.dart` — chips are text-in-`Wrap`, no fixed widths.
  - `amount_input_field.dart` — fixed 42px display font; at 2.0× the field
    grows vertically (padding is symmetric) — the screen is a
    `SingleChildScrollView`, so vertical growth scrolls.
- `lib/features/settings/presentation/screens/settings_screen.dart`
  `_showAccentPicker` (around lines 210–245): `_accentColors.map((color) =>
  GestureDetector(...))` — no `Semantics`, no `tooltip`.
- Test harness: `test/ui_smoke_test.dart` and `test/ui_regression_test.dart`
  already capture `FlutterError` (overflow exceptions) via `_installCapture()`
  and already exercise `textScaleFactorTestValue = 1.3` on a 360×640 viewport.

Repo conventions: `A11y` helper in `lib/core/utils/accessibility_helper.dart`
(`A11y.label(child, label)`), `MediaQuery.disableAnimationsOf(context)` for
motion, `AppSpacing`/`AppRadius` tokens.

## Commands you will need

| Purpose   | Command                    | Expected on success |
|-----------|----------------------------|---------------------|
| Get deps  | `flutter pub get`          | exit 0              |
| Analyze   | `flutter analyze`          | exit 0, no issues   |
| Full test | `flutter test`             | all pass            |

## Scope

**In scope** (the only files you should modify):
- `lib/features/calculator/presentation/screens/gst_calculator_screen.dart`
- `lib/features/settings/presentation/screens/settings_screen.dart`
- `test/ui_smoke_test.dart` (bump one text-scale test to 2.0 and keep a 1.3 case)

**Out of scope** (do NOT touch):
- Any visual redesign, color changes, or layout restructure.
- Other screens' scaling (they already scale unclamped).
- The GST math, state, or history logic.

## Steps

### Step 1: Raise the clamp to 2.0 on the calculator

In `gst_calculator_screen.dart` line 97, change
`MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, ...)` to
`maxScaleFactor: 2.0` and update the doc comment: the clamp now exists only to
cap runaway scaling, not to cap accessibility. Keep the `FittedBox`/`Flexible`
guards as-is.

**Verify**: `flutter analyze` → exit 0.

### Step 2: Add a 2.0× overflow regression test

In `test/ui_smoke_test.dart`, add a testWidgets mirroring "Small phone + large
text scale" but with `textScaleFactorTestValue = 2.0` on the 360×640 viewport,
entering a long amount (`99999999.99`) and scrolling through the result card
and quick actions, asserting `_captured` stays empty. Keep the existing 1.3×
test (it still covers the mid-range).

If the 2.0× test reveals a real overflow, fix the offending layout minimally
(e.g. allow the amount field's `contentPadding` vertical to compress, or the
eyebrow label to wrap) — the change must stay within the two in-scope files; a
layout fix in `amount_input_field.dart` would require adding it to scope, so
prefer fixes inside the already-scoped screen or a token-safe padding tweak,
and note it.

**Verify**: `flutter test test/ui_smoke_test.dart` → all pass, no captured
overflow.

### Step 3: Label the accent swatches

In `settings_screen.dart` `_showAccentPicker`, wrap each swatch
`GestureDetector` in `Semantics(label: <color name>, button: true, selected:
<is current>)` (or use `A11y.label`). Give each of the eight `_accentColors`
entries a human name (e.g. "Blue", "Green", "Orange", "Purple", "Red",
"Teal", "Amber", "Brown") as a parallel list of `(Color, String)` pairs. Keep
the visual identical.

**Verify**: `flutter analyze` → exit 0; in the accent dialog, each swatch is
announced with its color name.

## Test plan

- New widget test at 2.0× text scale on a 360×640 viewport (Step 2) using the
  existing `_installCapture` harness.
- Existing 1.3× tests keep passing.
- Optionally, a small assertion in the settings regression test that the
  accent dialog's `Semantics` nodes are non-empty.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0
- [ ] `gst_calculator_screen.dart` no longer contains `maxScaleFactor: 1.3`
- [ ] A 2.0× text-scale test on a 360×640 viewport passes with zero captured
      overflow errors
- [ ] Every accent swatch in the settings dialog has a `Semantics` label with a
      color name
- [ ] No file outside the in-scope list is modified
- [ ] `plans/README.md` status row for 005 updated to DONE

## STOP conditions

Stop and report back (do not improvise) if:

- Any "Current state" excerpt doesn't match the live code.
- The 2.0× test overflows in a way that requires changing a file outside the
  in-scope list (report the file and the overflow rather than expanding scope
  silently).
- Raising the clamp causes a visual regression you cannot attribute to a
  layout guard (report the screen + widget).

## Maintenance notes

- Keep the 2.0× test as a permanent guard; if a future layout change
  reintroduces overflow at high scales the test will catch it.
- The `A11y` helper is the home for the swatch labeling pattern — reuse it for
  any future color pickers.
- Contrast of the swatch colors themselves is not part of this plan (they're
  decorative indicators with text labels elsewhere); re-audit if swatches ever
  become the *only* signal.
