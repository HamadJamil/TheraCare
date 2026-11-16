import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theracare/core/widgets/labeled_progress.dart';
import 'package:theracare/core/widgets/scale_selector.dart';
import 'package:theracare/core/widgets/settings_group.dart';
import 'package:theracare/core/widgets/stat_tile.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('progress is announced as text, the bar is decorative', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, const LabeledProgress(label: 'Question 2 of 7', value: 2 / 7));
    expect(find.bySemanticsLabel('Question 2 of 7'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('%')), findsNothing);
    handle.dispose();
  });

  testWidgets('stat tiles read as one phrase and stack at large text', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      const StatRow(
        children: [
          StatTile(value: '7', label: 'exercises', icon: Icons.fitness_center),
          StatTile(value: '3', label: 'active days', icon: Icons.calendar_today),
        ],
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('7, exercises'), findsOneWidget);
    final first = tester.getTopLeft(find.byType(StatTile).first);
    final second = tester.getTopLeft(find.byType(StatTile).last);
    expect(second.dy, greaterThan(first.dy));
    handle.dispose();
  });

  testWidgets('scale fits on one screen width and repeats the chosen value', (tester) async {
    await pumpApp(tester, ScaleSelector(min: 0, max: 10, value: 7, onChanged: (_) {}));
    expect(find.text('You chose 7 of 10.'), findsOneWidget);
    final zero = tester.getRect(find.text('0'));
    final five = tester.getRect(find.text('5'));
    expect(five.top, closeTo(zero.top, 1), reason: '0–5 share the first row');
    expect(tester.getSize(find.byType(InkWell).first).height, greaterThanOrEqualTo(56));
  });

  testWidgets('settings rows are large tap targets', (tester) async {
    var tapped = false;
    await pumpApp(
      tester,
      SettingsGroup(
        title: 'Settings',
        items: [SettingsItem(icon: Icons.person, title: 'Personal data', onTap: () => tapped = true)],
      ),
    );
    expect(tester.getSize(find.byType(InkWell)).height, greaterThanOrEqualTo(56));
    await tester.tap(find.text('Personal data'));
    expect(tapped, isTrue);
  });
}
