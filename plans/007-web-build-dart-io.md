# Plan 007: Restore the web build (remove `dart:io` from shared paths)

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
- **Risk**: LOW-MED — platform-conditional refactor; Android/iOS behavior unchanged
- **Depends on**: none
- **Category**: platform/tooling (docs-vs-code mismatch)
- **Planned at**: no VCS — audit date 2026-08-15
- **Issue**: n/a

## Why this matters

The README and pubspec (launcher-icon web config, `web/` directory, "built for
Android, iOS, and web") claim web support, but three shared code paths import
`dart:io`, which does not compile for web: `flutter build web` fails at
compile time. The CSV export (history + invoices), the business-profile logo
picker, and the invoice PDF share/save all use `dart:io` (`File`,
`getTemporaryDirectory`) directly. Either the web target must actually build
and these features must degrade gracefully, or the web claim must be dropped.
This plan makes the app compile for web while keeping the Android/iOS
experience byte-for-byte identical, and makes each feature behave sensibly on
web.

## Current state

- `lib/features/csv_export/csv_export.dart` line 1: `import 'dart:io';` —
  `shareHistoryCsv`/`shareInvoiceCsv` write a `File` to
  `getTemporaryDirectory()` (from `path_provider`) then share via
  `SharePlus.instance.share(files: [XFile(file.path), ...])`.
- `lib/features/business_profile/presentation/screens/business_profile_edit_screen.dart`
  line 1: `import 'dart:io';` — logo preview uses `File(_logoPath!).existsSync()`
  and `Image.file(...)`.
- `lib/features/invoice/presentation/screens/invoice_preview_screen.dart`
  line 1: `import 'dart:io';` — `_sharePdf`/`_savePdf` write a PDF `File` to
  temp/documents directory.
- `path_provider` returns an in-memory fallback on web but `dart:io.File` is a
  compile-time error regardless.
- `test/ui_smoke_test.dart` and `test/ui_regression_test.dart` import
  `dart:io` too — tests run on the VM only, so they are fine; do not change
  them for web.

Repo conventions: `XFile` (cross_file) already used for sharing; plugins
(share_plus, printing) already support web.

## Commands you will need

| Purpose   | Command                    | Expected on success |
|-----------|----------------------------|---------------------|
| Get deps  | `flutter pub get`          | exit 0              |
| Analyze   | `flutter analyze`          | exit 0, no issues   |
| Web build | `flutter build web`        | exit 0, builds `build/web` |
| Full test | `flutter test`             | all pass            |

## Scope

**In scope** (the only files you should modify):
- `lib/features/csv_export/csv_export.dart`
- `lib/features/business_profile/presentation/screens/business_profile_edit_screen.dart`
- `lib/features/invoice/presentation/screens/invoice_preview_screen.dart`
- `README.md` (only if the web claim is dropped)

**Out of scope** (do NOT touch):
- Android/iOS manifests, Gradle, or iOS config.
- `dart:io` in test files (they run on the VM).
- The PDF generation logic itself (`generate_invoice_pdf.dart` — pure bytes,
  already platform-agnostic).

## Steps

### Step 1: Platform-conditional file write for CSV export

In `csv_export.dart`, replace the direct `dart:io` usage with a small
abstraction that works on all platforms. Concretely:

- Remove `import 'dart:io';`.
- Add a helper `Future<Uint8List> _csvBytes(String csv) => Uint8List.fromList(utf8.encode(csv));`
  and a function that produces an `XFile` from in-memory bytes without the
  filesystem:
  - Option A (recommended): use `XFile.fromData(bytes, mimeType:
    'text/csv', name: '<filename>.csv')` and pass it directly to
    `SharePlus.instance.share(files: [...])` — `XFile.fromData` works on every
    platform and share_plus handles it. This removes the temp-file dance
    entirely and is the cleanest fix.
- Keep `getTemporaryDirectory()` usage only behind a `kIsWeb` guard if a
  platform genuinely needs a real path (it doesn't for `XFile.fromData`).

**Verify**: `flutter build web` compiles; `flutter test` still passes
(`ui_regression_test.dart` asserts the shared call's arguments contain
`.csv` — `XFile.fromData` names still carry the `.csv` filename, so keep the
`name:` parameter; adjust the assertion if it checks `file.path` instead of
`file.name`).

### Step 2: Logo preview without `dart:io`

In `business_profile_edit_screen.dart`:

- The picker (`image_picker`) already returns an `XFile` — keep the picked
  path string in state as today, but render the preview via `Image.file` only
  when running on IO platforms. Use `kIsWeb` (from `package:flutter/foundation.dart`)
  plus `defaultTargetPlatform` checks:
  - On IO: keep `File(_logoPath!).existsSync()` / `Image.file(...)`.
  - On web: `Image.network`/`Image.memory` is wrong for a local path — the
    correct web path is to keep the picked `XFile` and render with
    `Image.file`-equivalent `Image.memory(await xfile.readAsBytes())`, or
    simply show the placeholder on web and store the path for later.
  - Recommended: keep the `XFile? _logoFile` alongside `_logoPath`; render
    `Image.memory(await _logoFile.readAsBytes())` on web, `Image.file` on IO.
- The `existsSync()` guard is only needed for restoring a saved path after an
  app restart on IO; on web the path is not re-usable, so show the placeholder
  when `kIsWeb`.

**Verify**: `flutter build web` compiles; `flutter test` passes (the
`image_picker` mock returns null, so the logo branch is untouched in tests).

### Step 3: PDF share/save on web

In `invoice_preview_screen.dart`:

- `_sharePdf`: replace the temp-file write with
  `XFile.fromData(pdf, mimeType: 'application/pdf', name:
  '${invoice.invoiceNumber}.pdf')` passed to share_plus (works everywhere).
- `_savePdf`: `getApplicationDocumentsDirectory()` + `File.writeAsBytes` is
  IO-only. On web, use the browser download: `printing`'s
  `Printing.sharePdf` already opens the browser's save dialog on web, or use
  the `printing` package's `Printing.layoutPdf`. Simplest correct web path:
  on `kIsWeb`, route "Save PDF" to `Printing.sharePdf(bytes: pdf, filename:
  ...)` (native save dialog); on IO keep the documents-directory write.
- Keep `_showPdf`/`_printPdf` as-is (printing handles web).

**Verify**: `flutter build web` compiles; `flutter test` passes (the existing
test asserts a real `.pdf` file lands in `/tmp` on IO — that behavior must
remain for the VM, so keep the IO branch intact).

### Step 4: If the web claim is dropped instead

If a decision is made to drop web support (Android-first), then: remove the
web section from `README.md`, remove `web/` generation references in
`pubspec.yaml` (flutter_launcher_icons web config, flutter_native_splash web)
— do **not** remove `web/` itself if the default template is harmless — and
record the decision in `plans/README.md` "considered and rejected" with the
reason (Android is the production target). Prefer Step 1–3 (make web work);
only take this path on explicit instruction.

**Verify**: `flutter analyze` passes; no dead web references remain in docs.

## Test plan

- `flutter test` (all) — the CSV/PDF share assertions keep passing (they
  assert filename/extension in the share arguments, which `XFile.fromData`
  preserves).
- `flutter build web` — new verification gate proving the target compiles.
- Manual: on web, CSV export and PDF view/save open the browser share/save
  dialogs.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `grep -rn "dart:io" lib/` returns no matches
- [ ] `flutter build web` exits 0
- [ ] `flutter analyze` exits 0
- [ ] `flutter test` exits 0 (VM behavior unchanged: CSV and PDF share still
      go through share_plus with `.csv`/`.pdf` filenames; Save PDF still
      writes a real file on IO)
- [ ] No Android/iOS config changed
- [ ] `plans/README.md` status row for 007 updated to DONE

## STOP conditions

Stop and report back (do not improvise) if:

- Any "Current state" excerpt doesn't match the live code.
- `flutter build web` fails for a reason unrelated to `dart:io` (report the
  error; do not start fixing unrelated web issues).
- A plugin (share_plus/printing/path_provider) lacks web support for the API
  you switched to (check pub.dev docs for the version in `pubspec.lock`
  before picking a different API).
- The existing `/tmp`-file assertions in `ui_regression_test.dart` break in a
  way you can't reconcile with `XFile.fromData` (report the exact assertion).

## Maintenance notes

- `XFile.fromData` is the pattern for all future share flows — no temp-file
  writes.
- The `kIsWeb` branches must stay minimal and documented; a future "save to
  file" feature on web should use `package:file_selector` rather than growing
  the branches.
- Re-run `flutter build web` in CI once added; the web target currently has no
  CI gate, which is why this regressed.
