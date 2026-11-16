import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/theme/tokens.dart';
import '../../core/l10n/l10n.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/scale_selector.dart';
import 'questionnaire_models.dart';

/// Renders the right large, accessible control for each question type.
class QuestionInput extends StatelessWidget {
  const QuestionInput({super.key, required this.question, required this.value, required this.onChanged});

  final Question question;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = question;
    switch (q.type) {
      case 'NUMERIC':
        return ScaleSelector(min: q.min ?? 0, max: q.max ?? 10, value: value as int?, onChanged: onChanged);
      case 'LIKERT':
      case 'SINGLE_CHOICE':
        return Column(
          children: [
            for (final o in q.options)
              ChoiceTile(label: o.label, selected: value == o.value, onTap: () => onChanged(o.value)),
          ],
        );
      case 'MULTI_CHOICE':
        final selected = ((value as List?) ?? const []).toSet();
        return Column(
          children: [
            for (final o in q.options)
              ChoiceTile(
                label: o.label,
                multiple: true,
                selected: selected.contains(o.value),
                onTap: () => onChanged(
                  selected.contains(o.value) ? (selected..remove(o.value)).toList() : [...selected, o.value],
                ),
              ),
          ],
        );
      case 'YES_NO':
        return Column(
          children: [
            ChoiceTile(label: l10n.yes, selected: value == true, onTap: () => onChanged(true)),
            ChoiceTile(label: l10n.no, selected: value == false, onTap: () => onChanged(false)),
          ],
        );
      case 'DATE':
        final current = value is String ? DateTime.tryParse(value! as String) : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              current == null
                  ? l10n.noDateChosen
                  : DateFormat.yMMMMd(Localizations.localeOf(context).toString()).format(current),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(
              label: l10n.chooseDate,
              icon: Icons.calendar_today,
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: current ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  initialEntryMode: DatePickerEntryMode.input,
                );
                if (picked != null) onChanged(DateFormat('yyyy-MM-dd').format(picked));
              },
            ),
          ],
        );
      default:
        return _TextAnswer(
          label: l10n.yourAnswer,
          initial: value as String? ?? '',
          long: q.type == 'LONG_TEXT',
          onChanged: (v) => onChanged(v.trim().isEmpty ? null : v),
        );
    }
  }
}

class _TextAnswer extends StatefulWidget {
  const _TextAnswer({required this.label, required this.initial, required this.long, required this.onChanged});
  final String label;
  final String initial;
  final bool long;
  final ValueChanged<String> onChanged;

  @override
  State<_TextAnswer> createState() => _TextAnswerState();
}

class _TextAnswerState extends State<_TextAnswer> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppTextField(
    label: widget.label,
    controller: _controller,
    maxLines: widget.long ? 5 : 1,
    maxLength: widget.long ? 2000 : 200,
    onChanged: widget.onChanged,
  );
}

/// Human-readable answer for the review step.
String describeAnswer(BuildContext context, Question q, Object? value) {
  final l10n = context.l10n;
  if (!q.isAnswered(value)) return l10n.notAnswered;
  return switch (q.type) {
    'YES_NO' => value == true ? l10n.yes : l10n.no,
    'MULTI_CHOICE' => q.options.where((o) => (value! as List).contains(o.value)).map((o) => o.label).join(', '),
    'LIKERT' || 'SINGLE_CHOICE' =>
      q.options.firstWhere((o) => o.value == value, orElse: () => QuestionOption(value!, '$value')).label,
    'NUMERIC' => l10n.scaleValue(value! as int, q.max ?? 10),
    _ => '$value',
  };
}
