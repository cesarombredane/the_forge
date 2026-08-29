import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/theme/app_colors.dart';

class StepsPage extends StatelessWidget {
  const StepsPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final today = _dateOnly(DateTime.now());
    final days = List.generate(
      7,
      (index) => today.subtract(Duration(days: 6 - index)),
    );
    final entriesByDay = {
      for (final entry in controller.stepEntries) _dateKey(entry.day): entry,
    };
    final values = [
      for (final day in days) entriesByDay[_dateKey(day)]?.steps ?? 0,
    ];
    final total = values.fold(0, (sum, steps) => sum + steps);
    final average = total / 7;
    final goal = controller.dailyStepGoal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _WeeklySummaryCard(
          total: total,
          average: average,
          dailyGoal: goal,
          values: values,
          days: days,
          onSetGoal: () => _setGoal(context),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Last 7 days',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Text(
              'Tap a day to update',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final day in days.reversed)
          _StepDayCard(
            day: day,
            steps: entriesByDay[_dateKey(day)]?.steps,
            onTap: () =>
                _editDay(context, day, entriesByDay[_dateKey(day)]?.steps),
          ),
      ],
    );
  }

  Future<void> _editDay(
    BuildContext context,
    DateTime day,
    int? currentSteps,
  ) async {
    final steps = await showDialog<int>(
      context: context,
      builder: (_) => _StepsEntryDialog(day: day, initialSteps: currentSteps),
    );
    if (steps != null && context.mounted) {
      await controller.saveSteps(day, steps);
    }
  }

  Future<void> _setGoal(BuildContext context) async {
    final goal = await showDialog<int>(
      context: context,
      builder: (_) => _StepGoalDialog(initialGoal: controller.dailyStepGoal),
    );
    if (goal != null && context.mounted) {
      await controller.saveDailyStepGoal(goal);
    }
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  const _WeeklySummaryCard({
    required this.total,
    required this.average,
    required this.dailyGoal,
    required this.values,
    required this.days,
    required this.onSetGoal,
  });

  final int total;
  final double average;
  final int? dailyGoal;
  final List<int> values;
  final List<DateTime> days;
  final VoidCallback onSetGoal;

  @override
  Widget build(BuildContext context) {
    final progress = dailyGoal == null ? 0.0 : average / dailyGoal!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.directions_walk,
                  size: 40,
                  color: AppColors.yellow,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '7-day average',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      Text(
                        '${_integer(average.round())} steps',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onSetGoal,
                  child: Text(dailyGoal == null ? 'Set goal' : 'Edit goal'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _MiniStepBars(values: values, days: days),
            const SizedBox(height: 16),
            if (dailyGoal == null)
              const Text('Set a daily objective to track your weekly average.')
            else ...[
              LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
              const SizedBox(height: 8),
              Text(
                '${_integer(total)} / ${_integer(dailyGoal! * 7)} weekly steps · '
                '${(progress * 100).round()}% of average goal',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStepBars extends StatelessWidget {
  const _MiniStepBars({required this.values, required this.days});

  final List<int> values;
  final List<DateTime> days;

  @override
  Widget build(BuildContext context) {
    final maximum = [
      ...values,
      1,
    ].reduce((first, second) => first > second ? first : second);
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < values.length; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: values[index] / maximum,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.yellow,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      index == values.length - 1
                          ? 'Today'
                          : _shortWeekday(days[index]),
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepDayCard extends StatelessWidget {
  const _StepDayCard({
    required this.day,
    required this.steps,
    required this.onTap,
  });

  final DateTime day;
  final int? steps;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.surfaceRaised,
          foregroundColor: AppColors.yellow,
          child: Text('${day.day}'),
        ),
        title: Text(_dayLabel(day)),
        subtitle: Text(_shortDate(day)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              steps == null ? 'Not entered' : '${_integer(steps!)} steps',
              style: TextStyle(
                color: steps == null
                    ? AppColors.textDisabled
                    : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StepsEntryDialog extends StatefulWidget {
  const _StepsEntryDialog({required this.day, this.initialSteps});

  final DateTime day;
  final int? initialSteps;

  @override
  State<_StepsEntryDialog> createState() => _StepsEntryDialogState();
}

class _StepsEntryDialogState extends State<_StepsEntryDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialSteps?.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Steps · ${_shortDate(widget.day)}'),
      content: Form(
        key: _key,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Step count',
            suffixText: 'steps',
          ),
          validator: _validateSteps,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(context, int.parse(_controller.text));
  }
}

class _StepGoalDialog extends StatefulWidget {
  const _StepGoalDialog({this.initialGoal});

  final int? initialGoal;

  @override
  State<_StepGoalDialog> createState() => _StepGoalDialogState();
}

class _StepGoalDialogState extends State<_StepGoalDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialGoal?.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daily step objective'),
      content: Form(
        key: _key,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily objective',
            suffixText: 'steps',
          ),
          validator: (value) {
            final number = int.tryParse(value ?? '');
            return number == null || number <= 0
                ? 'Enter an objective above 0'
                : null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    if (!_key.currentState!.validate()) return;
    Navigator.pop(context, int.parse(_controller.text));
  }
}

String? _validateSteps(String? value) {
  final number = int.tryParse(value ?? '');
  return number == null || number < 0 ? 'Enter 0 or more' : null;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dayLabel(DateTime value) {
  if (_dateKey(value) == _dateKey(DateTime.now())) return 'Today';
  return const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][value.weekday - 1];
}

String _shortWeekday(DateTime value) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value.weekday - 1];

String _integer(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(' ');
    buffer.write(digits[index]);
  }
  return buffer.toString();
}
