import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theracare/core/widgets/app_buttons.dart';
import 'package:theracare/core/widgets/app_text_field.dart';
import 'package:theracare/core/widgets/choice_tile.dart';
import 'package:theracare/core/widgets/scale_selector.dart';
import 'package:theracare/core/widgets/status_message.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('primary button meets the touch target and survives 200% text', (tester) async {
    await pumpApp(tester, PrimaryButton(label: "Start today's exercise", onPressed: () {}), textScale: 2.0);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(FilledButton)).height, greaterThanOrEqualTo(60));
    expect(find.text("Start today's exercise"), findsOneWidget);
  });

  testWidgets('loading button cannot be pressed twice', (tester) async {
    var taps = 0;
    await pumpApp(tester, PrimaryButton(label: 'Save', loading: true, onPressed: () => taps++), settle: false);
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
  });

  testWidgets('text field keeps a visible label and announces its name', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, const AppTextField(label: 'Email address', errorText: 'Enter a valid email address.'));
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Email address')), findsWidgets);
    handle.dispose();
  });

  testWidgets('password field has a labelled reveal control', (tester) async {
    await pumpApp(tester, const AppTextField(label: 'Password', obscure: true));
    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });

  testWidgets('scale values are spoken as "n of max" and selection is not colour-only', (tester) async {
    final handle = tester.ensureSemantics();
    int? value;
    await pumpApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) => ScaleSelector(
          min: 0,
          max: 10,
          value: value,
          minLabel: 'No pain',
          maxLabel: 'Worst pain',
          onChanged: (v) => setState(() => value = v),
        ),
      ),
    );
    expect(find.bySemanticsLabel('5 of 10'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('5 of 10'));
    await tester.pump();
    expect(value, 5);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel('5 of 10')), isSemantics(isSelected: true));
    handle.dispose();
  });

  testWidgets('scale stays usable at large text sizes', (tester) async {
    await pumpApp(tester, ScaleSelector(min: 0, max: 10, value: 3, onChanged: (_) {}), textScale: 2.0);
    expect(tester.takeException(), isNull);
    for (var v = 0; v <= 10; v++) {
      expect(tester.getSize(find.text('$v')).height, greaterThan(0));
    }
  });

  testWidgets('choice tiles expose checked and selected states', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      Column(
        children: [
          ChoiceTile(label: 'Yes', selected: true, onTap: () {}),
          ChoiceTile(label: 'Remember me', multiple: true, selected: false, onTap: () {}),
        ],
      ),
    );
    expect(tester.getSemantics(find.bySemanticsLabel('Yes')), isSemantics(isSelected: true));
    expect(tester.getSemantics(find.bySemanticsLabel('Remember me')), isSemantics(isChecked: false));
    expect(tester.getSize(find.byType(ChoiceTile).first).height, greaterThanOrEqualTo(60));
    handle.dispose();
  });

  testWidgets('status messages show text and icon, not colour alone', (tester) async {
    await pumpApp(tester, const StatusMessage(kind: StatusKind.error, title: 'Not saved', text: 'Please try again.'));
    expect(find.text('Not saved'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
