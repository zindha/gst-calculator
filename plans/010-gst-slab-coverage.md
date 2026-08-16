# Plan 010: Ship the documented 0% and 0.25% GST slabs; fix the rate badge map

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
- **Risk**: LOW — additive constant changes + one formatter; covered by existing tests
- **Depends on**: plans/002 (reuses its `formatRate` helper so fractional
  slabs display correctly)
- **Category**: product gap / docs-vs-code mismatch
- **Planned at**: no VCS — audit date 2026-08-15
- **Issue**: n/a

## Why this matters

The README advertises the calculator as covering "all Indian slabs (0%, 0.25%,
3%, 5%, 12%, 18%, 28%)", but `GstRates.standardSlabs` ships only
`[3, 5, 12, 18, 28]`. The 0.25% slab (rough diamonds) and 0% (nil-rated goods)
are only reachable through the "Custom" rate dialog — whose own hint is
"e.g., 0.25". The settings default-slab picker has the same gap. Additionally,
`GSTColorScheme.rateColor` has no `3` case, so the HSN lookup renders a 3%
entry with the red 28% badge, and the HSN rate filters omit 3% entirely. This
plan makes the advertised slabs first-class and fixes the color mapping — no
formulas change.

## Current state

- `lib/core/constants/gst_rates.dart` line 6:
  `static const List<double> standardSlabs = [3.0, 5.0, 12.0, 18.0, 28.0];`
- `README.md` (Features): "across all Indian slabs (0%, 0.25%, 3%, 5%, 12%,
  18%, 28%)".
- `lib/core/theme/theme_extensions.dart` `rateColor(double rate)`:
  `switch (rate) { 0 => rate0Color, 5 => rate5Color, 12 => rate12Color, 18 =>
  rate18Color, _ => rate28Color }` — `3` and `0.25` fall to the 28% red.
- `lib/features/hsn_lookup/data/hsn_sac_data.dart` — `rateFilters = [0, 5,
  12, 18, 28]` (no 3).
- Display sites that format rates: `gst_slab_selector.dart` (chip labels use
  `toStringAsFixed(0)`), `settings_screen.dart` line ~278 (default-slab
  picker), `history_list_item.dart` (plan 002 replaces this with
  `formatRate`), `quick_actions_bar.dart` (summary text), `invoice_line_item_row.dart`
  (`gstRate.toStringAsFixed(1)` — already fine for 0.25).
- `GstRates.defaultSlab = 18.0` and `minCustomSlab = 0.0` / `maxCustomSlab =
  100.0` unchanged.

Repo conventions: rates live in `GstRates`; colors in `GSTColorScheme`;
`formatRate` (from plan 002) is the display formatter.

## Commands you will need

| Purpose   | Command                    | Expected on success |
|-----------|----------------------------|---------------------|
| Get deps  | `flutter pub get`          | exit 0              |
| Analyze   | `flutter analyze`          | exit 0, no issues   |
| Full test | `flutter test`             | all pass            |

## Scope

**In scope** (the only files you should modify):
- `lib/core/constants/gst_rates.dart`
- `lib/core/theme/theme_extensions.dart`
- `lib/features/hsn_lookup/data/hsn_sac_data.dart` (rateFilters only)
- `lib/features/calculator/presentation/widgets/gst_slab_selector.dart`
  (chip label formatting)
- `lib/features/settings/presentation/screens/settings_screen.dart`
  (default-slab picker labels)
- `test/ui_regression_test.dart` (only if a chip-count assertion needs
  updating)

**Out of scope** (do NOT touch):
- `GstMath`/`GstResult` and all calculation formulas.
- `gst_rates_test`-style new data files unless one already exists (none does).
- HSN/SAC dataset entries (adding 0.25% goods/services entries is a separate
  content task — note in maintenance).
- `pubspec.yaml`, platform config, assets.

## Steps

### Step 1: Add the slabs

In `lib/core/constants/gst_rates.dart`, change `standardSlabs` to:

```dart
static const List<double> standardSlabs = [0.0, 0.25, 3.0, 5.0, 12.0, 18.0, 28.0];
```

Keep `defaultSlab = 18.0` and the min/max custom bounds unchanged. Check every
consumer of `standardSlabs`:

- `gst_calculator_notifier.dart` `loadFromHistory` uses
  `GstRates.standardSlabs.contains(entry.rate)` — a history entry at 0% or
  0.25% now correctly maps to a standard chip instead of "Custom" (intended).
- `gst_slab_selector.dart` and `settings_screen.dart` render chips/rows from
  the list — labels must use `formatRate` (Step 2).

**Verify**: `flutter analyze` → exit 0.

### Step 2: Format chip labels with `formatRate`

- In `gst_slab_selector.dart`, replace `'${slab.toStringAsFixed(0)}%'` with
  `'${formatRate(slab)}%'` (import the helper from plan 002 —
  `lib/core/utils/rate_formatter.dart`, or wherever 002 placed it; if 002
  hasn't landed, create the helper here and have 002 reuse it).
- Same for the default-slab picker rows in `settings_screen.dart` (line ~278).
- `0.25` renders as `0.25%`, `0` as `0%`, `18` as `18%`.

**Verify**: `flutter analyze` → exit 0.

### Step 3: Fix the rate-color map and HSN filters

- In `theme_extensions.dart`, extend `rateColor`:

  ```dart
  Color rateColor(double rate) => switch (rate) {
    0 => rate0Color,
    0.25 => rate0Color,     // nil/near-nil — neutral grey family
    3 => rate5Color,        // low slab — green family (or add rate3Color)
    5 => rate5Color,
    12 => rate12Color,
    18 => rate18Color,
    _ => rate28Color,
  };
  ```

  (If you prefer a distinct `rate3Color`, add the field to the extension and
  both theme constants — pick one approach and keep the switch exhaustive.)

- In `hsn_sac_data.dart`, `rateFilters = [0, 0.25, 3, 5, 12, 18, 28]` so the
  lookup filter covers the same slabs as the calculator. (No dataset entries
  at 0.25/3 exist yet — the filter will simply show empty results until
  content is added; that's acceptable and visible, or omit 0.25/3 from the
  filter if empty results are confusing — choose and document.)

**Verify**: `flutter analyze` → exit 0.

### Step 4: Tests

- `test/core/utils/gst_math_test.dart` already covers 0% and 0.25% math —
  unchanged.
- Add to `test/ui_regression_test.dart` (calculator test): after entering an
  amount, tapping `0%` yields zero GST (`₹1,000.00` total for ₹1,000), and
  tapping `0.25%` shows the chip label `0.25%` and a correct total.
- Add a `rateColor` assertion in a widget/theme test if one exists, or verify
  via the HSN screen that a 3% filter chip renders (assert
  `find.text('3%')`).

**Verify**: `flutter test` → all pass.

## Test plan

- Calculator: 0% and 0.25% slabs selectable, labeled correctly, math correct.
- Settings default-slab picker shows `0%` and `0.25%` rows.
- HSN filter chips include 0.25% and 3%.
- Existing slab tests (`12%`, `5%` flows in `ui_regression_test.dart`) still
  pass — chip count changes must not break `find.text('5%')`-style lookups
  (the labels remain unique per rate).

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0
- [ ] `GstRates.standardSlabs == [0.0, 0.25, 3.0, 5.0, 12.0, 18.0, 28.0]`
- [ ] A 0.25% custom-style calculation now uses the standard chip path
      (`loadFromHistory` treats 0.25 as standard)
- [ ] `0.25%` appears on the chip and in the settings picker (not `0%`)
- [ ] `rateColor(3)` no longer returns the 28% color
- [ ] HSN rate filters include 3 (and 0.25 if chosen)
- [ ] No file outside the in-scope list is modified
- [ ] `plans/README.md` status row for 010 updated to DONE

## STOP conditions

Stop and report back (do not improvise) if:

- Any "Current state" excerpt doesn't match the live code.
- Adding `0.0` to `standardSlabs` breaks an existing test that assumed the
  first chip was `3%` (update only the affected assertion's finder — report
  which).
- `formatRate` (plan 002) isn't available and creating it here would duplicate
  plan 002's work — create it in `lib/core/utils/rate_formatter.dart` and
  leave a note for 002 to reuse it.

## Maintenance notes

- The HSN dataset still lacks 0.25%/3% entries — adding accurate codes is a
  content task with its own review (tax rates change; source from current
  government schedules).
- When the GST council changes slabs (as it has historically), the single
  `standardSlabs` list + `rateColor` map are the two places to update —
  keep them adjacent in review.
- The 0% slab makes the whole calculation trivially zero-GST — the result
  card already handles `gst == 0` (GST row shows ₹0.00); verify once manually.
