# Plan 004: Keep sensitive data out of Android cloud backup; fix the privacy policy

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
- **Effort**: S (hours)
- **Risk**: LOW — XML + docs changes; no Dart logic
- **Depends on**: none
- **Category**: security/privacy
- **Planned at**: no VCS — audit date 2026-08-15
- **Issue**: n/a

## Why this matters

The app stores **bank account numbers, IFSC codes, GSTINs, addresses, and
phone numbers** in plaintext SharedPreferences (business profiles and saved
invoices). Android's Auto Backup is enabled (`allowBackup="true"`) and the
backup rules **include the entire `sharedpref` domain**, so all of that data is
uploaded to the user's Google Drive cloud backup — and carried across on
device-to-device transfer. Meanwhile `PRIVACY_POLICY.md` states the app "does
not ... store any personal data on external servers" and data is "stored
locally on your device only". The policy is inaccurate, and the cloud copy of
bank details is a genuine privacy/security exposure the user never consented
to. This plan excludes the sensitive keys from backup and corrects the policy.

## Current state

- `android/app/src/main/res/xml/backup_rules.xml`:
  `<full-backup-content><include domain="sharedpref" path="." /></full-backup-content>`
- `android/app/src/main/res/xml/data_extraction_rules.xml`: cloud-backup and
  device-transfer both `<include domain="sharedpref" path="." />`.
- `android/app/src/main/AndroidManifest.xml`: `android:allowBackup="true"` +
  `android:fullBackupContent="@xml/backup_rules"` +
  `android:dataExtractionRules="@xml/data_extraction_rules"`.
- Sensitive data locations (all SharedPreferences keys, see the prefs keys in
  `lib/features/settings/presentation/providers/settings_provider.dart` and
  the stores in `lib/features/business_profile/data/datasources/` and
  `lib/features/invoice/data/datasources/invoice_local_datasource.dart`):
  - `business_profiles` — `BusinessProfile.toJson` includes
    `bankAccountNumber`, `bankIfsc`, `bankName`, `gstin`, `phone`, `email`,
    `address` (plaintext).
  - `saved_invoices` / `current_draft` — `InvoiceModel.toJson` includes the
    seller's bank details and party GSTINs/addresses.
- `PRIVACY_POLICY.md` — claims local-only storage, no transmission.

## Commands you will need

| Purpose   | Command                    | Expected on success |
|-----------|----------------------------|---------------------|
| Get deps  | `flutter pub get`          | exit 0              |
| Analyze   | `flutter analyze`          | exit 0, no issues   |
| Full test | `flutter test`             | all pass (no code behavior change; smoke) |
| XML check | `python3 -c "import xml.dom.minidom,sys; [xml.dom.minidom.parse(f) for f in sys.argv[1:]]" android/app/src/main/res/xml/*.xml` (or `xmllint`) | no parse errors |

## Scope

**In scope** (the only files you should modify):
- `android/app/src/main/res/xml/backup_rules.xml`
- `android/app/src/main/res/xml/data_extraction_rules.xml`
- `PRIVACY_POLICY.md`
- `README.md` (one sentence under the Play Console checklist about backup, if
  it mentions local-only data)
- `lib/features/settings/presentation/providers/settings_provider.dart`
  (only if you introduce a `secure_*` key namespace — see Step 2 option)

**Out of scope** (do NOT touch):
- App Dart logic, GST math, UI, or tests that assert behavior.
- Encrypting the whole SharedPreferences store (out of scope for this plan;
  see maintenance note).

## Steps

### Step 1: Exclude sensitive keys from cloud backup

Replace the blanket `include` with an explicit allowlist of **non-sensitive**
keys for cloud backup, and keep device-to-device transfer intact (transfer to
the same user's new device is the *desired* continuity feature; the concern is
the cloud copy). Concretely, in `data_extraction_rules.xml`:

```xml
<data-extraction-rules>
    <cloud-backup>
        <!-- Allowlist: settings and calculation history are not sensitive.
             Business profiles (bank details, GSTINs) and invoices are
             excluded from cloud backup. -->
        <include domain="sharedpref" path="theme_mode"/>
        <include domain="sharedpref" path="default_slab"/>
        <include domain="sharedpref" path="default_calc_type"/>
        <include domain="sharedpref" path="default_trans_type"/>
        <include domain="sharedpref" path="accent_color"/>
        <include domain="sharedpref" path="onboarding_done"/>
        <include domain="sharedpref" path="calculation_history"/>
        <!-- Exclude everything else (business profiles, invoices, draft,
             invoice counter, any future key). -->
        <exclude domain="sharedpref" path="."/>
    </cloud-backup>
    <device-transfer>
        <include domain="sharedpref" path="."/>
    </device-transfer>
</data-extraction-rules>
```

Key facts to respect:
- `include` paths match SharedPreferences keys exactly (`theme_mode`,
  `default_slab`, `default_calc_type`, `default_trans_type`, `accent_color`,
  `onboarding_done` — from `settings_provider.dart`; `calculation_history` —
  from `history_local_datasource.dart`).
- `business_profiles`, `saved_invoices`, `current_draft`, and
  `invoice_no_counter_*` (plan 003) are intentionally **excluded** from cloud.
- An `exclude domain="sharedpref" path="."` after the includes guarantees
  future keys are excluded by default (include-allowlist wins for the named
  keys; the trailing exclude catches the rest).

Mirror the same change in `backup_rules.xml` (legacy `full-backup-content` for
Android 11 and below) so behavior is consistent:

```xml
<full-backup-content>
    <include domain="sharedpref" path="theme_mode"/>
    <!-- … same allowlist … -->
    <exclude domain="sharedpref" path="."/>
</full-backup-content>
```

**Verify**: both XML files parse; `flutter analyze` and `flutter test` still
pass (no Dart change).

### Step 2: (Recommended) stop writing bank details to plaintext prefs

Business profile bank fields and the invoice's embedded bank details remain in
plaintext on-device even after backup exclusion. If the effort is acceptable,
move the four bank fields (`bankAccountName`, `bankAccountNumber`, `bankIfsc`,
`bankName`) into a separately-persisted, excluded key (still
SharedPreferences) as a first step, or — the stronger fix — store them via
`flutter_secure_storage` (Keychain/Keystore). This requires adding the
dependency `flutter_secure_storage` to `pubspec.yaml`, migrating
`BusinessProfile.toJson/fromJson` and the invoice model to reference the
secure store, and a data migration for existing profiles. **If adding a
dependency is out of scope for this change, implement Step 1 only and record
the plaintext-on-device risk in the PR description** — do not silently skip;
say so in the final status update.

**Verify (if implemented)**: unit test that profile save writes no bank value
into the `business_profiles` prefs string; `flutter test` passes.

### Step 3: Correct the privacy policy

Update `PRIVACY_POLICY.md`:

- Replace the "never uploaded / external servers" absolutes with an accurate
  statement: the app stores data locally; non-sensitive data (settings,
  calculation history) may be included in Android's optional cloud backup; bank
  details, GSTINs, and invoice data are excluded from cloud backup and remain
  on-device.
- Update the "Data retention & deletion" section to note that uninstalling
  removes local data and that cloud-backup copies, if any, are governed by
  Google's backup settings.
- Replace the placeholder contact email (`your-email@example.com`) — the README
  already flags this as a pre-release TODO.

Also add one line to `README.md` under the Play Console checklist noting the
backup allowlist so future edits to prefs keys revisit the XML files.

**Verify**: no code change; docs read correctly.

## Test plan

- No new Dart tests required for Step 1 (config + docs). If Step 2 is
  implemented, add the secure-store round-trip test noted there.
- A manual sanity check on a device: after backup, restore on a fresh install,
  profiles/invoices must NOT be restored from cloud while settings/history
  are.

## Done criteria

Machine-checkable. ALL must hold:

- [ ] `data_extraction_rules.xml` contains the allowlist + trailing
      `<exclude domain="sharedpref" path="."/>` for cloud-backup
- [ ] `backup_rules.xml` mirrors the allowlist for legacy full backup
- [ ] Both XML files parse without error
- [ ] `PRIVACY_POLICY.md` no longer claims no external copies and reflects the
      backup behavior; placeholder email replaced or explicitly flagged
- [ ] `flutter analyze` and `flutter test` pass
- [ ] No file outside the in-scope list is modified
- [ ] `plans/README.md` status row for 004 updated to DONE

## STOP conditions

Stop and report back (do not improvise) if:

- Any "Current state" excerpt doesn't match the live code.
- An Android build tooling version rejects the trailing exclude (unlikely;
  report the error rather than dropping the exclude).
- You find a prefs key used by the app that is missing from the allowlist
  (settings/history) — add it only if it's clearly non-sensitive, otherwise
  report.

## Maintenance notes

- **Any future SharedPreferences key must be classified** (cloud-safe or not)
  and added to/kept out of the allowlist. Add a comment in the XML to that
  effect.
- The real long-term fix for bank details is `flutter_secure_storage`; plan
  for it separately.
- Device-to-device transfer intentionally still carries profiles/invoices —
  that's the feature; only the *cloud* copy is excluded.
