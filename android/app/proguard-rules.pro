# ── Flutter & Dart ────────────────────────────────────────────────────
# Keep the Flutter engine entry points and generated plugin registrant.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**   { *; }
-keep class io.flutter.view.**   { *; }
-keep class io.flutter.**        { *; }
-keep class io.flutter.plugins.** { *; }

# ── Riverpod / flutter_riverpod ──────────────────────────────────────
# Provider annotations and generated code use reflection-like patterns.
-keep class com.gstcalculator.app.** { *; }
-keep class flutter_riverpod.** { *; }

# ── SharedPreferences ────────────────────────────────────────────────
# Uses JSON serialization under the hood.
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# ── Lucide icons ─────────────────────────────────────────────────────
# IconData constants are resolved via const constructors; R8 must not
# strip or obfuscate them.
-keep class lucide_icons_flutter.** { *; }

# ── intl / date formatting ───────────────────────────────────────────
-keep class io.flutter.plugins.intl.** { *; }

# ── share_plus ───────────────────────────────────────────────────────
-keep class io.flutter.plugins.shareplus.** { *; }

# ── Suppress warnings for missing annotations ───────────────────────
-dontwarn javax.annotation.**
