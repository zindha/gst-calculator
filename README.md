# GST Calculator

A Flutter app for calculating Indian GST (Goods & Services Tax) and tracking
calculation history — built for Android, iOS, and web.

## Features

- **GST calculator** — exclusive ("add GST") and inclusive ("extract GST")
  modes, across all Indian slabs (0%, 0.25%, 3%, 5%, 12%, 18%, 28%).
- **Intra-state vs inter-state** — automatic CGST + SGST split, or single IGST.
- **Calculation history** — every calculation is saved locally; delete
  individual entries or clear all.
- **CSV export** — share calculation history as CSV.
- **Share / copy** — copy or share any calculation breakdown.
- **Theming** — light/dark mode.
- **Onboarding** — one-time intro shown on first launch.

## Tech stack

- **Flutter** (Dart SDK `^3.12.2`)
- **[flutter_riverpod](https://riverpod.dev)** — state management
- **[shared_preferences](https://pub.dev/packages/shared_preferences)** — local
  persistence (history, settings)
- **[share_plus](https://pub.dev/packages/share_plus)** — share breakdowns and CSV
- **[intl](https://pub.dev/packages/intl)** — Indian Rupee formatting (`en_IN`)

## Project structure

The codebase follows a feature-first clean architecture:

```
lib/
├── main.dart            # App entry point (binding init, locale, orientation)
├── app.dart             # Root widget + bottom navigation shell
├── core/                # Shared, feature-agnostic code
│   ├── constants/       # App strings, GST rates
│   ├── theme/           # Light/dark themes + brand tokens
│   ├── utils/           # GST math, currency formatting, validators, a11y
│   └── widgets/         # Reusable UI (headers, chips, empty state)
└── features/            # One directory per feature
    ├── calculator/      # domain (entities, use cases) + presentation
    ├── history/         # data (local datasource) + presentation
    ├── csv_export/
    ├── onboarding/
    └── settings/
```

## Getting started

```bash
# Install dependencies
flutter pub get

# Run on a connected device / emulator
flutter run

# Run tests
flutter test

# Static analysis
flutter analyze
```

## Build

```bash
# Android app bundle (for Play Store)
flutter build appbundle

# Android APK (for direct install)
flutter build apk

# iOS archive (requires macOS + Xcode)
flutter build ipa

# Web
flutter build web
```

## Continuous integration (GitHub Actions)

A workflow (`.github/workflows/build-apk.yml`) builds both `app-debug.apk`
and `app-release.apk` on every push/PR and uploads them as artifacts; pushing
a `v*` tag also attaches both APKs to a GitHub Release.

The release APK is signed with the debug keystore by default. To sign it with
your upload key, run the one-shot setup script (generates the keystore if
needed, then stores all four secrets on the repo):

```bash
./tool/setup-release-signing.sh owner/repo
```

It requires `keytool` (any JDK) and an authenticated `gh` CLI. The secrets
it sets are `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, and
`KEY_PASSWORD` — the keystore itself (`android/app/upload-keystore.jks`) is
gitignored and must be backed up separately.

## Release (Play Store)

### 1. One-time setup

- **Application ID** — set your own reverse-domain ID for `applicationId` in
  `android/app/build.gradle.kts` before publishing. It cannot be changed after
  your app is on the Play Store.
- **App icon** — generated from the root `app-icon.png` by the
  `flutter_launcher_icons` dev tool (Android legacy + adaptive, iOS, web). To
  rebrand, replace `app-icon.png` and re-run
  `dart run flutter_launcher_icons`. The splash logo is a separate asset
  (`assets/icon/splash_logo.png`, regenerated with
  `dart run flutter_native_splash:create`).
- **Privacy policy** — host `PRIVACY_POLICY.md` at a public URL (update the
  contact email first) and link it from the Play Console.

### 2. Release signing

Generate an upload key (do this once — back it up; you can never update your
app without it):

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key.properties` (never commit it — it's gitignored):

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

### 3. Build the release bundle

```bash
flutter build appbundle
```

Upload the `.aab` from `build/app/outputs/bundle/release/` to the Play Console.

### 4. Play Console checklist

- Complete the Data safety form (the app stores data locally only — see
  `PRIVACY_POLICY.md`).
- **Backup allowlist** — Android cloud backup is restricted to non-sensitive
  prefs keys by the allowlists in `android/app/src/main/res/xml/backup_rules.xml`
  and `data_extraction_rules.xml` (settings + calculation history only). If
  you ever add a SharedPreferences key, classify it and update both XML files.
- Set content rating and target audience.
- Add screenshots and a feature graphic.
- Opt in to Play App Signing and upload your upload key.
