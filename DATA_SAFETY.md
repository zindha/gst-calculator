# Data Safety — Play Store Declaration

Use this information to fill out the **Data safety** section in Google Play Console.

---

## Does your app collect or share any user data?
**No.** The app does not collect, transmit, or share any user data.

## Data types collected
**None.**

The app stores all data locally on-device using Android SharedPreferences.
No data is sent to any server, analytics platform, or third-party service.

## Data sharing
**None.** The app does not share data with any third party.

## Data encryption
All data is stored locally in SharedPreferences, which is sandboxed by Android's application storage model.

## Data deletion
Users can delete their data at any time by tapping "Clear All Data" in the app's Settings screen. Uninstalling the app also removes all local data.

---

### Play Console form mapping

| Play Console field | Value |
|--------------------|-------|
| Data collected | None |
| Data shared | None |
| Data encrypted in transit | N/A (no data transmitted) |
| Data deletion request | User can delete within the app (Settings → Clear All Data) |
| Privacy policy URL | [YOUR_PRIVACY_POLICY_URL] |

Replace `[YOUR_PRIVACY_POLICY_URL]` with the URL where you host `PRIVACY_POLICY.md` (e.g., a GitHub Pages link or your own domain).
