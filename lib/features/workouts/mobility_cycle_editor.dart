import 'package:flutter/material.dart';
import 'package:the_forge/data/models/training.dart';
import 'gym_set_fields.dart';

Future<Exercise?> editMobilityCycles(
  BuildContext context,
  Exercise exercise,
  int cycles,
) => showDialog<Exercise>(
  context: context,
  builder: (_) => _CycleEditor(exercise: exercise, cycles: cycles),
);

class _CycleEditor extends StatefulWidget {
  const _CycleEditor({required this.exercise, required this.cycles});
  final Exercise exercise;
  final int cycles;
  @override
  State<_CycleEditor> createState() => _CycleEditorState();
}

class _CycleEditorState extends State<_CycleEditor> {
  late final _values = List.generate(
    widget.cycles,
    (i) => i < widget.exercise.workingSets.length
        ? widget.exercise.workingSets[i].copyWith(confirmed: true)
        : WorkingSet(
            amount: widget.exercise.reps,
            weightKg: 0,
            confirmed: true,
          ),
  );
  final _invalid = <int>{};
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('${widget.exercise.name} · cycle results'),
    content: SizedBox(
      width: 440,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the actual reps/seconds for each cycle. 0 means skipped. Applying records these values.',
            ),
            for (var i = 0; i < _values.length; i++) ...[
              Text('Cycle ${i + 1}'),
              GymSetFields(
                key: ValueKey(i),
                value: _values[i],
                unit: widget.exercise.unit,
                mode: null,
                bodyweight: null,
                index: i,
                mobility: true,
                confirmation: false,
                onChanged: (value) => setState(() {
                  if (value == null) {
                    _invalid.add(i);
                  } else {
                    _invalid.remove(i);
                    _values[i] = value;
                  }
                }),
              ),
            ],
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
                widget.exercise.copyWith(workingSets: _values),
              ),
        child: const Text('Apply'),
      ),
    ],
  );
}
