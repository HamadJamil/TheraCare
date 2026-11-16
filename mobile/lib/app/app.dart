import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/l10n.dart';
import '../core/providers/core_providers.dart';
import '../features/preferences/preferences.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class TheraCareApp extends ConsumerWidget {
  const TheraCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider).value ?? const Preferences();
    final localeCode = ref.watch(localeCodeProvider);
    final theme = AppTheme.light(highContrast: prefs.highContrast);

    return MaterialApp.router(
      title: 'TheraCare',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      locale: Locale(localeCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: prefs.reducedMotion ? theme.copyWith(pageTransitionsTheme: _noTransitions) : theme,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          // The in-app text size multiplies the system setting — never clamps it.
          data: media.copyWith(
            textScaler: ScaledTextScaler(media.textScaler, prefs.textScale),
            disableAnimations: media.disableAnimations || prefs.reducedMotion,
          ),
          child: child!,
        );
      },
    );
  }

  static const _noTransitions = PageTransitionsTheme(
    builders: {TargetPlatform.android: _NoTransitionBuilder(), TargetPlatform.iOS: _NoTransitionBuilder()},
  );
}

class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> a,
    Animation<double> b,
    Widget child,
  ) => child;
}

/// Applies the user's in-app factor on top of the (possibly non-linear) system scaler.
class ScaledTextScaler extends TextScaler {
  const ScaledTextScaler(this.base, this.factor);
  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) => other is ScaledTextScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}

/// Ensures `flutter_localizations` delegates stay referenced for Material widgets.
const materialDelegates = GlobalMaterialLocalizations.delegate;
