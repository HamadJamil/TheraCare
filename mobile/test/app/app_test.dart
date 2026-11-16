import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theracare/app/app.dart';
import 'package:theracare/core/providers/core_providers.dart';

import '../helpers/fakes.dart';

void main() {
  test('in-app text size multiplies the system scale without clamping', () {
    const scaler = ScaledTextScaler(TextScaler.linear(1.5), 1.6);
    expect(scaler.scale(18), closeTo(18 * 1.5 * 1.6, 0.001));
    expect(scaler, const ScaledTextScaler(TextScaler.linear(1.5), 1.6));
  });

  testWidgets('starts on the welcome screen when signed out', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...(await baseOverrides()).cast(),
            connectivityProvider.overrideWith((ref) => Stream.value(true)),
          ],
          child: const TheraCareApp(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text('Ihr Rücken, Schritt für Schritt'), findsOneWidget);
    expect(find.text('Konto erstellen'), findsOneWidget);
    expect(find.text('Hilfe'), findsOneWidget);
  });
}
