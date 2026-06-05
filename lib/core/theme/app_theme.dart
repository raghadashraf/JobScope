import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppTheme {
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -1,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor,
        height: 1.4,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.5,
      ),
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBg,
    required Color surface,
    required Color surfaceVariant,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color border,
    required Color divider,
  }) {
    final onSurface = textPrimary;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: _buildTextTheme(textPrimary),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          side: BorderSide(color: border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMD,
          vertical: 14,
        ),
        hintStyle: GoogleFonts.inter(
          color: textTertiary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLG),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: GoogleFonts.inter(color: textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      iconTheme: IconThemeData(color: textSecondary),
    );
  }

  static final ThemeData lightTheme = _buildTheme(
    brightness: Brightness.light,
    scaffoldBg: const Color(0xFFFAFBFC),
    surface: const Color(0xFFFFFFFF),
    surfaceVariant: const Color(0xFFF3F4F6),
    textPrimary: const Color(0xFF0F172A),
    textSecondary: const Color(0xFF475569),
    textTertiary: const Color(0xFF94A3B8),
    border: const Color(0xFFE2E8F0),
    divider: const Color(0xFFF1F5F9),
  );

  static final ThemeData darkTheme = _buildTheme(
    brightness: Brightness.dark,
    scaffoldBg: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceVariant: const Color(0xFF334155),
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    textTertiary: const Color(0xFF94A3B8),
    border: AppColors.darkBorder,
    divider: const Color(0xFF1E293B),
  );
}
