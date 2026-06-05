import 'package:flutter/material.dart';

/// Semantic UI colors. Neutrals follow [applyBrightness] from [MaterialApp.builder].
/// Brand/status colors stay constant in light and dark mode.
class AppColors {
  AppColors._();

  static Brightness _brightness = Brightness.light;

  /// Called from [MaterialApp.builder] whenever the theme changes.
  static void applyBrightness(Brightness brightness) {
    _brightness = brightness;
  }

  static bool get isDark => _brightness == Brightness.dark;

  // Primary - Deep Professional Blue (like LinkedIn/Stripe)
  static const Color primary = Color(0xFF0A66C2);
  static const Color primaryDark = Color(0xFF004182);
  static const Color primaryLight = Color(0xFFE7F3FF);

  // Secondary - Sophisticated Teal
  static const Color secondary = Color(0xFF0D9488);
  static const Color secondaryDark = Color(0xFF0F766E);
  static const Color secondaryLight = Color(0xFFCCFBF1);

  // Accent - Premium Gold
  static const Color accent = Color(0xFFD97706);

  // Status colors
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFD97706);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  // Light neutrals (private)
  static const Color _backgroundLight = Color(0xFFFAFBFC);
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _surfaceVariantLight = Color(0xFFF3F4F6);
  static const Color _textPrimaryLight = Color(0xFF0F172A);
  static const Color _textSecondaryLight = Color(0xFF475569);
  static const Color _textTertiaryLight = Color(0xFF94A3B8);
  static const Color _borderLight = Color(0xFFE2E8F0);
  static const Color _borderDarkLight = Color(0xFFCBD5E1);
  static const Color _dividerLight = Color(0xFFF1F5F9);

  // Dark neutrals (private)
  static const Color _backgroundDark = Color(0xFF0F172A);
  static const Color _surfaceDark = Color(0xFF1E293B);
  static const Color _surfaceVariantDark = Color(0xFF334155);
  static const Color _textPrimaryDark = Color(0xFFF8FAFC);
  static const Color _textSecondaryDark = Color(0xFFCBD5E1);
  static const Color _textTertiaryDark = Color(0xFF94A3B8);
  static const Color _borderDark = Color(0xFF334155);
  static const Color _borderDarkAlt = Color(0xFF475569);
  static const Color _dividerDark = Color(0xFF1E293B);

  // Semantic getters (use these in widgets)
  static Color get background =>
      isDark ? _backgroundDark : _backgroundLight;

  static Color get surface => isDark ? _surfaceDark : _surfaceLight;

  static Color get surfaceVariant =>
      isDark ? _surfaceVariantDark : _surfaceVariantLight;

  static Color get textPrimary =>
      isDark ? _textPrimaryDark : _textPrimaryLight;

  static Color get textSecondary =>
      isDark ? _textSecondaryDark : _textSecondaryLight;

  static Color get textTertiary =>
      isDark ? _textTertiaryDark : _textTertiaryLight;

  static Color get border => isDark ? _borderDark : _borderLight;

  static Color get borderDark => isDark ? _borderDarkAlt : _borderDarkLight;

  static Color get divider => isDark ? _dividerDark : _dividerLight;

  // Legacy names used in theme definitions
  static const Color darkBackground = _backgroundDark;
  static const Color darkSurface = _surfaceDark;
  static const Color darkBorder = _borderDark;
  static const Color darkTextPrimary = _textPrimaryDark;
  static const Color darkTextSecondary = _textSecondaryDark;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0A66C2), Color(0xFF004182)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
