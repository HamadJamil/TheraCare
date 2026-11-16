import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theracare/app/theme/app_theme.dart';
import 'package:theracare/core/l10n/l10n.dart';

/// Pumps a widget inside the app theme and localizations, optionally with a
/// large system text scale to check that nothing essential is clipped.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  double textScale = 1.0,
  Locale locale = const Locale('en'),
  List<Object> overrides = const [],
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale), size: const Size(360, 800)),
          child: Scaffold(
            body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: child),
          ),
        ),
      ),
    ),
  );
  settle ? await tester.pumpAndSettle() : await tester.pump();
}
