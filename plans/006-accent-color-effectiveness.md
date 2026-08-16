# Plan 006: Make the accent-color setting effective (or remove it)

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
- **Risk**: LOW — theming only; default look unchanged
- **Depends on**: none
- **Category**: bug (feature advertised but non-functional)
- **Planned at**: no VCS — audit date 2026-08-15
- **Issue**: n/a

## Why this matters

Settings and onboarding advertise an accent-color feature ("pick an accent
colour", "Custom Accent — Tap to change"), but selecting an accent has almost
no visible effect. Both themes pin `primary` and `secondary` to the fixed
emerald/saffron brand colors, and the accent seed only shifts derived tones
(`primaryContainer`, `tertiary`, surface tints) that **no widget in the app
uses** — verified: zero references to `colorScheme.tertiary`,
`primaryContainer`, or `secondaryContainer` across `lib/`. A user who picks
"Red" sees essentially no change, which reads as a broken feature and erodes
trust in the Settings screen. This plan makes the accent actually tint the UI
(primary accent surfaces) — or, if product direction prefers a fixed brand,
removes the feature and its settings rows cleanly.

## Current state

- `lib/core/theme/app_theme.dart`:
  - `buildLightTheme({Color? accentColor})`: `seed = accentColor ??
    ColorPresets.lightSeed`, then
    `ColorScheme.fromSeed(seedColor: seed, ..., primary: ColorPresets.emerald,
    onPrimary: Colors.white, secondary: ColorPresets.saffron, ...)` (lines
    14–21).
  - `buildDarkTheme(...)`: same pattern with `emeraldLight`/`saffronLight`
    (lines ~210–220).
- `lib/core/theme/theme_controller.dart`: `accentColorProvider` watches
  `settingsProvider.accentColor` and feeds `GSTCalculatorApp`.
- `lib/features/settings/presentation/providers/settings_provider.dart`:
  `accentColor` persisted as an ARGB int under `accent_color`;
  `setAccentColor`/`clearAccentColor` work.
- `lib/features/settings/presentation/screens/settings_screen.dart`: "Accent
  Color" row (or "Custom Accent" + Reset) opens the 8-swatch picker.
- Grep evidence: `colorScheme.tertiary|primaryContainer|secondaryContainer`
  → **0 matches** in `lib/`. The app's visible color usage is `primary`,
  `secondary`, `onPrimary`, `onSurface(Variant)`, `outlineVariant`,
  `surfaceContainerHighest` (used in two minor chip backgrounds), `error`.

Repo conventions: theme built in `app_theme.dart`; brand identity is "The
Ledger" (emerald + saffron on paper) — the fix must keep the default look
identical.

## Commands you will need

| Purpose   | Command                    | Expected on success |
|-----------|----------------------------|---------------------|
| Get deps  | `flutter pub get`          | exit 0              |
| Analyze   | `flutter analyze`          | exit 0, no issues   |
| Full test | `flutter test`             | all pass            |

## Scope

**In scope** (the only files you should modify):
- `lib/core/theme/app_theme.dart`
- `lib/core/theme/color_presets.dart` (if adding per-accent onPrimary handling)
- `lib/features/settings/presentation/screens/settings_screen.dart` (only if
  removing the feature)
- `lib/features/settings/presentation/providers/settings_provider.dart` (only
  if removing the feature)
- `lib/core/theme/theme_controller.dart` (only if removing the feature)
- `test/ui_regression_test.dart` (the settings test taps the accent picker —
  update to assert the new behavior)
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart` (only
  if the onboarding copy mentions accents and the feature is removed)

**Out of scope** (do NOT touch):
- The GST color scheme extension (`theme_extensions.dart`) semantics — CGST /
  SGST / IGST colors stay fixed regardless of accent.
- Any widget layout or spacing.

## Steps

### Step 1: Decide and wire the accent into the ColorScheme

Preferred approach (keep the feature, make it visible — do this unless told
otherwise):

- In `buildLightTheme`/`buildDarkTheme`, stop pinning `primary` (and for the
  light theme `secondary`) to the fixed brand colors when a custom accent is
  supplied. Instead: `primary = accentColor ?? ColorPresets.emerald`, and let
  `fromSeed` derive the rest. For the dark theme use
  `Color.computeLuminance(accentColor) < 0.5 ? Color.lerp(accentColor,
  Colors.white, 0.35)! : accentColor` as the light-variant primary so dark-mode
  contrast is preserved.
- Keep `onPrimary` correct: `ThemeData.estimateBrightnessForColor(primary)`
  picks `Colors.white` or `Colors.black` (or use `onPrimary` from `fromSeed`).
- Leave the `secondary` (saffron) pinned for the custom-rate chips and the
  "Generate Invoice" button so the accent doesn't clash with GST semantics —
  OR let secondary follow the seed too; pick one and keep the default look
  pixel-identical (when `accentColor == null`, the constants must reproduce
  today's scheme exactly — verify against `ColorPresets`).
- Delete the now-unused `lightSeed`/`darkSeed` distinction only if nothing
  else references them; otherwise keep them as the default seeds.

If instead the decision is to remove the feature: delete the accent picker UI
rows, `setAccentColor`/`clearAccentColor`/`accentColor` from
`settings_provider.dart`, `accentColorProvider` from `theme_controller.dart`,
the `accentColor` param from `app_theme.dart`, and the onboarding slide copy
that mentions accent colours; remove the now-dead `accent_color` prefs key
handling (old key can be left orphaned — harmless). **Do not remove the
feature and leave the picker in place.**

**Verify**: `flutter analyze` → exit 0.

### Step 2: Regression-test the behavior

In `test/ui_regression_test.dart`'s settings test, after picking a swatch
(e.g. the red `Color(0xFFC62828)` swatch), assert the calculator screen's
primary color changed: e.g.
`Theme.of(tester.element(find.text('Calculate'))).colorScheme.primary ==
Color(0xFFC62828)` (or a documented derived value). Update the existing
"Custom Accent → Reset" flow assertions to match the new effective behavior
(they currently only check the row labels, which still pass).

**Verify**: `flutter test test/ui_regression_test.dart` → all pass.

### Step 3: Confirm default look is unchanged

Run the full suite and, if available, diff a screenshot of the default theme
before/after (or eyeball the light and dark themes with `accentColor == null`).
The default scheme must be identical to today's.

**Verify**: `flutter test` → all pass.

## Test plan

- Update the settings regression test (Step 2): accent selection now changes
  `colorScheme.primary`; Reset restores emerald.
- No new standalone test file needed; the existing harness covers it.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0
- [ ] Selecting a swatch changes `Theme.of(context).colorScheme.primary` on the
      calculator screen
- [ ] "Reset" restores the default emerald
- [ ] With no accent set, the light and dark schemes are identical to the
      pre-change build (compare `ColorScheme` values from both themes)
- [ ] No widget layout, spacing, or GST color semantics changed
- [ ] `plans/README.md` status row for 006 updated to DONE

## STOP conditions

Stop and report back (do not improvise) if:

- Any "Current state" excerpt doesn't match the live code.
- Making the accent effective visibly breaks contrast on `onPrimary` for one
  of the eight preset swatches (report the swatch; do not silently pick a
  different color).
- The default-theme diff shows any change (report rather than "fixing" it).

## Maintenance notes

- If the brand team later wants a fixed identity regardless of settings, the
  removal path in Step 1 is the sanctioned way out — never leave a
  non-functional picker.
- Contrast: the 8 presets were chosen for decorative use; as *primary* they
  must meet WCAG AA against white `onPrimary` — verify each preset with
  `Color.computeLuminance` during implementation and adjust `onPrimary`
  accordingly (that adjustment is in scope).
