#!/usr/bin/env bash
#
# One-time setup: generate the release upload keystore and store it in
# GitHub Actions secrets so the release APK is signed with your upload key.
#
# Prerequisites:
#   - keytool (ships with any JDK: `apt install default-jdk` / `brew install openjdk`)
#   - gh CLI authenticated against the target repository
#     (`gh auth login` — the repo is detected from the current remote)
#
# Usage:
#   ./tool/setup-release-signing.sh [owner/repo]
#
# It is safe to re-run: an existing keystore is reused, and existing
# secrets are re-set to the same values.
#
# The keystore is generated in ./android/app/upload-keystore.jks (gitignored)
# and must be backed up — you can never update the app on the Play Store
# without it.
set -euo pipefail

REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)}"
if [[ -z "$REPO" ]]; then
  echo "error: could not detect the repository. Pass it explicitly:" >&2
  echo "  $0 owner/repo" >&2
  exit 1
fi

command -v keytool >/dev/null 2>&1 || {
  echo "error: keytool not found. Install a JDK first (e.g. 'apt install default-jdk')." >&2
  exit 1
}
command -v gh >/dev/null 2>&1 || {
  echo "error: gh not found or not authenticated. Run 'gh auth login' first." >&2
  exit 1
}

KS_DIR="android/app"
KS_FILE="$KS_DIR/upload-keystore.jks"

# ── 1. Generate the upload keystore (reuse an existing one) ──────────────
if [[ -f "$KS_FILE" ]]; then
  echo "Using existing keystore: $KS_FILE"
  KEY_ALIAS="${KEY_ALIAS:-upload}"
else
  echo "Generating a new upload keystore at $KS_FILE"
  read -rsp "Keystore password (store + key; keep it safe): " STORE_PASS
  echo
  read -rp "Key alias [upload]: " KEY_ALIAS
  KEY_ALIAS="${KEY_ALIAS:-upload}"
  keytool -genkey -v \
    -keystore "$KS_FILE" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASS" -keypass "$STORE_PASS" \
    -dname "CN=GST Calculator,O=GST Calculator,C=IN"
  echo "Keystore created. BACK THIS FILE UP — without it you cannot update the app."
fi

if [[ -z "${KEYSTORE_PASSWORD:-}" ]]; then
  read -rsp "Keystore password: " KEYSTORE_PASSWORD
  echo
fi
KEY_ALIAS="${KEY_ALIAS:-upload}"
if [[ -z "${KEY_PASSWORD:-}" ]]; then
  KEY_PASSWORD="$KEYSTORE_PASSWORD"
fi

# ── 2. Push the secrets to GitHub ────────────────────────────────────────
echo "Setting secrets on $REPO ..."
KEYSTORE_BASE64="$(base64 -w0 "$KS_FILE")"

gh secret set KEYSTORE_BASE64 --repo "$REPO" --body "$KEYSTORE_BASE64"
gh secret set KEYSTORE_PASSWORD --repo "$REPO" --body "$KEYSTORE_PASSWORD"
gh secret set KEY_ALIAS --repo "$REPO" --body "$KEY_ALIAS"
gh secret set KEY_PASSWORD --repo "$REPO" --body "$KEY_PASSWORD"

echo
echo "Done. The next release build will be signed with $KS_FILE."
echo "Verify with: gh secret list --repo $REPO"
