# Plan 009: PDF "amount in words" — paise and crore support

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
- **Risk**: LOW — pure function + one call site; unit-tested
- **Depends on**: plans/001 (derive words from the reconciled grand total so
  the words match the printed number)
- **Category**: correctness/bug
- **Planned at**: no VCS — audit date 2026-08-15
- **Issue**: n/a

## Why this matters

The generated invoice PDF prints an "Amount in words" line that is wrong for
two common cases:

1. **Paise are truncated.** `_numberToWords(invoice.grandTotal.toInt())`
   drops the decimal part: ₹118.75 prints "One Hundred Eighteen Rupees Only",
   understating the amount by 75 paise. Invoices are settlement documents;
   the words must state the full amount.
2. **Values ≥ ₹1 crore break.** `convert()` only handles 1–99, and the lakh
   group passes values ≥ 100 straight through: `convert(100)` returns `''`, so
   ₹1,00,00,000 prints " Rupees Only" with no amount at all. Crore-scale
   invoices are routine for real businesses.

## Current state

- `lib/features/invoice/domain/usecases/generate_invoice_pdf.dart`:
  - `_buildTaxSummary` line 358:
    ```dart
    pw.Text('Amount in words: ${_numberToWords(invoice.grandTotal.toInt())}', ...)
    ```
  - `_numberToWords(int n)` (lines ~379–430): handles lakh (÷100000),
    thousand, hundred, remainder; `convert(x)` returns `''` for `x >= 100`;
    returns `'... Rupees Only'`.
- `lib/core/utils/currency_formatter.dart` — the display formatter (not used
  for words).
- No existing unit tests for `_numberToWords` (it's private, inside the use
  case).

Repo conventions: pure helpers live in `lib/core/utils/` with tests in
`test/core/utils/`; the PDF use case is otherwise self-contained.

## Commands you will need

| Purpose   | Command                    | Expected on success |
|-----------|----------------------------|---------------------|
| Get deps  | `flutter pub get`          | exit 0              |
| Analyze   | `flutter analyze`          | exit 0, no issues   |
| Unit test | `flutter test test/core/utils/amount_in_words_test.dart` | all pass |
| Full test | `flutter test`             | all pass            |

## Scope

**In scope** (the only files you should modify):
- `lib/core/utils/amount_in_words.dart` (create — the number-to-words
  function)
- `lib/features/invoice/domain/usecases/generate_invoice_pdf.dart` (call the
  new helper; remove the private `_numberToWords`)
- `test/core/utils/amount_in_words_test.dart` (create)
- `test/ui_regression_test.dart` (only if a PDF-content assertion is added)

**Out of scope** (do NOT touch):
- PDF layout, fonts, table structure, or any other summary row.
- `InvoiceModel` fields or serialization.
- Currency display formatting elsewhere.

## Steps

### Step 1: Write the correct number-to-words function

Create `lib/core/utils/amount_in_words.dart`:

```dart
/// Converts a money amount to Indian number-in-words, e.g.
/// `118.75` -> "One Hundred Eighteen Rupees and Seventy-Five Paise Only".
String amountInWords(double amount);
```

Requirements:

- Split into whole rupees (`amount.floor()`) and paise
  (`(amount * 100).round() % 100`) — round paise, don't truncate.
- Indian numbering: crores (1e7), lakhs (1e5), thousands (1e3), hundreds.
- `convert(x)` must handle 0–999 (extend the existing 1–99 logic with a
  hundreds case) so crore/lakh/thousand groups work.
- Output format: `<Rupees words> Rupees[ and <Paise words> Paise] Only`.
  Zero rupees with paise → `"Seventy-Five Paise Only"`; zero amount →
  `"Zero Rupees Only"`.
- Handle `amount < 0` by returning an error string or throwing
  `ArgumentError` (the PDF path never passes negatives — the invoice total is
  validated > 0); document the choice.

**Verify**: `flutter analyze` → exit 0.

### Step 2: Unit tests

Create `test/core/utils/amount_in_words_test.dart` covering:

- `118.75` → "One Hundred Eighteen Rupees and Seventy-Five Paise Only"
- `1000` → "One Thousand Rupees Only"
- `100000` → "One Lakh Rupees Only"
- `10000000` → "One Crore Rupees Only"
- `1234567.89` → contains "Twelve Lakh Thirty-Four Thousand Five Hundred
  Sixty-Seven Rupees and Eighty-Nine Paise" (assert exact string)
- `0.75` → "Seventy-Five Paise Only"
- `0` → "Zero Rupees Only"
- A paise-rounding case: `118.999` → "...Rupees and... " (100.0 rounds to
  100 paise → "One Rupee"? decide: rupees = 118, paise = round(99.9) = 100 →
  carry: rupees 119, paise 0 — implement the carry correctly and assert it).

**Verify**: `flutter test test/core/utils/amount_in_words_test.dart` → all pass.

### Step 3: Wire into the PDF

In `generate_invoice_pdf.dart`:

- Import `../../../../core/utils/amount_in_words.dart`.
- Replace line 358 with `Amount in words: ${amountInWords(invoice.grandTotal)}`
  (pass the full double, not `toInt()`).
- Delete the private `_numberToWords` and its now-unused `units`/`teens`/
  `tens`/`convert` closures.
- Derive from the **reconciled** grand total if plan 001 has landed
  (see dependency note) so words match the printed 2-dp number; if 001 hasn't
  landed, use `invoice.grandTotal` directly — the function rounds internally.

**Verify**: `flutter analyze` → exit 0.

### Step 4: Optional PDF-content regression

The existing PDF tests only assert that a file was produced/shared, not its
content. If the `pdf` package makes text extraction easy in a unit test
(parse `doc.save()` bytes), add an assertion that the generated PDF's text
contains the expected words for a known invoice; otherwise rely on the unit
tests in Step 2 and note the gap.

**Verify**: `flutter test` → all pass.

## Test plan

- New `test/core/utils/amount_in_words_test.dart` (Step 2) — the functional
  guarantee.
- Existing `ui_regression_test.dart` PDF tests unchanged (file produced +
  shared still holds).

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `flutter analyze` exits 0
- [ ] `test/core/utils/amount_in_words_test.dart` exists and all its tests pass
- [ ] `grep -rn "_numberToWords" lib/` returns no matches
- [ ] `flutter test` exits 0
- [ ] A ₹118.75 invoice's PDF would print "…Rupees and Seventy-Five Paise Only"
      (verified by unit test)
- [ ] A ₹1,00,00,000 invoice's words contain "One Crore"
- [ ] No file outside the in-scope list is modified
- [ ] `plans/README.md` status row for 009 updated to DONE

## STOP conditions

Stop and report back (do not improvise) if:

- Any "Current state" excerpt doesn't match the live code.
- The paise-carry rule (`118.999` → 119 rupees) differs from what a reviewer
  expects — implement the mathematically correct carry and note it in the PR
  (do not silently drop paise).
- Deleting `_numberToWords` breaks another call site (grep first).

## Maintenance notes

- `amountInWords` is the single source of truth for words; reuse it if the
  calculator or history ever prints amounts in words.
- The function intentionally supports crores now; if the app ever needs
  Arabic numerals in words or a different currency name, extend it there.
- Keep the paise-rounding behavior documented — a future change to
  "round-half-up vs round-half-even" would be a deliberate policy change.
