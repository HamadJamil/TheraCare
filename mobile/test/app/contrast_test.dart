import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theracare/app/theme/tokens.dart';

double _luminance(Color c) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final l1 = _luminance(a), l2 = _luminance(b);
  return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05);
}

void main() {
  group('WCAG 2.2 AA contrast of design tokens', () {
    final textPairs = {
      'text primary on background': (AppColors.textPrimary, AppColors.background),
      'text primary on surface': (AppColors.textPrimary, AppColors.surface),
      'text secondary on background': (AppColors.textSecondary, AppColors.background),
      'text secondary on surface': (AppColors.textSecondary, AppColors.surface),
      'white on primary': (Colors.white, AppColors.primary),
      'white on secondary': (Colors.white, AppColors.secondary),
      'primary on surface': (AppColors.primary, AppColors.surface),
      'error on surface': (AppColors.error, AppColors.surface),
      'success on surface': (AppColors.success, AppColors.surface),
      'warning on surface': (AppColors.warning, AppColors.surface),
      'white on error': (Colors.white, AppColors.error),
    };

    textPairs.forEach((name, pair) {
      test('$name is at least 4.5:1', () {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      });
    });

    test('control borders reach 3:1 against surfaces', () {
      expect(contrast(AppColors.border, AppColors.surface), greaterThanOrEqualTo(3));
      expect(contrast(AppColors.border, AppColors.background), greaterThanOrEqualTo(3));
      expect(contrast(AppColors.primary, AppColors.background), greaterThanOrEqualTo(3));
    });
  });
}
