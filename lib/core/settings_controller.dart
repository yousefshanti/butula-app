import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.isArabic = true,
  });

  final ThemeMode themeMode;
  final bool isArabic;

  AppSettings copyWith({ThemeMode? themeMode, bool? isArabic}) => AppSettings(
        themeMode: themeMode ?? this.themeMode,
        isArabic: isArabic ?? this.isArabic,
      );
}

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._prefs) : super(const AppSettings()) {
    _load();
  }
  final SharedPreferences _prefs;

  static const _kTheme = 'themeMode';
  static const _kArabic = 'isArabic';

  void _load() {
    final theme = _prefs.getString(_kTheme);
    final isArabic = _prefs.getBool(_kArabic) ?? true;
    state = AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == theme,
        orElse: () => ThemeMode.system,
      ),
      isArabic: isArabic,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(_kTheme, mode.name);
  }

  Future<void> setArabic(bool value) async {
    state = state.copyWith(isArabic: value);
    await _prefs.setBool(_kArabic, value);
  }
}

/// Overridden in main() once SharedPreferences is loaded.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider not initialized'),
);

final settingsProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController(ref.watch(sharedPrefsProvider));
});

/// The active bilingual strings, derived from the language setting.
final stringsProvider = Provider<AppStrings>((ref) {
  final isArabic = ref.watch(settingsProvider).isArabic;
  return isArabic ? arStrings : enStrings;
});
