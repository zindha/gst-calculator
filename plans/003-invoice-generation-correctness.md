# Plan 003: Invoice generation correctness (base, numbering, refresh, state)

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
- **Risk**: LOW-MED — changes draft creation and the quick-action handoff; covered by tests
- **Depends on**: plans/001 (the new test in Step 5 asserts displayed-value equality, which requires reconciled display)
- **Category**: correctness/bug
- **Planned at**: no VCS — audit date 2026-08-15
- **Issue**: n/a

## Why this matters

Three money/trust defects in the invoice flow:

1. **"Generate Invoice" from an inclusive calculation over-charges GST.**
   `quick_actions_bar.dart` feeds the *entered* amount (the gross, GST-inclusive
   value) as the line-item rate. The invoice then adds GST on top of an amount
   that already includes GST — the invoice total exceeds the calculation the
   user just saw.
2. **Invoice numbers collide.** Every draft is numbered
   `INV-<yyyyMMdd>-001`; two invoices created the same day get identical
   numbers. GST invoices legally need unique, sequential numbers.
3. **The saved-invoices list goes stale.** `finaliseInvoice()` saves to
   storage but never updates `savedInvoicesProvider`; the new invoice is
   invisible until the user taps the manual "Refresh" button. Editing is also
   mislabeled: "Edit" on a saved invoice *duplicates* it (number + `-copy`).

Plus a correctness nit: intra/inter-state is decided by case-sensitive string
equality of free-text states (`"Delhi"` vs `"delhi"` → wrongly IGST).

## Current state

- `lib/features/calculator/presentation/widgets/quick_actions_bar.dart` lines
  136–155 (`_generateInvoice`): `final amount = double.tryParse(state.amountText)
  ?? 0;` then `notifier.updateLineItem(0, InvoiceLineItem(..., rate: amount,
  gstRate: state.effectiveRate, ...))`. For inclusive mode `amount` is the
  gross — `result.baseAmount` is the correct base.
- `lib/features/invoice/presentation/providers/invoice_provider.dart`:
  - `_createFresh()` (lines ~30–45): `invoiceNo = 'INV-${DateFormatter.compact(now)}-001'`.
  - `finaliseInvoice()`: `invoiceStore.save(finalised)` + `clearDraft()` +
    `state = _createFresh()`; **no** `savedInvoicesProvider` refresh.
  - `duplicateFrom(source)`: `invoiceNumber: '${source.invoiceNumber}-copy'`.
  - `updateSeller`/`updateBuyer`: `isIntraState = sellerState == buyerState`
    (raw string equality; both free-text fields).
- `lib/features/invoice/presentation/screens/invoice_history_screen.dart`:
  header exposes an explicit "Refresh invoices" action — the current
  workaround for the stale list.
- Tests that pin current behavior: `test/ui_regression_test.dart` taps
  "Refresh invoices" after finalising, and `duplicateFrom`/`-copy` is asserted
  via the "Duplicated" snackbar. These will need updating.

Repo conventions: persistence via `JsonListStore` keyed by id; state via
Riverpod notifiers; `DateFormatter` for date strings.

## Commands you will need

| Purpose   | Command                    | Expected on success |
|-----------|----------------------------|---------------------|
| Get deps  | `flutter pub get`          | exit 0              |
| Analyze   | `flutter analyze`          | exit 0, no issues   |
| Full test | `flutter test`             | all pass            |

## Scope

**In scope** (the only files you should modify):
- `lib/features/calculator/presentation/widgets/quick_actions_bar.dart`
- `lib/features/invoice/presentation/providers/invoice_provider.dart`
- `lib/features/invoice/data/datasources/invoice_local_datasource.dart` (only
  if a counter key must be stored here)
- `lib/features/invoice/presentation/screens/invoice_history_screen.dart`
  (only if the refresh action becomes redundant)
- `lib/features/invoice/presentation/screens/invoice_editor_screen.dart`
  (only if the "Edit" affordance changes)
- `test/ui_regression_test.dart`, `test/ui_smoke_test.dart` (update the
  refresh-tap steps)

**Out of scope** (do NOT touch):
- `lib/core/utils/gst_math.dart`, the GST formulas, slab list.
- The PDF generator (`generate_invoice_pdf.dart`) — plan 009.
- `InvoiceModel`/`InvoiceLineItem` JSON shape — old saved invoices must keep
  loading.

## Steps

### Step 1: Fix the inclusive-mode handoff base

In `quick_actions_bar.dart` `_generateInvoice`, compute the line rate from the
**calculation result**, not the raw text:

```dart
final result = state.result;             // already non-null (bar only shows with a result)
final lineRate = result.isInclusive ? result.baseAmount : amount;
```

Pass `rate: lineRate`. Add a comment that inclusive mode must use the
extracted base so GST isn't charged on a GST-inclusive value.

**Verify**: `flutter analyze` → exit 0.

### Step 2: Unique, sequential invoice numbers

Introduce a persisted counter so every created draft gets a unique number:

- Add a static/instance helper in `invoice_provider.dart` (or a tiny
  `InvoiceNumberGenerator` in `lib/features/invoice/domain/`): reads the
  current day-key counter from SharedPreferences (`invoice_no_counter_<yyyyMMdd>`),
  returns `INV-<yyyyMMdd>-<NNN>` with `NNN` zero-padded to 3 digits, then
  increments and persists. Handle the wrap at 999 (append `-<timestamp>` on
  overflow as a documented fallback, or reset per day — pick one and document).
- Use it in `_createFresh()` instead of the hardcoded `-001`.
- Keep the draft's number editable after creation (the editor already allows
  it via `updateInvoiceNumber`); the counter only seeds new drafts.
- `duplicateFrom`: keep the `-copy` suffix (duplicating is an explicit user
  action) but the *next fresh* draft still gets a new unique number.

**Verify**: two fresh drafts created in the same test session (call
`_createFresh` via `reset()` twice) have different invoice numbers. Add a unit
test for `InvoiceNumberGenerator` (same-day sequence `-001`, `-002`, …; new
day resets).

### Step 3: Keep the saved-invoices list in sync

In `finaliseInvoice()`, after `invoiceStore.save(finalised)`, also refresh the
list notifier:

```dart
await ref.read(savedInvoicesProvider.notifier).reload();
```

(The `savedInvoicesProvider` is available in the same provider file.) Verify
the list is reactive: after finalising and navigating back to the Invoices
tab, the new invoice appears **without** tapping "Refresh". Remove the manual
refresh header action only if the reload makes it fully redundant everywhere
(it can stay as a harmless affordance otherwise — prefer removing to reduce
UI noise, but confirm no test depends on its absence).

**Verify**: `flutter test test/ui_regression_test.dart` — update the invoice
test to drop the "Refresh invoices" tap and still find `INV-…` after
finalising.

### Step 4: Normalize state comparison

In `updateSeller`/`updateBuyer`, compare normalized states:

```dart
bool sameState(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();
```

Use it in both methods' `isIntraState` computation. Do not change the stored
strings — only the comparison.

**Verify**: `flutter analyze` → exit 0; add a notifier test: seller state
`"Delhi"`, buyer state `"delhi "` → `isIntraState == true`.

### Step 5: Regression tests for the whole flow

- **Inclusive handoff**: calculator `100` inclusive @ 18% → tap "Generate
  Invoice" → the first line item's rate field shows `84.75` and the invoice
  grand total equals the calculator's displayed total (₹100.00 after plan
  001's reconciliation — assert `find.text('₹100.00')` in the editor's summary
  or the preview).
- **Numbering**: two consecutive finalises produce distinct invoice numbers.
- **List sync**: after finalising, the Invoices tab shows the new invoice
  without the manual refresh (update the existing test that taps "Refresh
  invoices").
- **State normalization**: as in Step 4.

**Verify**: `flutter test` → all pass.

## Test plan

- New/updated tests: inclusive handoff (Step 5), number uniqueness (Step 2 +
  5), list auto-refresh (Step 3 + 5), state normalization (Step 4).
- Existing `ui_smoke_test.dart` / `ui_regression_test.dart` invoice journeys
  updated for the removed refresh tap.
- `gst_math_test.dart` untouched.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0
- [ ] Inclusive `100` @ 18% → Generate Invoice → line rate is `84.75`, invoice
      total is `₹100.00` (matches the calculator)
- [ ] Two fresh drafts in one day have different invoice numbers
- [ ] After finalising, the Invoices tab shows the invoice without tapping
      Refresh
- [ ] Seller `"Delhi"` + buyer `"delhi"` → Intra-State (CGST+SGST)
- [ ] No file outside the in-scope list is modified
- [ ] `plans/README.md` status row for 003 updated to DONE

## STOP conditions

Stop and report back (do not improvise) if:

- Any "Current state" excerpt doesn't match the live code.
- Removing the "Refresh invoices" button breaks a test you can't fix by
  relying on auto-refresh.
- The fix appears to require changing the `saved_invoices` storage key or
  `InvoiceModel` JSON fields.
- Plan 001 hasn't landed and the ₹100.00 assertion in Step 5 cannot hold — in
  that case keep the assertion but mark it `@Skip`-free by computing the
  expected total from the *pre-reconciliation* display (report the mismatch).

## Maintenance notes

- The invoice counter lives in SharedPreferences; a device-transfer or backup
  restore (plan 004 excludes nothing here) will carry it — that's fine, but if
  numbering must survive `prefs.clear()`-style resets, move it to a dedicated
  key that plan 004 explicitly backs up.
- "Edit" on a saved invoice is currently duplicate-and-open; if real
  in-place editing is wanted later, it's a separate feature (do not build it
  in this plan).
- If invoice numbers ever need a per-year or per-branch prefix, extend the
  generator — keep the format in one place.
