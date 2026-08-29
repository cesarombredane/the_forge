import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:the_forge/theme/app_colors.dart';

enum _WeightRange {
  twoMonths('2 months', 62),
  sixMonths('6 months', 183),
  oneYear('1 year', 366);

  const _WeightRange(this.label, this.days);

  final String label;
  final int days;
}

class WeightPage extends StatefulWidget {
  const WeightPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  _WeightRange _range = _WeightRange.twoMonths;

  @override
  Widget build(BuildContext context) {
    final entries = widget.controller.weightEntries;
    final cutoff = DateTime.now().subtract(Duration(days: _range.days));
    final chartEntries = entries
        .where((entry) => !entry.recordedAt.isBefore(cutoff))
        .toList()
        .reversed
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _CurrentWeightCard(entry: entries.firstOrNull, onAdd: _addWeight),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Evolution',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    DropdownButton<_WeightRange>(
                      value: _range,
                      items: _WeightRange.values
                          .map(
                            (range) => DropdownMenuItem(
                              value: range,
                              child: Text(range.label),
                            ),
                          )
                          .toList(),
                      onChanged: (range) => setState(() => _range = range!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (chartEntries.isEmpty)
                  const SizedBox(
                    height: 180,
                    child: Center(
                      child: Text('Add a weigh-in to start your chart.'),
                    ),
                  )
                else
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _WeightChartPainter(entries: chartEntries),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ReminderCard(
          reminder: widget.controller.weightReminder,
          onEdit: _editReminder,
          onRemove: _removeReminder,
        ),
        const SizedBox(height: 20),
        Text('History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No weigh-ins recorded yet.'),
            ),
          )
        else
          for (final entry in entries)
            Card(
              child: ListTile(
                leading: const Icon(Icons.monitor_weight_outlined),
                title: Text('${_weight(entry.weightKg)} kg'),
                subtitle: Text(_dateTime(entry.recordedAt)),
                trailing: IconButton(
                  tooltip: 'Delete weigh-in',
                  onPressed: () => widget.controller.deleteWeight(entry),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _addWeight() async {
    final weight = await showWeightEntryDialog(
      context,
      initialWeight: widget.controller.weightEntries.firstOrNull?.weightKg,
    );
    if (weight != null && mounted) await widget.controller.addWeight(weight);
  }

  Future<void> _editReminder() async {
    final reminder = await showDialog<WeightReminder>(
      context: context,
      builder: (_) =>
          _WeightReminderDialog(reminder: widget.controller.weightReminder),
    );
    if (reminder != null && mounted) {
      await widget.controller.saveWeightReminder(reminder);
    }
  }

  Future<void> _removeReminder() async {
    await widget.controller.removeWeightReminder();
  }
}

class _CurrentWeightCard extends StatelessWidget {
  const _CurrentWeightCard({required this.entry, required this.onAdd});

  final WeightEntry? entry;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(
              Icons.monitor_weight_outlined,
              size: 44,
              color: AppColors.yellow,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current weight',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    entry == null ? '—' : '${_weight(entry!.weightKg)} kg',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (entry != null)
                    Text(
                      _dateTime(entry!.recordedAt),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
            FilledButton(onPressed: onAdd, child: const Text('Weigh in')),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.onEdit,
    required this.onRemove,
  });

  final WeightReminder? reminder;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_repeat, color: AppColors.yellow),
        title: const Text('Weekly weigh-in'),
        subtitle: Text(
          reminder == null
              ? 'No reminder scheduled'
              : '${_weekday(reminder!.weekday)} at ${_clock(reminder!.hour, reminder!.minute)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (reminder != null)
              IconButton(
                tooltip: 'Remove reminder',
                onPressed: onRemove,
                icon: const Icon(Icons.notifications_off_outlined),
              ),
            IconButton(
              tooltip: reminder == null ? 'Set reminder' : 'Edit reminder',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightReminderDialog extends StatefulWidget {
  const _WeightReminderDialog({this.reminder});

  final WeightReminder? reminder;

  @override
  State<_WeightReminderDialog> createState() => _WeightReminderDialogState();
}

class _WeightReminderDialogState extends State<_WeightReminderDialog> {
  late int _weekdayValue;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _weekdayValue = widget.reminder?.weekday ?? DateTime.saturday;
    _time = TimeOfDay(
      hour: widget.reminder?.hour ?? 8,
      minute: widget.reminder?.minute ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Weekly weigh-in'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _weekdayValue,
            decoration: const InputDecoration(labelText: 'Weekday'),
            items: List.generate(
              7,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text(_weekday(index + 1)),
              ),
            ),
            onChanged: (value) => setState(() => _weekdayValue = value!),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Time'),
            subtitle: Text(_time.format(context)),
            onTap: _pickTime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            WeightReminder(
              weekday: _weekdayValue,
              hour: _time.hour,
              minute: _time.minute,
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
    if (time != null) setState(() => _time = time);
  }
}

Future<double?> showWeightEntryDialog(
  BuildContext context, {
  double? initialWeight,
}) {
  return showDialog<double>(
    context: context,
    builder: (_) => _WeightEntryDialog(initialWeight: initialWeight),
  );
}

class _WeightEntryDialog extends StatefulWidget {
  const _WeightEntryDialog({this.initialWeight});

  final double? initialWeight;

  @override
  State<_WeightEntryDialog> createState() => _WeightEntryDialogState();
}

class _WeightEntryDialogState extends State<_WeightEntryDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialWeight == null ? '' : _weight(widget.initialWeight!),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record weight'),
      content: Form(
        key: _key,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Current weight',
            suffixText: 'kg',
          ),
          validator: (value) {
            final number = _parseWeight(value);
            return number == null || number <= 0
                ? 'Enter a weight above 0'
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
    Navigator.pop(context, _parseWeight(_controller.text));
  }
}

double? _parseWeight(String? value) =>
    double.tryParse((value ?? '').trim().replaceFirst(',', '.'));

class _WeightChartPainter extends CustomPainter {
  const _WeightChartPainter({required this.entries});

  final List<WeightEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 42.0;
    const top = 12.0;
    const right = 8.0;
    const bottom = 26.0;
    final area = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final weights = entries.map((entry) => entry.weightKg);
    final rawMin = weights.reduce(math.min);
    final rawMax = weights.reduce(math.max);
    final padding = math.max(1.0, (rawMax - rawMin) * 0.15);
    final minWeight = rawMin - padding;
    final maxWeight = rawMax + padding;
    final firstDate = entries.first.recordedAt;
    final lastDate = entries.last.recordedAt;
    final dateSpan = math.max(1, lastDate.difference(firstDate).inSeconds);

    final gridPaint = Paint()
      ..color = AppColors.surfaceRaised
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = area.top + area.height * index / 4;
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), gridPaint);
      final value = maxWeight - (maxWeight - minWeight) * index / 4;
      _paintText(canvas, _weight(value), Offset(0, y - 7));
    }

    Offset point(WeightEntry entry) {
      final x =
          area.left +
          area.width *
              entry.recordedAt.difference(firstDate).inSeconds /
              dateSpan;
      final y =
          area.bottom -
          area.height * (entry.weightKg - minWeight) / (maxWeight - minWeight);
      return Offset(x, y);
    }

    final path = Path();
    for (var index = 0; index < entries.length; index++) {
      final position = point(entries[index]);
      if (index == 0) {
        path.moveTo(position.dx, position.dy);
      } else {
        path.lineTo(position.dx, position.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.yellow
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    final dotPaint = Paint()..color = AppColors.yellowSoft;
    for (final entry in entries) {
      canvas.drawCircle(point(entry), 3.5, dotPaint);
    }
    _paintText(
      canvas,
      _shortDate(firstDate),
      Offset(area.left, area.bottom + 7),
    );
    final lastLabel = _shortDate(lastDate);
    _paintText(
      canvas,
      lastLabel,
      Offset(area.right, area.bottom + 7),
      alignRight: true,
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset, {
    bool alignRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(alignRight ? offset.dx - painter.width : offset.dx, offset.dy),
    );
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) =>
      oldDelegate.entries != entries;
}

String _weight(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

String _clock(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

String _dateTime(DateTime value) =>
    '${_shortDate(value)} at ${_clock(value.hour, value.minute)}';

String _weekday(int value) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][value - 1];
