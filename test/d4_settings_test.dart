import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobscope/core/constants/app_colors.dart';
import 'package:jobscope/features/settings/data/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('D4 — settings storage', () {
    test('themeModeFromPrefsIndex defaults to light', () {
      expect(themeModeFromPrefsIndex(null), ThemeMode.light);
      expect(themeModeFromPrefsIndex(99), ThemeMode.light);
    });

    test('themeModeFromPrefsIndex round-trips ThemeMode.dark', () {
      expect(
        themeModeFromPrefsIndex(ThemeMode.dark.index),
        ThemeMode.dark,
      );
    });

    test('SettingsStorage keys are stable', () {
      expect(SettingsStorage.themeKey, 'settings_theme_mode');
      expect(
        SettingsStorage.notificationsKey,
        'settings_notifications_enabled',
      );
    });

    test('AppSettings copyWith updates flags', () {
      const s = AppSettings();
      final dark = s.copyWith(themeMode: ThemeMode.dark);
      expect(dark.isDarkMode, isTrue);
      final quiet = dark.copyWith(notificationsEnabled: false);
      expect(quiet.notificationsEnabled, isFalse);
    });
  });

  group('D4 — SharedPreferences persistence', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      await container.read(settingsProvider.future);
    });

    tearDown(() {
      container.dispose();
    });

    test('setDarkMode writes theme index and updates themeModeProvider', () async {
      await container.read(settingsProvider.notifier).setDarkMode(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(SettingsStorage.themeKey), ThemeMode.dark.index);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      expect(container.read(settingsProvider).value!.isDarkMode, isTrue);
    });

    test('setDarkMode off restores light mode', () async {
      await container.read(settingsProvider.notifier).setDarkMode(true);
      await container.read(settingsProvider.notifier).setDarkMode(false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(SettingsStorage.themeKey), ThemeMode.light.index);
      expect(container.read(themeModeProvider), ThemeMode.light);
    });

    test('loads dark mode from existing prefs (TC-D4 step 3)', () async {
      SharedPreferences.setMockInitialValues({
        SettingsStorage.themeKey: ThemeMode.dark.index,
      });
      final fresh = ProviderContainer();
      addTearDown(fresh.dispose);

      final settings = await fresh.read(settingsProvider.future);
      expect(settings.themeMode, ThemeMode.dark);
      expect(fresh.read(themeModeProvider), ThemeMode.dark);
    });

    test('setNotificationsEnabled persists (TC-D4 step 5)', () async {
      await container
          .read(settingsProvider.notifier)
          .setNotificationsEnabled(false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SettingsStorage.notificationsKey), isFalse);
      expect(
        container.read(notificationsEnabledProvider),
        isFalse,
      );
    });
  });

  group('D4 — AppColors dark mode sync', () {
    test('semantic colors switch with applyBrightness', () {
      AppColors.applyBrightness(Brightness.light);
      expect(AppColors.isDark, isFalse);

      AppColors.applyBrightness(Brightness.dark);
      expect(AppColors.isDark, isTrue);
      expect(AppColors.background, const Color(0xFF0F172A));
      expect(AppColors.surface, const Color(0xFF1E293B));
      expect(AppColors.textPrimary, const Color(0xFFF8FAFC));

      AppColors.applyBrightness(Brightness.light);
      expect(AppColors.background, const Color(0xFFFAFBFC));
    });
  });
}
