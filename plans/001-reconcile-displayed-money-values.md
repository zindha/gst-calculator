# Plan 001: Reconcile displayed money values (rounding)

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
- **Risk**: MED — touches the core math result and every money display; mitigations are the new tests
- **Depends on**: none
- **Category**: correctness/bug
- **Planned at**: no VCS — audit date 2026-08-15
- **Issue**: n/a

## Why this matters

This is a money app. When a user calculates ₹100 inclusive of 18% GST, the
screen currently shows a base of ₹84.75, CGST ₹7.63 and SGST ₹7.63 — which sum
to ₹100.01 — while the headline total says ₹100.00. The "GST" row shows ₹15.25
while CGST+SGST visually sum to ₹15.26. Every displayed number is rounded to 2
decimal places independently from unrounded doubles, so the parts never
reconcile with the whole. For a tax tool, "the numbers don't add up" is a
trust-destroying defect that also carries over to history, CSV export, invoice
summaries, and the PDF. This plan makes displayed (and exported) money values
reconcile: parts sum exactly to the totals shown.

## Current state

- `lib/core/utils/gst_math.dart` — `GstMath.calculate` returns exact doubles
  (`GstResult{baseAmount, cgst, sgst, igst, totalAmount}`). For inclusive
  ₹100 @ 18%: `baseAmount = 100/1.18 = 84.74576…`, `totalGst = 15.25423…`,
  `cgst = sgst = 7.62711…`, `totalAmount = 100`.
- `lib/features/calculator/presentation/widgets/results_breakdown_card.dart`
  — renders each field through `CurrencyFormatter.format(...)` (2 dp):
  base `₹84.75`, CGST `₹7.63`, SGST `₹7.63`, total `₹100.00`, and the GST
  row computes `totalGst = result.cgst + result.sgst + result.igst` (unrounded
  sum, formatted to `₹15.25`).
- `lib/features/history/presentation/widgets/history_list_item.dart` — same
  pattern: `totalGst = entry.cgst + entry.sgst + entry.igst` formatted
  independently.
- `lib/features/invoice/presentation/widgets/tax_summary_card.dart` and
  `lib/features/invoice/domain/usecases/generate_invoice_pdf.dart`
  (`_buildTaxSummary`) — subtotal / CGST / SGST / IGST / grand total formatted
  independently; per-line GST amounts in `InvoiceLineItem.gstAmount` are exact
  doubles.
- `lib/core/utils/currency_formatter.dart` — `NumberFormat.currency(symbol:
  '₹', locale: 'en_IN')`, always 2 dp. Used everywhere; keep as the final
  formatting step.

Repo convention to match: display formatting flows through
`CurrencyFormatter`; domain models carry raw numbers; tests live in
`test/core/utils/` for pure logic and `test/ui_*` for widget behavior.

## Commands you will need

| Purpose   | Command                    | Expected on success |
|-----------|----------------------------|---------------------|
| Get deps  | `flutter pub get`          | exit 0              |
| Analyze   | `flutter analyze`          | exit 0, no issues   |
| Unit test | `flutter test test/core/utils/money_test.dart` | all pass |
| Full test | `flutter test`             | all pass            |

(Assumes a Flutter SDK environment; not installed in the audit workspace.)

## Scope

**In scope** (the only files you should modify):
- `lib/core/utils/money.dart` (create — rounding/reconciliation helpers)
- `lib/features/calculator/presentation/widgets/results_breakdown_card.dart`
- `lib/features/history/presentation/widgets/history_list_item.dart`
- `lib/features/invoice/presentation/widgets/tax_summary_card.dart`
- `lib/features/invoice/domain/usecases/generate_invoice_pdf.dart`
- `lib/features/csv_export/csv_export.dart` (history + invoice CSV rows)
- `test/core/utils/money_test.dart` (create)
- `test/ui_regression_test.dart` (add one inclusive-rounding assertion)

**Out of scope** (do NOT touch):
- `lib/core/utils/gst_math.dart` — keep `GstResult` exact; reconciliation is a
  display/export concern in this plan.
- The GST formulas, slab list, modes, or state machine in the calculator.
- `lib/features/history/data/models/history_entry.dart` serialization — do not
  change persisted shape (old entries must keep loading).

## Steps

### Step 1: Create the money helpers

Create `lib/core/utils/money.dart`:

```dart
/// Round-half-up to 2 decimal places (paise).
double round2(double v) => (v * 100).roundToDouble() / 100;

/// A display-ready breakdown whose parts sum exactly to the shown total.
class ReconciledBreakdown {
  final double base;
  final double cgst;
  final double sgst;
  final double igst;
  final double gst;      // cgst + sgst + igst
  final double total;    // base + gst
}

/// Reconciles a [GstResult] so base + gst == total and cgst + sgst == gst
/// at 2-decimal precision. Rules:
///  - inclusive: the entered gross is authoritative -> total = round2(input),
///    gst = total - base (base rounded), so base + gst == total exactly.
///  - exclusive: the entered base is authoritative -> base = round2(input),
///    total = base + round2(gst), gst = total - base.
///  - intra-state: sgst absorbs the rounding remainder: sgst = gst - cgst.
ReconciledBreakdown reconcile(GstResult r, {required double input});
```

Implement `reconcile` exactly to those rules. Concretely:

```dart
final base = round2(r.baseAmount);
final gstR = round2(r.cgst + r.sgst + r.igst);
final double total;
final double gst;
if (r.isInclusive) {
  total = round2(input);
  gst = total - base;
} else {
  total = base + gstR;
  gst = total - base;
}
final cgst = round2(r.cgst);
final sgst = r.isIntraState ? gst - cgst : 0.0;
final igst = r.isIntraState ? 0.0 : gst;
```

Handle the inter-state case with `input` = the parsed `amountText` double (the
same value the notifier parses).

**Verify**: `flutter analyze` → exit 0. `flutter test test/core/utils/money_test.dart` → all pass (tests written in Step 2).

### Step 2: Write the unit tests (write first, then implement to green if needed)

Create `test/core/utils/money_test.dart` covering:

- Inclusive ₹100 @ 18%: `base == 84.75`, `cgst == 7.62`, `sgst == 7.63`,
  `gst == 15.25`, `total == 100.00`, and `base + gst == total` exactly.
  (Check the arithmetic: `gst = 100 − 84.75 = 15.25`, `cgst = round2(7.6271) =
  7.63`, `sgst = 15.25 − 7.63 = 7.62` — CGST/SGST differ by one paisa so the
  parts reconcile; assert `cgst + sgst == gst`.)
- Exclusive ₹1,000 @ 18%: `base == 1000`, `gst == 180`, `total == 1180`,
  `cgst == sgst == 90`.
- Inclusive ₹1,180 @ 18%: `base == 1000`, `gst == 180`, `total == 1180`.
- Inclusive ₹99.99 @ 0.25%: parts sum exactly (no assertion drift).
- Inter-state variant: `igst == gst`, `cgst == sgst == 0`.
- A property-style loop: for a set of (amount, rate, mode) pairs, assert
  `round2(b.base + b.gst) == b.total` and `b.cgst + b.sgst == b.gst`.

Model the file after `test/core/utils/gst_math_test.dart` (plain `test()`
groups, `closeTo` where comparing to raw doubles, `==` where comparing
reconciled values).

**Verify**: `flutter test test/core/utils/money_test.dart` → all pass.

### Step 3: Apply reconciliation in the calculator result card

In `results_breakdown_card.dart`, replace the direct formatting of
`result.baseAmount`, `result.cgst`, `result.sgst`, `result.igst`,
`result.totalAmount` and the computed `totalGst` with values from
`reconcile(result, input: double.parse(state.amountText))`. Keep the existing
`FittedBox`/`AnimatedSwitcher` structure and the `_formatRate` labels
unchanged. The "GST" row must show `breakdown.gst`; the breakdown rows show
`breakdown.cgst` / `breakdown.sgst` / `breakdown.igst`; the hero total shows
`breakdown.total`.

**Verify**: `flutter test test/ui_regression_test.dart` → all pass
(assertions like `₹1,180.00`, `₹892.86`, `₹107.14` still hold because 2-dp
inputs with standard rates reconcile to the same displayed values).

### Step 4: Apply reconciliation in history, invoice summary, CSV, and PDF

- `history_list_item.dart`: use `reconcile(…)`-equivalent values for the
  `Total …` and `GST …` lines (construct a `GstResult`-like reconcile from the
  stored `HistoryEntry` fields, or add a `reconcileFromParts(base, cgst, sgst,
  igst, total, isInclusive)` overload in `money.dart`). The list line
  `GST ₹15.25` must equal the visible CGST+SGST sum for the same entry.
- `tax_summary_card.dart`: it receives already-summed `cgst`, `sgst`, `igst`,
  `grandTotal` from `InvoiceModel` getters. Adjust the *callers*
  (`invoice_editor_screen.dart` and `invoice_preview_screen.dart`) to pass
  reconciled values (round2 each; for intra-state make `sgst =
  round2(grandTotal − subtotal) − cgst` so the card's rows sum to the grand
  total). Do not change the card widget's API.
- `csv_export.dart`: `buildHistoryCsv` and `buildInvoiceCsv` — replace
  `toStringAsFixed(2)` of raw fields with reconciled/rounded values so the
  CSV's CGST+SGST+IGST row sums to its total column. Keep the header rows and
  `_escape`/`_row` helpers unchanged.
- `generate_invoice_pdf.dart` `_buildTaxSummary`: use reconciled values for
  the CGST/SGST/IGST/subtotal rows so they match the grand total. (The
  amount-in-words line is handled by plan 009; leave it here.)

**Verify**: `flutter test` → all pass.

### Step 5: Add the inclusive-rounding regression assertion

In `test/ui_regression_test.dart`, extend the first calculator test (or add a
new testWidgets) with: enter `100` → tap `Remove GST` (inclusive) → assert
`find.text('₹100.00')` (total) is present, `find.text('₹84.75')` (base) is
present, and the sum of the two CGST/SGST row values equals the GST row value
(assert the exact strings `₹7.63` and `₹7.62` appear). This locks the
reconciliation behavior against regressions.

**Verify**: `flutter test test/ui_regression_test.dart` → all pass.

## Test plan

- New file `test/core/utils/money_test.dart` — the reconciliation rules above.
- One widget regression in `test/ui_regression_test.dart` (Step 5).
- Existing tests must all still pass — in particular `gst_math_test.dart`
  (unchanged, exact doubles untouched) and the existing UI assertions for
  whole-paise inputs.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `flutter analyze` exits 0
- [ ] `test/core/utils/money_test.dart` exists and all its tests pass
- [ ] `flutter test` exits 0 (entire suite)
- [ ] With amount `100`, inclusive mode, 18%: the result card shows base
      `₹84.75`, CGST `₹7.63`, SGST `₹7.62`, GST `₹15.25`, total `₹100.00`,
      and `84.75 + 7.63 + 7.62 == 100.00` exactly
- [ ] No file outside the in-scope list is modified
- [ ] `plans/README.md` status row for 001 updated to DONE

## STOP conditions

Stop and report back (do not improvise) if:

- Any "Current state" excerpt doesn't match the live code.
- An existing UI assertion (`₹892.86`, `₹107.14`, `₹1,180.00`, …) fails after
  Step 3 in a way you cannot attribute to reconciliation (report the failing
  expectation).
- The fix appears to require changing `gst_math.dart` or the persisted
  `HistoryEntry` JSON shape.
- `round2` behavior is ambiguous for a value ending in exactly `.005` (assert
  the observed behavior in the tests and proceed — do not re-design).

## Maintenance notes

- Any future money display (new screens, exports) must go through
  `money.dart` helpers; note this in code review.
- `GstResult` stays exact — do not "fix" it to rounded values later; the
  reconciliation layer is the single source of display truth.
- Watch out for the 0.005 tie case: `(v * 100).roundToDouble()` uses
  round-half-away-from-zero; keep that behavior documented in `money.dart`.
