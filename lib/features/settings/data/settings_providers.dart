import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyThemeMode = 'settings_theme_mode';
const _keyNotificationsEnabled = 'settings_notifications_enabled';

class AppSettings {
  final ThemeMode themeMode;
  final bool notificationsEnabled;

  const AppSettings({
    this.themeMode = ThemeMode.light,
    this.notificationsEnabled = true,
  });

  bool get isDarkMode => themeMode == ThemeMode.dark;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        notificationsEnabled:
            notificationsEnabled ?? this.notificationsEnabled,
      );
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyThemeMode);
    final notificationsEnabled = prefs.getBool(_keyNotificationsEnabled);
    return AppSettings(
      themeMode: themeModeFromPrefsIndex(themeIndex),
      notificationsEnabled: notificationsEnabled ?? true,
    );
  }

  Future<void> setDarkMode(bool enabled) async {
    final mode = enabled ? ThemeMode.dark : ThemeMode.light;
    await _persistTheme(mode);
    _updateState((s) => s.copyWith(themeMode: mode));
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
    _updateState((s) => s.copyWith(notificationsEnabled: enabled));
  }

  Future<void> _persistTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  void _updateState(AppSettings Function(AppSettings current) fn) {
    final current = state.value ?? const AppSettings();
    state = AsyncValue.data(fn(current));
  }

}

ThemeMode themeModeFromPrefsIndex(int? index) {
  if (index == null) return ThemeMode.light;
  if (index < 0 || index >= ThemeMode.values.length) return ThemeMode.light;
  return ThemeMode.values[index];
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(
    settingsProvider.select(
      (async) => async.value?.themeMode ?? ThemeMode.light,
    ),
  );
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).value?.notificationsEnabled ?? true;
});

/// SharedPreferences keys + theme index mapping (for tests).
abstract final class SettingsStorage {
  static const themeKey = _keyThemeMode;
  static const notificationsKey = _keyNotificationsEnabled;

  static ThemeMode themeFromPrefsIndex(int? index) =>
      themeModeFromPrefsIndex(index);
}
