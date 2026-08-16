# Plan 002: Coalesce history auto-saves and fix rate display

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

- **Priority**: P1
- **Effort**: M (a day-ish)
- **Risk**: LOW — behavior change is additive (fewer, cleaner entries); no persisted-shape change
- **Depends on**: none
- **Category**: correctness/bug + performance
- **Planned at**: no VCS — audit date 2026-08-15
- **Issue**: n/a

## Why this matters

History is a stated core feature ("every calculation is saved locally"), but
the current auto-save writes **on every keystroke and every control change**:
typing `1000` creates four entries (1, 12, 123, 1000), each slab/mode toggle
adds another, tapping a history item re-saves a fresh duplicate, and each save
performs a full SharedPreferences read + rewrite (`loadAll` then `persist`)
as an unawaited async fire-and-forget — a per-keystroke I/O churn that can
drop entries under rapid input. The History tab quickly becomes a wall of
near-duplicate rows, and the rate shown for fractional rates is wrong
(`0.25.toStringAsFixed(0)` renders `0%`). This plan makes history entries
meaningful (one per settled calculation), removes the write churn, and fixes
rate display.

## Current state

- `lib/features/calculator/presentation/providers/gst_calculator_notifier.dart`:
  - `_recalculate()` (around lines 125–145) parses `state.amountText`, computes
    a result, then calls `_autoSave(result)` on every change.
  - `_autoSave(GstResult result)` (lines 147–185) builds a `HistoryEntry` with
    `id: '${now.millisecondsSinceEpoch}_${result.baseAmount}'`, skips only if
    the *last* entry matches on `amountText` + `rate`, then calls
    `ref.read(historyProvider.notifier).addEntry(entry)` (not awaited).
  - `loadFromHistory(entry)` sets state then calls `_recalculate()`, which
    auto-saves a *new* entry when the last-saved differs — duplicating the
    tapped entry.
- `lib/features/history/presentation/providers/history_provider.dart`
  `addEntry` → `store.save(entry)` → `JsonListStore.save` does `await loadAll()`
  then `persist(items)` (`lib/core/utils/json_list_store.dart`) — a full-list
  read + write per call.
- `lib/features/history/presentation/widgets/history_list_item.dart` — renders
  the rate with `entry.rate.toStringAsFixed(0)` (e.g. `0.25` → `0%`,
  `1.5` → `2%`); custom fractional rates display incorrectly.
- `lib/core/utils/date_formatter.dart` — date/time formatting for entries
  (unchanged).

Repo conventions: state via Riverpod notifiers; persistence via
`JsonListStore`; display formatting through `CurrencyFormatter` /
`DateFormatter`.

## Commands you will need

| Purpose   | Command                    | Expected on success |
|-----------|----------------------------|---------------------|
| Get deps  | `flutter pub get`          | exit 0              |
| Analyze   | `flutter analyze`          | exit 0, no issues   |
| Full test | `flutter test`             | all pass            |

## Scope

**In scope** (the only files you should modify):
- `lib/features/calculator/presentation/providers/gst_calculator_notifier.dart`
- `lib/features/history/presentation/providers/history_provider.dart`
- `lib/features/history/presentation/widgets/history_list_item.dart`
- `lib/core/utils/json_list_store.dart` (only if needed for coalescing; prefer
  notifier-level changes)
- `test/core/.../gst_calculator_notifier_test.dart` (create — notifier unit tests)
- `test/ui_regression_test.dart` (adjust the history test if its entry-count
  assumptions change)

**Out of scope** (do NOT touch):
- `lib/core/utils/gst_math.dart`, `GstResult`, the calculation formulas.
- `HistoryEntry` JSON shape and storage key (`calculation_history`) — old
  entries must keep loading.
- The invoice draft auto-save (`invoice_provider.dart`) — different mechanism,
  already debounced by user action.

## Steps

### Step 1: Add a short debounce to auto-save

In `GstCalculatorNotifier`:

- Add a `Timer? _historyDebounce;` field (import `dart:async`).
- Replace the direct `_autoSave(result)` call in `_recalculate()` with
  `_scheduleAutoSave(result)`.
- `_scheduleAutoSave(GstResult result)` cancels any pending timer and starts a
  new one (≈ 600 ms): `_historyDebounce = Timer(const Duration(milliseconds:
  600), () => _autoSave(result));`. The latest result wins — typing `1000`
  produces one save.
- In `_autoSave`, keep the last-saved de-dup, but also treat
  "result unchanged from the previous auto-saved entry" as a skip. Do **not**
  auto-save from `loadFromHistory` — add a `_suppressAutoSave` flag set before
  calling `_recalculate()` there, or restructure `loadFromHistory` to set the
  state and compute the result without triggering a save.
- Cancel `_historyDebounce` if the notifier is disposed (implement
  `dispose()` if the notifier doesn't have one; Riverpod `Notifier` supports
  `dispose`).
- `clearAll()` should also clear `_lastSaved` and cancel the pending timer so
  clearing history isn't immediately followed by a re-save of the same value.

**Verify**: `flutter analyze` → exit 0.

### Step 2: Harden `addEntry` against write races

In `HistoryNotifier.addEntry`, guard against overlapping writes from the
debounce window ending while a previous write is still in flight: track an
in-flight future (`Future<void>? _writeQueue`) and chain new saves behind it:

```dart
Future<void> addEntry(HistoryEntry entry) async {
  state = [entry, ...state];            // optimistic UI update (unchanged)
  _writeQueue = (_writeQueue ?? Future.value()).then((_) => store.save(entry));
  await _writeQueue;
}
```

(If `JsonListStore.save` needs to be made race-safe instead, serialize at the
store level with the same chaining pattern — pick one layer and note it in the
PR.)

**Verify**: `flutter analyze` → exit 0.

### Step 3: Fix fractional-rate display in the history list

In `history_list_item.dart`, replace `entry.rate.toStringAsFixed(0)` with a
shared formatter. Add to `lib/core/utils/gst_math.dart` (or a small
`lib/core/utils/rate_formatter.dart`):

```dart
/// Formats a GST rate for display: integer rates without decimals,
/// fractional rates with up to 2 decimals, trailing zeros stripped.
String formatRate(double rate) {
  final text = rate.toStringAsFixed(2);
  final trimmed = text.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.endsWith('.') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
}
```

`0.25` → `0.25`, `18` → `18`, `1.5` → `1.5`. Use it in `history_list_item.dart`
(the `@ X%` part) and in `settings_screen.dart` line ~278 (the default-slab
picker uses `toStringAsFixed(0)` — apply the same formatter there and in
`gst_slab_selector.dart`'s custom-rate label if it regresses). Plan 010 will
reuse this formatter for the new 0%/0.25% slabs.

**Verify**: `flutter analyze` → exit 0.

### Step 4: Notifier unit tests

Create `test/core/.../gst_calculator_notifier_test.dart` (place under
`test/features/calculator/presentation/providers/` to mirror lib). Use the
Riverpod `ProviderContainer` pattern with `SharedPreferences.setMockInitialValues({})`
(see `test/ui_regression_test.dart` for the mocking pattern). Tests:

- Typing `1`, `12`, `123` quickly (pump timers past the debounce) results in
  exactly **one** history entry for the settled value.
- Changing the slab twice within the debounce window results in one entry for
  the final slab.
- `loadFromHistory` does **not** create a new history entry.
- `clearAll()` clears state and does not immediately re-save.

**Verify**: `flutter test test/features/calculator/presentation/providers/` → all pass.

### Step 5: Adjust the regression test if needed

`test/ui_regression_test.dart` (History test) and `test/ui_smoke_test.dart`
type `999999` / `2000` and rely on history containing the entry. With the
debounce, the entry still lands after `pumpAndSettle` (the widget tests pump
frames; ensure a `tester.pump(const Duration(milliseconds: 700))` is added
after entering text, before asserting history content, if any assertion
becomes flaky). Update those tests to pump past the debounce window.

**Verify**: `flutter test` → all pass.

## Test plan

- New notifier tests (Step 4) — the core of this plan's verification.
- History widget tests in `ui_regression_test.dart` still pass (with the
  debounce pump).
- No existing test may assert a *specific number of spam entries* — if one
  does, update it to assert the coalesced behavior instead.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0
- [ ] Typing `1000` produces exactly 1 history entry (not 4)
- [ ] Tapping a history item does not create a duplicate entry
- [ ] A `0.25%` custom-rate history entry displays `@ 0.25%` (not `@ 0%`)
- [ ] `clearAll()` does not cause a re-save
- [ ] No file outside the in-scope list is modified
- [ ] `plans/README.md` status row for 002 updated to DONE

## STOP conditions

Stop and report back (do not improvise) if:

- Any "Current state" excerpt doesn't match the live code.
- `flutter test` fails in `gst_math_test.dart` or `ui_smoke_test.dart` in a
  way not attributable to debounce timing.
- The fix appears to require changing the `calculation_history` storage key or
  `HistoryEntry` JSON fields.
- Debouncing breaks the "load from history" snackbar flow (`Loaded: …` must
  still appear).

## Maintenance notes

- The 600 ms debounce is a UX knob; keep it in one named constant.
- `formatRate` becomes the single rate formatter — plan 010 (0%/0.25% slabs)
  depends on it; do not introduce a second one.
- If history later gains grouping/merging UI, the coalescing at save-time
  remains correct; re-visit only if users want every intermediate keystroke.
