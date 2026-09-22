import 'package:flutter/material.dart';
import 'package:the_forge/data/models/training.dart';

class GymSetFields extends StatefulWidget {
  const GymSetFields({
    super.key,
    required this.value,
    required this.unit,
    required this.mode,
    required this.bodyweight,
    required this.index,
    required this.onChanged,
    this.confirmation = true,
    this.mobility = false,
  });
  final WorkingSet value;
  final ExerciseUnit unit;
  final WeightMode? mode;
  final double? bodyweight;
  final int index;
  final bool confirmation;
  final bool mobility;
  final ValueChanged<WorkingSet?> onChanged;
  @override
  State<GymSetFields> createState() => _GymSetFieldsState();
}

class _GymSetFieldsState extends State<GymSetFields> {
  late final _amount = TextEditingController(text: '${widget.value.amount}');
  late final _weight = TextEditingController(text: '${widget.value.weightKg}');
  late bool _confirmed = widget.value.confirmed;
  String? _error;
  @override
  void dispose() {
    _amount.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GymSetFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bodyweight != widget.bodyweight ||
        oldWidget.mode != widget.mode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _change();
      });
    }
  }

  void _change() {
    final amount = int.tryParse(_amount.text);
    final weight = double.tryParse(_weight.text.replaceAll(',', '.'));
    String? error;
    if (amount == null || amount < 0)
      error = 'Enter reps/seconds of 0 or more.';
    if (weight == null || !weight.isFinite) error = 'Enter a valid weight.';
    if (weight != null && widget.mode == WeightMode.external && weight < 0)
      error = 'External load must be 0 or more.';
    if (weight != null &&
        widget.mode == WeightMode.bodyweight &&
        widget.bodyweight != null &&
        widget.bodyweight! + weight < 0)
      error = 'Assistance exceeds bodyweight.';
    setState(() {
      _error = error;
      if (amount == 0) _confirmed = true;
    });
    widget.onChanged(
      error == null
          ? WorkingSet(
              amount: amount!,
              weightKg: weight!,
              confirmed: widget.confirmation ? _confirmed : true,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(width: 30, child: Text('${widget.index + 1}')),
            if (!widget.mobility)
              Expanded(
                child: TextFormField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.mode == WeightMode.bodyweight
                        ? 'Adjustment kg'
                        : 'Weight kg',
                  ),
                  onChanged: (_) => _change(),
                ),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.unit == ExerciseUnit.reps
                      ? 'Reps'
                      : 'Seconds',
                ),
                onChanged: (_) => _change(),
              ),
            ),
            if (widget.confirmation)
              Checkbox(
                value: _confirmed,
                onChanged: (v) {
                  _confirmed = v!;
                  _change();
                },
              ),
          ],
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
      ],
    ),
  );
}

Future<Exercise?> editGymWorkingSets(
  BuildContext context,
  Exercise exercise,
  double? bodyweight,
) => showDialog<Exercise>(
  context: context,
  builder: (_) => _SetsDialog(exercise: exercise, bodyweight: bodyweight),
);

class _SetsDialog extends StatefulWidget {
  const _SetsDialog({required this.exercise, required this.bodyweight});
  final Exercise exercise;
  final double? bodyweight;
  @override
  State<_SetsDialog> createState() => _SetsDialogState();
}

class _SetsDialogState extends State<_SetsDialog> {
  late final _sets = widget.exercise.prescribedSets
      .map((s) => s.copyWith(confirmed: true))
      .toList();
  final _invalid = <int>{};
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.exercise.name),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Working sets only. 0 reps/seconds means skipped.'),
            for (var i = 0; i < _sets.length; i++)
              GymSetFields(
                key: ValueKey(i),
                value: _sets[i],
                unit: widget.exercise.unit,
                mode: widget.exercise.weightMode,
                bodyweight: widget.bodyweight,
                index: i,
                confirmation: false,
                onChanged: (value) {
                  setState(() {
                    if (value == null) {
                      _invalid.add(i);
                    } else {
                      _invalid.remove(i);
                      _sets[i] = value;
                    }
                  });
                },
              ),
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      setState(() => _sets.add(_sets.last.copyWith())),
                  child: const Text('Add set'),
                ),
                TextButton(
                  onPressed: _sets.length <= 1
                      ? null
                      : () => setState(() {
                          _invalid.remove(_sets.length - 1);
                          _sets.removeLast();
                        }),
                  child: const Text('Remove last set'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _invalid.isNotEmpty
            ? null
            : () => Navigator.pop(
                context,
                widget.exercise.copyWith(
                  sets: _sets.length,
                  workingSets: List.of(_sets),
                ),
              ),
        child: const Text('Apply'),
      ),
    ],
  );
}
