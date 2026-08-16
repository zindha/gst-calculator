# Plan 008: Stabilize invoice-editor text controllers

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
- **Effort**: M (a day-ish)
- **Risk**: LOW — controlled refactor of widget state, covered by the existing invoice regression tests
- **Depends on**: none
- **Category**: interaction/bug (code-quality anti-pattern with user-visible effect)
- **Planned at**: no VCS — audit date 2026-08-15
- **Issue**: n/a

## Why this matters

The invoice editor creates `TextEditingController` instances **inside
`build()`** via `TextEditingController.fromValue(...)` for six fields — the
four party fields (seller/buyer name, GSTIN, address, state) and the notes and
terms fields. Every rebuild (which happens on *every keystroke*, because
`onChanged` updates the Riverpod draft notifier) constructs a brand-new
controller: the old one is abandoned without `dispose()` (a resource leak
that repeats until GC) and the `TextField` re-attaches to a fresh controller,
which resets the caret and can break IME composition for non-Latin input
(Devanagari, Tamil, etc. — highly relevant for an Indian GST app). Users
typing in the middle of a field see the cursor jump, and every character
triggers a full draft save. The fix: manage the controllers as
`StatefulWidget` state, sync them with the model, and dispose them properly —
the pattern already used by `_InvoiceLineItemRowState` in the same file.

## Current state

- `lib/features/invoice/presentation/widgets/invoice_party_selector.dart` —
  four fields, each:
  ```dart
  controller: TextEditingController.fromValue(
    TextEditingValue(text: name),
  ),
  onChanged: onNameChanged,
  ```
  (lines ~82, 95, 108, 122). The widget is a `ConsumerWidget` (stateless);
  `name`/`gstin`/`address`/`state` come from the draft model.
- `lib/features/invoice/presentation/screens/invoice_editor_screen.dart` lines
  ~170 and ~184 — notes and terms:
  ```dart
  controller: TextEditingController.fromValue(
    TextEditingValue(text: invoice.notes ?? ''),
  ),
  ```
  inside the `build` of a `ConsumerWidget`.
- Contrast: `lib/features/invoice/presentation/widgets/invoice_line_item_row.dart`
  (`_InvoiceLineItemRowState`) is a `StatefulWidget` that creates controllers
  once in `initState` and syncs in `didUpdateWidget` — the correct pattern to
  copy.
- The draft notifier (`invoice_provider.dart`) persists the full draft on
  every mutation (`_autoSave`), so keystrokes are already saved; this plan
  does not change persistence.

Repo conventions: stateful forms keep controllers in `initState` + dispose
(see `business_profile_edit_screen.dart` and `invoice_line_item_row.dart`);
`A11y` helper for haptics.

## Commands you will need

| Purpose   | Command                    | Expected on success |
|-----------|----------------------------|---------------------|
| Get deps  | `flutter pub get`          | exit 0              |
| Analyze   | `flutter analyze`          | exit 0, no issues   |
| Full test | `flutter test`             | all pass            |

## Scope

**In scope** (the only files you should modify):
- `lib/features/invoice/presentation/widgets/invoice_party_selector.dart`
- `lib/features/invoice/presentation/screens/invoice_editor_screen.dart`

**Out of scope** (do NOT touch):
- The draft notifier and persistence (already correct; unchanged).
- The line-item row widget (already correct).
- Any other screen (no other screen uses the fromValue-in-build pattern —
  verify with `grep -rn "fromValue" lib/` before starting).

## Steps

### Step 1: Convert `InvoicePartySelector` to a StatefulWidget

- Change `class InvoicePartySelector extends ConsumerWidget` to
  `ConsumerStatefulWidget` + `ConsumerState`.
- In `initState`, create four controllers from the initial
  `widget.name/gstin/address/state`; dispose them in `dispose()`.
- In `didUpdateWidget`, sync controller text **only when the model value
  differs from the controller's current text AND the change did not originate
  from this field's own `onChanged`** (otherwise the caret resets on every
  keystroke). The standard guard:

  ```dart
  @override
  void didUpdateWidget(InvoicePartySelector old) {
    super.didUpdateWidget(old);
    void sync(TextEditingController c, String value) {
      if (c.text != value) {
        c.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      }
    }
    sync(_nameCtrl, widget.name);
    sync(_gstinCtrl, widget.gstin);
    sync(_addressCtrl, widget.address);
    sync(_stateCtrl, widget.state);
  }
  ```

  Because `onChanged` fires before the model updates, `c.text == value` for
  self-originated changes and the sync no-ops — the caret survives. Profile
  selection (external change) moves the caret to the end, which is correct.
- Replace the `fromValue` controllers in `build` with the instance
  controllers. Keep `onChanged`, labels, `isDense`, capitalizations, and the
  "From Profile" button exactly as they are.

**Verify**: `flutter analyze` → exit 0.

### Step 2: Move notes/terms controllers into editor state

- Convert `InvoiceEditorScreen` from `ConsumerWidget` to
  `ConsumerStatefulWidget` (`ConsumerState<InvoiceEditorScreen>`), moving the
  `theme`/`invoice`/`notifier` reads into `build` as today.
- `initState`: create `_notesCtrl` and `_termsCtrl` from
  `widget`-less reads — the draft is read via `ref`; in a `ConsumerState`,
  read `ref.read(invoiceDraftProvider)` inside `initState` (allowed for the
  initial value), or initialize empty and sync in `didChangeDependencies`.
- `dispose()` both controllers.
- `didUpdateWidget`/build-time sync: same guarded `sync` pattern against
  `invoice.notes`/`invoice.terms` so external resets (`Reset to empty`,
  `duplicateFrom`, finalise→fresh) clear or repopulate the fields, while
  keystrokes keep the caret.
- Replace the two `fromValue` usages with the instance controllers.

**Verify**: `flutter analyze` → exit 0.

### Step 3: Regression tests

The existing invoice journey in `test/ui_regression_test.dart` already types
into seller/buyer/notes fields and asserts values flow through (`Acme
Traders`, notes text). Add two focused assertions to that test (or a new
testWidgets):

- Typing a multi-character value into "Seller Name" leaves the field showing
  the full value and the caret at the end (assert `controller.text` and
  `controller.selection` via the widget finder).
- After tapping "Reset to empty" from the editor menu, the notes/terms fields
  clear (model change propagates to the controllers).

**Verify**: `flutter test test/ui_regression_test.dart` → all pass; `flutter
test` → all pass.

## Test plan

- Extend `test/ui_regression_test.dart` invoice journey per Step 3.
- No changes to `invoice_provider.dart` tests (none exist; persistence is
  covered by the journey tests).

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `grep -rn "fromValue" lib/` returns no matches
- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0
- [ ] Typing in a party field preserves the caret position (no jump to start)
- [ ] External model changes (profile pick, reset, duplicate) propagate into
      the fields
- [ ] No controller is created in a `build` method (grep `build` + `controller:`)
- [ ] No file outside the in-scope list is modified
- [ ] `plans/README.md` status row for 008 updated to DONE

## STOP conditions

Stop and report back (do not improvise) if:

- Any "Current state" excerpt doesn't match the live code.
- `grep -rn "fromValue" lib/` finds occurrences outside the two in-scope
  files (report them; do not silently expand scope).
- The guarded sync can't prevent caret resets in a `TextField` (test proves a
  jump) — stop and report rather than working around it in the widget.
- A regression test that types into fields fails in a way suggesting lost
  input (report the exact sequence).

## Maintenance notes

- This is the reference pattern for any future form with model-backed fields:
  controllers in `initState`, guarded sync in `didUpdateWidget`, dispose in
  `dispose()`.
- The line-item rows already follow this pattern — keep them consistent.
- If the draft notifier is ever changed to debounce `_autoSave`, the caret
  logic here is unaffected (controllers are decoupled from persistence).
