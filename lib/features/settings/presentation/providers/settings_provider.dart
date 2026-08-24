import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../calculator/domain/entities/gst_calculation_type.dart';
import '../../../calculator/domain/entities/gst_transaction_type.dart';

// ── Keys ──────────────────────────────────────────────────────────────

class _PrefKeys {
  static const themeMode = 'theme_mode';
  static const defaultSlab = 'default_slab';
  static const defaultCalcType = 'default_calc_type';
  static const defaultTransType = 'default_trans_type';
  static const onboardingDone = 'onboarding_done';

  // NOTE: the legacy 'accent_color' pref is deliberately not read or written
  // anymore. The brand identity is fixed to the icon-derived palette, so any
  // previously saved accent is simply ignored (safe backward compatibility —
  // the stored value is inert and the app always uses the brand default).
}

// ── Model ─────────────────────────────────────────────────────────────

/// Application-wide settings with persistence.
class AppSettings {
  final ThemeMode themeMode;
  final double defaultSlab;
  final GstCalculationType defaultCalculationType;
  final GstTransactionType defaultTransactionType;
  final bool onboardingDone;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.defaultSlab = 18.0,
    this.defaultCalculationType = GstCalculationType.exclusive,
    this.defaultTransactionType = GstTransactionType.intraState,
    this.onboardingDone = false,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? defaultSlab,
    GstCalculationType? defaultCalculationType,
    GstTransactionType? defaultTransactionType,
    bool? onboardingDone,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      defaultSlab: defaultSlab ?? this.defaultSlab,
      defaultCalculationType:
          defaultCalculationType ?? this.defaultCalculationType,
      defaultTransactionType:
          defaultTransactionType ?? this.defaultTransactionType,
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────

/// Provider that holds the persisted application settings.
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Eagerly-loaded SharedPreferences instance, attached from main() before
/// runApp so the first build() can read saved settings synchronously — no
/// flash of defaults (theme, slab, modes) on startup. Null in widget tests,
/// which fall back to the async load path.
SharedPreferences? _prefsCache;

/// Attaches the [SharedPreferences] instance loaded in main() before runApp.
void attachSharedPreferences(SharedPreferences prefs) => _prefsCache = prefs;

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = _prefsCache;
    if (prefs != null) {
      // Synchronous first build: saved settings are visible on frame one.
      return _readFrom(prefs);
    }
    // No eager instance (e.g. widget tests): load asynchronously.
    _loadFromPrefs();
    return const AppSettings();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    state = _readFrom(prefs);
  }

  AppSettings _readFrom(SharedPreferences prefs) {
    final themeModeIndex = prefs.getInt(_PrefKeys.themeMode) ?? 0;
    final themeMode = ThemeMode.values[themeModeIndex.clamp(0, 2)];

    final slab = prefs.getDouble(_PrefKeys.defaultSlab) ?? 18.0;
    final calcTypeIndex = prefs.getInt(_PrefKeys.defaultCalcType) ?? 0;
    final transTypeIndex = prefs.getInt(_PrefKeys.defaultTransType) ?? 0;
    final onboardingDone = prefs.getBool(_PrefKeys.onboardingDone) ?? false;

    return AppSettings(
      themeMode: themeMode,
      defaultSlab: slab,
      defaultCalculationType:
          GstCalculationType.values[calcTypeIndex.clamp(0, 1)],
      defaultTransactionType:
          GstTransactionType.values[transTypeIndex.clamp(0, 1)],
      onboardingDone: onboardingDone,
    );
  }

  Future<void> _save(String key, Object value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  // ── Mutations ───────────────────────────────────────────────────────

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _save(_PrefKeys.themeMode, mode.index);
  }

  Future<void> setDefaultSlab(double slab) async {
    state = state.copyWith(defaultSlab: slab);
    await _save(_PrefKeys.defaultSlab, slab);
  }

  Future<void> setDefaultCalculationType(GstCalculationType type) async {
    state = state.copyWith(defaultCalculationType: type);
    await _save(_PrefKeys.defaultCalcType, type.index);
  }

  Future<void> setDefaultTransactionType(GstTransactionType type) async {
    state = state.copyWith(defaultTransactionType: type);
    await _save(_PrefKeys.defaultTransType, type.index);
  }

  Future<void> markOnboardingDone() async {
    state = state.copyWith(onboardingDone: true);
    await _save(_PrefKeys.onboardingDone, true);
  }
}
