import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:the_forge/data/models/performance.dart';
import 'package:the_forge/features/workouts/gym_set_fields.dart';

class GymSessionPage extends StatefulWidget {
  const GymSessionPage({
    super.key,
    required this.controller,
    required this.workout,
  });
  final AppController controller;
  final Workout workout;
  @override
  State<GymSessionPage> createState() => _GymSessionPageState();
}

class _GymSessionPageState extends State<GymSessionPage> {
  bool get _mobility => widget.workout.sport == Sport.mobility;
  late Workout _workout = widget.workout;
  late final _duration = TextEditingController(
    text: '${_workout.durationMinutes}',
  );
  late final _comment = TextEditingController(text: _workout.comment);
  Future<void> _pending = Future.value();
  final _invalid = <String>{};
  String? _error;
  int _writes = 0;
  bool _leaving = false;
  bool _busy = false;
  @override
  void dispose() {
    _duration.dispose();
    _comment.dispose();
    super.dispose();
  }

  void _save() {
    final snapshot = _workout;
    setState(() {
      _writes++;
    });
    _pending = _pending.then((_) async {
      try {
        await _persist(snapshot);
        if (mounted) setState(() => _error = null);
      } catch (error) {
        if (mounted) setState(() => _error = 'Could not save: $error');
      } finally {
        if (mounted) setState(() => _writes--);
      }
    });
  }

  Future<void> _persist(Workout workout, {bool finish = false}) => _mobility
      ? widget.controller.saveMobility(workout, finish: finish)
      : widget.controller.saveGym(workout, finish: finish);

  Future<void> _cancel() async {
    if (_busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_mobility ? 'Cancel routine?' : 'Cancel workout?'),
        content: const Text(
          'Discard all progress, including previously saved progress? The session will stay scheduled and return to not started.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep training'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard progress'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    // Drain saves before restoring the snapshot; no queued save can undo the reset.
    await _pending;
    try {
      await widget.controller.cancelSession(_workout.id!);
      if (!mounted) return;
      setState(() => _leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = 'Could not cancel: $error';
        });
    }
  }

  Future<void> _exit({bool finish = false}) async {
    if (_busy) return;
    if (_invalid.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correct invalid fields before leaving.')),
      );
      return;
    }
    if (finish &&
        _workout.exercises.any((e) => e.workingSets.any((s) => !s.confirmed))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mobility
                ? 'Confirm each movement in every cycle. Enter 0 to skip.'
                : 'Confirm each set. Enter 0 for skipped sets.',
          ),
        ),
      );
      return;
    }
    setState(() => _busy = true);
    await _pending;
    if (!mounted) return;
    if (_error != null) {
      setState(() => _busy = false);
      return;
    }
    try {
      if (finish) await _persist(_workout, finish: true);
      if (mounted) {
        setState(() => _leaving = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (error) {
      if (mounted)
        setState(() {
          _error = '$error';
          _busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _leaving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _exit();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(_workout.title),
        actions: [
          TextButton(
            onPressed: _busy ? null : _cancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _writes > 0
                  ? 'Saving…'
                  : _error != null
                  ? 'Not saved'
                  : 'Saved on this device',
            ),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              TextButton(onPressed: _save, child: const Text('Retry saving')),
            ],
            if (_workout.bodyWeightKg != null)
              Text('Session bodyweight: ${_workout.bodyWeightKg} kg'),
            if (_workout.warmup.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Warm-up\n${_workout.warmup}'),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _mobility
                    ? 'Confirm each movement in each cycle. Enter 0 reps/seconds to skip. Movements and cycles stay fixed.'
                    : 'Working sets only. Check each completed set. Enter 0 reps/seconds to skip. Exercise and set counts stay fixed.',
              ),
            ),
            if (_mobility)
              for (var cycle = 0; cycle < _workout.cycleCount; cycle++)
                _cycle(cycle)
            else
              for (var i = 0; i < _workout.exercises.length; i++) _exercise(i),
            const SizedBox(height: 16),
            TextFormField(
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Actual duration',
                suffixText: 'minutes',
              ),
              onChanged: (value) {
                final duration = int.tryParse(value);
                if (duration == null || duration <= 0) {
                  setState(() => _invalid.add('duration'));
                  return;
                }
                _invalid.remove('duration');
                _workout = _workout.copyWith(durationMinutes: duration);
                _save();
              },
            ),
            if (_invalid.contains('duration'))
              const Text(
                'Enter a duration above 0.',
                style: TextStyle(color: Colors.redAccent),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _comment,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Training comment'),
              onChanged: (value) {
                _workout = _workout.copyWith(comment: value);
                _save();
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _exit(finish: true),
              icon: const Icon(Icons.check),
              label: Text(_mobility ? 'Finish routine' : 'Finish workout'),
            ),
            TextButton(
              onPressed: () => _exit(),
              child: const Text('Save and leave — resume later'),
            ),
            TextButton(
              onPressed: _cancel,
              child: Text(_mobility ? 'Cancel routine' : 'Cancel workout'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _cycle(int cycle) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cycle ${cycle + 1}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (var i = 0; i < _workout.exercises.length; i++) ...[
            Text(
              '${_workout.exercises[i].name}${_workout.exercises[i].perSide ? ' · per side' : ''}',
            ),
            GymSetFields(
              key: ValueKey('mobility:$i:$cycle'),
              value: _workout.exercises[i].workingSets[cycle],
              unit: _workout.exercises[i].unit,
              mode: null,
              bodyweight: null,
              index: i,
              mobility: true,
              onChanged: (value) {
                final key = '$i:$cycle';
                if (value == null) {
                  setState(() => _invalid.add(key));
                  return;
                }
                _invalid.remove(key);
                final exercise = _workout.exercises[i];
                final sets = List<WorkingSet>.of(exercise.workingSets)
                  ..[cycle] = value;
                final exercises = List<Exercise>.of(_workout.exercises)
                  ..[i] = exercise.copyWith(workingSets: sets);
                _workout = _workout.copyWith(exercises: exercises);
                _save();
              },
            ),
          ],
        ],
      ),
    ),
  );

  Widget _exercise(int index) {
    final exercise = _workout.exercises[index];
    final previous = previousGymWorkout(
      widget.controller.workouts,
      _workout,
      exercise,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(exercise.name, style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${exercise.unit.name}${exercise.perSide ? ' per side' : ''} · ${exercise.weightMode == WeightMode.bodyweight ? 'Bodyweight + adjustment' : 'External load'}',
            ),
            const SizedBox(height: 10),
            if (previous == null)
              const Text('No previous completed performance.')
            else ...[
              Text(
                'Last time · ${MaterialLocalizations.of(context).formatMediumDate(previous.scheduledAt)} · ${previous.title}',
              ),
              for (final entry in previous.exercises.where(
                (e) =>
                    e.libraryId == exercise.libraryId &&
                    e.unit == exercise.unit,
              ))
                Text(
                  entry.workingSets
                      .map(
                        (s) =>
                            '${s.weightKg} kg × ${s.amount} ${entry.unit.name}${s.amount == 0 ? ' (skipped)' : ''}',
                      )
                      .join(' / '),
                ),
              if (previous.bodyWeightKg != null &&
                  exercise.weightMode == WeightMode.bodyweight)
                Text('Previous bodyweight: ${previous.bodyWeightKg} kg'),
            ],
            const Divider(),
            const Text('Today'),
            for (var j = 0; j < exercise.workingSets.length; j++)
              GymSetFields(
                key: ValueKey('$index:$j'),
                value: exercise.workingSets[j],
                index: j,
                unit: exercise.unit,
                mode: exercise.weightMode,
                bodyweight: _workout.bodyWeightKg,
                onChanged: (value) {
                  final key = '$index:$j';
                  if (value == null) {
                    setState(() => _invalid.add(key));
                    return;
                  }
                  _invalid.remove(key);
                  final sets = List<WorkingSet>.of(
                    _workout.exercises[index].workingSets,
                  )..[j] = value;
                  final exercises = List<Exercise>.of(_workout.exercises)
                    ..[index] = exercise.copyWith(workingSets: sets);
                  _workout = _workout.copyWith(exercises: exercises);
                  _save();
                },
              ),
          ],
        ),
      ),
    );
  }
}
