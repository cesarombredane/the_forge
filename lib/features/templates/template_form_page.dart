import 'package:the_forge/features/workouts/mobility_cycle_editor.dart';
import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/features/exercises/exercises_page.dart';
import 'package:the_forge/features/workouts/gym_set_fields.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:the_forge/features/workouts/running_comparison.dart';

class TemplateFormPage extends StatefulWidget {
  const TemplateFormPage({super.key, required this.controller, this.template})
    : workout = null;

  const TemplateFormPage.workout({
    super.key,
    required this.controller,
    required Workout this.workout,
  }) : template = null;

  final AppController controller;
  final WorkoutTemplate? template;
  final Workout? workout;

  @override
  State<TemplateFormPage> createState() => _TemplateFormPageState();
}

class _TemplateFormPageState extends State<TemplateFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _duration;
  late final TextEditingController _description;
  late final TextEditingController _warmup;
  late final TextEditingController _distance;
  late final TextEditingController _sportDetails;
  late final TextEditingController _cycles;
  late Sport _sport;
  HockeySessionType _hockeyType = HockeySessionType.training;
  late List<Exercise> _exercises;
  late final TextEditingController _comment;
  DateTime? _scheduledAt;
  late final TextEditingController _bodyweight;

  @override
  void initState() {
    super.initState();
    final workout = widget.workout;
    _bodyweight = TextEditingController(
      text: workout?.bodyWeightKg?.toString() ?? '',
    );
    final template =
        widget.template ??
        (workout == null
            ? null
            : WorkoutTemplate(
                title: workout.title,
                sport: workout.sport,
                durationMinutes: workout.durationMinutes,
                description: workout.description,
                warmup: workout.warmup,
                hockeyType: workout.hockeyType,
                distanceKm: workout.distanceKm,
                sportDetails: workout.sportDetails,
                exercises: workout.exercises,
                cycleCount: workout.cycleCount,
              ));
    _comment = TextEditingController(text: workout?.comment ?? '');
    _scheduledAt = workout?.scheduledAt;
    _title = TextEditingController(text: template?.title ?? '');
    _duration = TextEditingController(
      text: template?.durationMinutes.toString() ?? '60',
    );
    _description = TextEditingController(text: template?.description ?? '');
    _warmup = TextEditingController(text: template?.warmup ?? '');
    _distance = TextEditingController(
      text: template?.distanceKm?.toString() ?? '',
    );
    _sportDetails = TextEditingController(text: template?.sportDetails ?? '');
    _cycles = TextEditingController(
      text: template?.cycleCount.toString() ?? '1',
    );
    _sport = template?.sport ?? Sport.gym;
    _hockeyType = template?.hockeyType ?? HockeySessionType.training;
    _exercises = List.of(template?.exercises ?? const []);
  }

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _description.dispose();
    _warmup.dispose();
    _distance.dispose();
    _sportDetails.dispose();
    _cycles.dispose();
    _comment.dispose();
    _bodyweight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.workout != null
              ? 'Edit workout'
              : widget.template == null
              ? 'New template'
              : 'Edit template',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_scheduledAt != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Training date and time'),
                  subtitle: Text(
                    '${MaterialLocalizations.of(context).formatMediumDate(_scheduledAt!)} · ${TimeOfDay.fromDateTime(_scheduledAt!).format(context)}',
                  ),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickTrainingDate,
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<Sport>(
                initialValue: _sport,
                decoration: const InputDecoration(labelText: 'Sport'),
                items: Sport.values
                    .map(
                      (sport) => DropdownMenuItem(
                        value: sport,
                        child: Text(sport.label),
                      ),
                    )
                    .toList(),
                onChanged: (sport) => setState(() {
                  final previousSport = _sport;
                  _sport = sport!;
                  if (previousSport != _sport &&
                      (previousSport == Sport.gym ||
                          previousSport == Sport.mobility ||
                          _sport == Sport.gym ||
                          _sport == Sport.mobility)) {
                    _exercises.clear();
                  }
                }),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                autofocus: widget.template == null && widget.workout == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: widget.workout == null
                      ? 'Template name'
                      : 'Workout name',
                  hintText: 'Leg day, Sunday run…',
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _duration,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  if (_sport == Sport.running) setState(() {});
                },
                decoration: InputDecoration(
                  labelText: widget.workout != null && _sport == Sport.running
                      ? 'Actual duration'
                      : 'Duration',
                  suffixText: 'minutes',
                ),
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  return number == null || number <= 0
                      ? 'Enter a duration above 0'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
              if (_sport != Sport.mobility && _sport != Sport.running) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _warmup,
                  minLines: 2,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Warm-up instructions',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ..._sportFields(),
              if (widget.workout != null && _sport == Sport.gym) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bodyweight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Session bodyweight',
                    suffixText: 'kg',
                    helperText: 'Historical snapshot, not a new weigh-in',
                  ),
                  validator: (v) =>
                      (v ?? '').isEmpty &&
                          !_exercises.any(
                            (e) => e.weightMode == WeightMode.bodyweight,
                          )
                      ? null
                      : _positiveDouble(v),
                ),
              ],
              if (widget.workout != null) ...[
                const SizedBox(height: 24),
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
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  widget.workout == null ? 'Save template' : 'Save workout',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _sportFields() {
    return switch (_sport) {
      Sport.gym => _exerciseFields(mobility: false),
      Sport.mobility => [
        TextFormField(
          controller: _cycles,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Number of cycles'),
          validator: _positiveInt,
        ),
        const SizedBox(height: 16),
        ..._exerciseFields(mobility: true),
      ],
      Sport.hockey => [
        DropdownButtonFormField<HockeySessionType>(
          initialValue: _hockeyType,
          decoration: const InputDecoration(labelText: 'Session type'),
          items: HockeySessionType.values
              .map(
                (type) =>
                    DropdownMenuItem(value: type, child: Text(type.label)),
              )
              .toList(),
          onChanged: (type) => setState(() => _hockeyType = type!),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _sportDetails,
          decoration: const InputDecoration(
            labelText: 'Position or session details',
          ),
        ),
      ],
      Sport.running => _runningFields(),
    };
  }

  List<Widget> _exerciseFields({required bool mobility}) => [
    Row(
      children: [
        Expanded(
          child: Text(
            mobility ? 'Cycle movements' : 'Exercises',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        TextButton.icon(
          onPressed: () => _editExercise(mobility: mobility),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
        ),
      ],
    ),
    if (_exercises.isEmpty)
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('No movements yet. Add the first movement.'),
      ),
    if (_exercises.isNotEmpty)
      ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _exercises.length,
        onReorderItem: _reorderExercise,
        itemBuilder: (context, index) {
          final exercise = _exercises[index];
          return Card(
            key: ObjectKey(exercise),
            child: ListTile(
              leading: ReorderableDragStartListener(
                index: index,
                child: const Tooltip(
                  message: 'Drag to reorder',
                  child: Icon(Icons.drag_handle),
                ),
              ),
              title: Text(exercise.name),
              subtitle: Text(_exerciseSummary(exercise, mobility: mobility)),
              onTap: () => _editExercise(index: index, mobility: mobility),
              trailing: IconButton(
                tooltip: 'Remove exercise',
                onPressed: () => setState(() => _exercises.removeAt(index)),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          );
        },
      ),
  ];

  List<Widget> _runningFields() => [
    TextFormField(
      controller: _distance,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: widget.workout == null ? 'Distance' : 'Actual distance',
        suffixText: 'km',
      ),
      validator: _positiveDouble,
    ),
    const SizedBox(height: 16),
    if (widget.workout != null)
      RunningComparison(
        targetMinutes: widget.workout!.targetDurationMinutes,
        targetDistanceKm: widget.workout!.targetDistanceKm,
        actualMinutes: int.tryParse(_duration.text),
        actualDistanceKm: double.tryParse(_distance.text.replaceAll(',', '.')),
      )
    else
      InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Target pace',
          suffixText: 'min/km',
        ),
        child: Text(
          _runningPace() ?? 'Enter a valid duration and distance',
          style: TextStyle(color: _runningPace() == null ? Colors.grey : null),
        ),
      ),
  ];

  Future<void> _editExercise({int? index, required bool mobility}) async {
    FocusScope.of(context).unfocus();
    Exercise? initial = index == null ? null : _exercises[index];
    if (mobility && widget.workout != null && initial != null) {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Edit cycle results'),
                onTap: () => Navigator.pop(context, 'cycles'),
              ),
              ListTile(
                title: const Text('Edit movement details'),
                onTap: () => Navigator.pop(context, 'details'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || action == null) return;
      if (action == 'cycles') {
        final cycles = int.tryParse(_cycles.text);
        if (cycles == null || cycles <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enter a positive number of cycles first.'),
            ),
          );
          return;
        }
        final result = await editMobilityCycles(context, initial, cycles);
        if (mounted && result != null)
          setState(() => _exercises[index!] = result);
        return;
      }
    }
    LibraryExercise? library;
    if (!mobility) {
      library = widget.controller.exerciseLibrary
          .where((e) => e.id == initial?.libraryId)
          .firstOrNull;
      if (widget.workout != null && initial != null && library != null) {
        final action = await showModalBottomSheet<String>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Edit working sets'),
                  onTap: () => Navigator.pop(context, 'sets'),
                ),
                ListTile(
                  title: const Text('Change linked exercise'),
                  onTap: () => Navigator.pop(context, 'link'),
                ),
              ],
            ),
          ),
        );
        if (!mounted || action == null) return;
        if (action == 'link') {
          final selected = await pickLibraryExercise(
            context,
            widget.controller,
            unit: initial.unit,
          );
          if (!mounted || selected == null) return;
          setState(
            () => _exercises[index!] = initial.copyWith(
              name: selected.name,
              libraryId: selected.id,
              weightMode: selected.weightMode,
            ),
          );
        } else {
          final result = await editGymWorkingSets(
            context,
            initial,
            double.tryParse(_bodyweight.text.replaceAll(',', '.')),
          );
          if (mounted && result != null)
            setState(() => _exercises[index!] = result);
        }
        return;
      }
      if (library == null || library.needsReview) {
        library = await pickLibraryExercise(context, widget.controller);
        if (!mounted || library == null) return;
      }
    }
    final result = await showDialog<Exercise>(
      context: context,
      builder: (_) => _ExerciseDialog(
        exercise: initial,
        mobility: mobility,
        library: library,
        controller: widget.controller,
      ),
    );
    if (!mounted || result == null) return;
    final saved = widget.workout != null && !mobility
        ? result.copyWith(
            workingSets: result.prescribedSets
                .map((s) => s.copyWith(confirmed: true))
                .toList(),
          )
        : mobility && initial != null
        ? result.copyWith(workingSets: initial.workingSets)
        : result;
    setState(() {
      if (index == null) {
        _exercises.add(saved);
      } else {
        _exercises[index] = saved;
      }
    });
  }

  void _reorderExercise(int oldIndex, int newIndex) {
    setState(() {
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
    });
  }

  Future<void> _pickTrainingDate() async {
    final initial = _scheduledAt!;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year < 2020 ? initial.year : 2020),
      lastDate: DateTime(initial.year > 2100 ? initial.year : 2100, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(
      () => _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if ((_sport == Sport.gym || _sport == Sport.mobility) &&
        _exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise.')),
      );
      return;
    }
    final values = WorkoutTemplate(
      id: widget.template?.id,
      title: _title.text.trim(),
      sport: _sport,
      durationMinutes: int.parse(_duration.text),
      description: _description.text.trim(),
      warmup: _sport == Sport.mobility || _sport == Sport.running
          ? ''
          : _warmup.text.trim(),
      hockeyType: _sport == Sport.hockey ? _hockeyType : null,
      distanceKm: _sport == Sport.running
          ? double.tryParse(_distance.text.replaceAll(',', '.'))
          : null,
      sportDetails: _sport == Sport.hockey ? _sportDetails.text.trim() : '',
      exercises: _sport == Sport.gym || _sport == Sport.mobility
          ? _exercises
          : const [],
      cycleCount: _sport == Sport.mobility ? int.parse(_cycles.text) : 1,
    );
    final workout = widget.workout;
    if (workout == null) {
      Navigator.pop(context, values);
    } else {
      final updated = Workout(
        id: workout.id,
        templateId: workout.templateId,
        title: values.title,
        sport: values.sport,
        scheduledAt: _scheduledAt!,
        durationMinutes: values.durationMinutes,
        description: values.description,
        warmup: values.warmup,
        status: workout.status,
        hockeyType: values.hockeyType,
        distanceKm: values.distanceKm,
        sportDetails: values.sportDetails,
        exercises: values.exercises,
        cycleCount: values.cycleCount,
        comment: _comment.text.trim(),
        completedAt: workout.completedAt,
        targetDurationMinutes: workout.targetDurationMinutes,
        targetDistanceKm: workout.targetDistanceKm,
        startedAt: workout.startedAt,
        bodyWeightKg: double.tryParse(_bodyweight.text.replaceAll(',', '.')),
      );
      try {
        if (updated.sport == Sport.gym)
          validateGymWorkout(updated, finishing: true);
        if (updated.sport == Sport.mobility)
          validateMobilityWorkout(updated, finishing: true, allowUnknown: true);
      } catch (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
        return;
      }
      Navigator.pop(context, updated);
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _positiveDouble(String? value) {
    final number = double.tryParse((value ?? '').replaceAll(',', '.'));
    return number == null || !number.isFinite || number <= 0
        ? 'Enter a number above 0'
        : null;
  }

  String? _positiveInt(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number <= 0 ? 'Enter a number above 0' : null;
  }

  String? _runningPace() {
    final pace = runningPaceSeconds(
      int.tryParse(_duration.text),
      double.tryParse(_distance.text.replaceAll(',', '.')),
    );
    return pace == null ? null : formatRunningPace(pace);
  }
}

class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog({
    this.exercise,
    required this.mobility,
    this.library,
    required this.controller,
  });

  final Exercise? exercise;
  final bool mobility;
  final LibraryExercise? library;
  final AppController controller;

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sets;
  late final TextEditingController _reps;
  late final TextEditingController _weight;
  late ExerciseUnit _unit;
  late bool _perSide;
  LibraryExercise? _library;

  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    _library = widget.library;
    _name = TextEditingController(text: _library?.name ?? exercise?.name ?? '');
    _sets = TextEditingController(text: exercise?.sets.toString() ?? '3');
    _reps = TextEditingController(text: exercise?.reps.toString() ?? '10');
    _weight = TextEditingController(text: exercise?.weightKg.toString() ?? '0');
    _unit = _library?.unit ?? exercise?.unit ?? ExerciseUnit.reps;
    _perSide = exercise?.perSide ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _sets.dispose();
    _reps.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.exercise == null ? 'Add exercise' : 'Edit exercise'),
      content: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: widget.mobility,
                readOnly: !widget.mobility,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Exercise name',
                  suffixIcon: widget.mobility
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.swap_horiz),
                          tooltip: 'Choose exercise',
                          onPressed: () async {
                            final selected = await pickLibraryExercise(
                              context,
                              widget.controller,
                            );
                            if (mounted && selected != null)
                              setState(() {
                                _library = selected;
                                _name.text = selected.name;
                                _unit = selected.unit;
                              });
                          },
                        ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 12),
              SegmentedButton<ExerciseUnit>(
                segments: const [
                  ButtonSegment(value: ExerciseUnit.reps, label: Text('Reps')),
                  ButtonSegment(
                    value: ExerciseUnit.seconds,
                    label: Text('Time'),
                  ),
                ],
                selected: {_unit},
                onSelectionChanged: widget.mobility
                    ? (selection) => setState(() => _unit = selection.first)
                    : null,
              ),
              const SizedBox(height: 12),
              if (widget.mobility)
                _numberField(
                  _reps,
                  _unit == ExerciseUnit.reps ? 'Reps' : 'Time (seconds)',
                )
              else
                Row(
                  children: [
                    Expanded(child: _numberField(_sets, 'Sets')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numberField(
                        _reps,
                        _unit == ExerciseUnit.reps ? 'Reps' : 'Time (seconds)',
                      ),
                    ),
                  ],
                ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Per side'),
                value: _perSide,
                onChanged: (value) => setState(() => _perSide = value!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (!widget.mobility) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Weight / additional weight',
                    suffixText: 'kg',
                  ),
                  validator: (value) {
                    final number = double.tryParse(
                      (value ?? '').replaceAll(',', '.'),
                    );
                    if (number == null || !number.isFinite)
                      return 'Enter a valid number';
                    return _library?.weightMode == WeightMode.external &&
                            number < 0
                        ? 'External load cannot be negative'
                        : null;
                  },
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
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
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
    if (!_key.currentState!.validate()) return;
    Navigator.pop(
      context,
      Exercise(
        name: _name.text.trim(),
        sets: widget.mobility ? 1 : int.parse(_sets.text),
        reps: int.parse(_reps.text),
        weightKg: widget.mobility
            ? 0
            : double.parse(_weight.text.replaceAll(',', '.')),
        libraryId: widget.mobility ? null : _library?.id,
        weightMode: widget.mobility ? null : _library?.weightMode,
        unit: _unit,
        perSide: _perSide,
      ),
    );
  }
}

String _exerciseSummary(Exercise exercise, {required bool mobility}) {
  if (mobility && exercise.workingSets.isNotEmpty) {
    return [
      for (var i = 0; i < exercise.workingSets.length; i++)
        'Cycle ${i + 1}: ${exercise.workingSets[i].amount} ${exercise.unit.name}${exercise.workingSets[i].amount == 0 ? ' (skipped)' : ''}',
    ].join(' / ');
  }
  if (!mobility && exercise.workingSets.isNotEmpty) {
    return exercise.workingSets
        .map(
          (s) =>
              '${s.weightKg} kg × ${s.amount} ${exercise.unit.name}${s.amount == 0 ? ' (skipped)' : ''}',
        )
        .join(' · ');
  }
  final weight = exercise.weightKg == 0
      ? 'bodyweight'
      : '${_compactNumber(exercise.weightKg)} kg';
  final amount = exercise.unit == ExerciseUnit.reps
      ? '${exercise.reps} reps'
      : '${exercise.reps} sec';
  final side = exercise.perSide ? ' · per side' : '';
  return mobility
      ? '$amount$side'
      : '${exercise.sets} × $amount$side · $weight';
}

String _compactNumber(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
