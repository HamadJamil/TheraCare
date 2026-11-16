import 'package:flutter/material.dart';

/// Colour tokens from the TheraCare design language. Every text pair is
/// checked for at least 4.5:1 contrast in `test/app/theme/contrast_test.dart`.
abstract final class AppColors {
  static const primary = Color(0xFF174A68);
  static const secondary = Color(0xFF287B78);
  static const background = Color(0xFFF5F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF263746);
  static const textSecondary = Color(0xFF526575);
  static const success = Color(0xFF24734A);
  static const warning = Color(0xFF95600C);
  static const error = Color(0xFFB4232F);
  // Control boundaries need at least 3:1 against surface and background.
  static const border = Color(0xFF6F808E);

  // High-contrast variant (user preference).
  static const hcText = Color(0xFF000000);
  static const hcPrimary = Color(0xFF0B2C40);
}

abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;

  /// Horizontal page padding on phones.
  static const page = 24.0;
}

/// Generous touch targets (logical pixels).
abstract final class AppSizes {
  static const primaryButton = 60.0;
  static const secondaryButton = 54.0;
  static const minTouch = 48.0;
  static const navItem = 56.0;
  static const input = 60.0;
}
