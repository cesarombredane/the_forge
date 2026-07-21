import 'package:flutter/material.dart';
import 'package:the_forge/data/models/training.dart';

class WorkoutCompletion {
  const WorkoutCompletion({
    required this.durationMinutes,
    required this.comment,
    required this.exercises,
  });

  final int durationMinutes;
  final String comment;
  final List<Exercise> exercises;
}

class WorkoutCompletionDialog extends StatefulWidget {
  const WorkoutCompletionDialog({super.key, required this.workout});

  final Workout workout;

  @override
  State<WorkoutCompletionDialog> createState() =>
      _WorkoutCompletionDialogState();
}

class _WorkoutCompletionDialogState extends State<WorkoutCompletionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _duration;
  late final TextEditingController _comment;
  late List<Exercise> _exercises;

  @override
  void initState() {
    super.initState();
    _duration = TextEditingController(
      text: widget.workout.durationMinutes.toString(),
    );
    _comment = TextEditingController();
    _exercises = List.of(widget.workout.exercises);
  }

  @override
  void dispose() {
    _duration.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete workout'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _duration,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Actual duration',
                  suffixText: 'minutes',
                ),
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  return number == null || number <= 0
                      ? 'Enter a duration above 0'
                      : null;
                },
              ),
              if (_exercises.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Actual gym loads',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                for (var index = 0; index < _exercises.length; index++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_exercises[index].name),
                    subtitle: Text(_summary(_exercises[index])),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editExercise(index),
                  ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _comment,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Training comment',
                  alignLabelWithHint: true,
                ),
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
        FilledButton(onPressed: _submit, child: const Text('Complete')),
      ],
    );
  }

  Future<void> _editExercise(int index) async {
    final exercise = _exercises[index];
    final sets = TextEditingController(text: exercise.sets.toString());
    final reps = TextEditingController(text: exercise.reps.toString());
    final weight = TextEditingController(text: exercise.weightKg.toString());
    final key = GlobalKey<FormState>();
    final result = await showDialog<Exercise>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise.name),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _positiveField(sets, 'Sets')),
                  const SizedBox(width: 12),
                  Expanded(child: _positiveField(reps, 'Reps')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: weight,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Weight / additional weight',
                  suffixText: 'kg',
                ),
                validator: (value) {
                  final number = double.tryParse(value ?? '');
                  return number == null || number < 0
                      ? 'Enter 0 or more'
                      : null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!key.currentState!.validate()) return;
              Navigator.pop(
                context,
                exercise.copyWith(
                  sets: int.parse(sets.text),
                  reps: int.parse(reps.text),
                  weightKg: double.parse(weight.text),
                ),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    sets.dispose();
    reps.dispose();
    weight.dispose();
    if (result != null) setState(() => _exercises[index] = result);
  }

  Widget _positiveField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final number = int.tryParse(value ?? '');
        return number == null || number <= 0 ? 'Above 0' : null;
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      WorkoutCompletion(
        durationMinutes: int.parse(_duration.text),
        comment: _comment.text.trim(),
        exercises: _exercises,
      ),
    );
  }
}

String _summary(Exercise exercise) {
  final weight = exercise.weightKg == 0
      ? 'bodyweight'
      : '${exercise.weightKg.toStringAsFixed(1)} kg';
  return '${exercise.sets} × ${exercise.reps} · $weight';
}
