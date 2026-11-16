import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the app theme. Text sizes are base sizes — the system text scale is
/// always applied on top and never clamped.
abstract final class AppTheme {
  static const _font = 'AtkinsonHyperlegible';

  static TextTheme _text(Color body, Color heading) => TextTheme(
    displayLarge: TextStyle(fontSize: 36, height: 1.25, fontWeight: FontWeight.w700, color: heading),
    headlineLarge: TextStyle(fontSize: 30, height: 1.3, fontWeight: FontWeight.w700, color: heading),
    headlineMedium: TextStyle(fontSize: 26, height: 1.3, fontWeight: FontWeight.w700, color: heading),
    headlineSmall: TextStyle(fontSize: 22, height: 1.35, fontWeight: FontWeight.w700, color: heading),
    titleLarge: TextStyle(fontSize: 22, height: 1.35, fontWeight: FontWeight.w700, color: heading),
    titleMedium: TextStyle(fontSize: 20, height: 1.4, fontWeight: FontWeight.w700, color: body),
    bodyLarge: TextStyle(fontSize: 20, height: 1.5, color: body),
    bodyMedium: TextStyle(fontSize: 18, height: 1.5, color: body),
    bodySmall: TextStyle(fontSize: 16, height: 1.5, color: body),
    labelLarge: const TextStyle(fontSize: 18, height: 1.3, fontWeight: FontWeight.w700),
    labelMedium: TextStyle(fontSize: 16, height: 1.4, color: body),
  );

  static ThemeData light({bool highContrast = false}) {
    final primary = highContrast ? AppColors.hcPrimary : AppColors.primary;
    final text = highContrast ? AppColors.hcText : AppColors.textPrimary;
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: text,
      onSurfaceVariant: highContrast ? AppColors.hcText : AppColors.textSecondary,
      error: AppColors.error,
      onError: Colors.white,
      outline: highContrast ? AppColors.hcText : AppColors.border,
    );
    final borderWidth = highContrast ? 2.0 : 1.5;
    OutlineInputBorder border(Color color, [double? width]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width ?? borderWidth),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _font,
      colorScheme: scheme,
      scaffoldBackgroundColor: highContrast ? Colors.white : AppColors.background,
      textTheme: _text(text, primary),
      appBarTheme: AppBarTheme(
        backgroundColor: highContrast ? Colors.white : AppColors.background,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w700, color: primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.primaryButton),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.secondaryButton),
          foregroundColor: primary,
          backgroundColor: AppColors.surface,
          side: BorderSide(color: primary, width: borderWidth),
          textStyle: const TextStyle(fontFamily: _font, fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSizes.minTouch, AppSizes.minTouch),
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontFamily: _font,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 18),
        border: border(AppColors.border),
        enabledBorder: border(highContrast ? AppColors.hcText : AppColors.border),
        focusedBorder: border(primary, 3),
        errorBorder: border(AppColors.error, 2),
        focusedErrorBorder: border(AppColors.error, 3),
        errorStyle: const TextStyle(fontSize: 16, color: AppColors.error),
        errorMaxLines: 4,
        helperMaxLines: 4,
        helperStyle: TextStyle(fontSize: 16, color: highContrast ? AppColors.hcText : AppColors.textSecondary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: highContrast ? AppColors.hcText : const Color(0xFFD5DEE5),
            width: highContrast ? 2 : 1,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: _font,
            fontSize: 15,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400,
            color: primary,
          ),
        ),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: primary, size: 28)),
      ),
      radioTheme: RadioThemeData(fillColor: WidgetStatePropertyAll(primary)),
      checkboxTheme: CheckboxThemeData(
        side: BorderSide(color: primary, width: 2),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      switchTheme: const SwitchThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
      dividerTheme: const DividerThemeData(color: Color(0xFFD5DEE5), thickness: 1),
      focusColor: primary.withValues(alpha: 0.2),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
