import 'package:flutter/material.dart';
import 'package:the_forge/data/models/training.dart';

class TemplateFormPage extends StatefulWidget {
  const TemplateFormPage({super.key, this.template});

  final WorkoutTemplate? template;

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
  late final TextEditingController _cadence;
  late final TextEditingController _sportDetails;
  late final TextEditingController _cycles;
  late Sport _sport;
  HockeySessionType _hockeyType = HockeySessionType.training;
  late List<Exercise> _exercises;

  @override
  void initState() {
    super.initState();
    final template = widget.template;
    _title = TextEditingController(text: template?.title ?? '');
    _duration = TextEditingController(
      text: template?.durationMinutes.toString() ?? '60',
    );
    _description = TextEditingController(text: template?.description ?? '');
    _warmup = TextEditingController(text: template?.warmup ?? '');
    _distance = TextEditingController(
      text: template?.distanceKm?.toString() ?? '',
    );
    _cadence = TextEditingController(text: template?.cadence?.toString() ?? '');
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
    _cadence.dispose();
    _sportDetails.dispose();
    _cycles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template == null ? 'New template' : 'Edit template'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                autofocus: widget.template == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Template name',
                  hintText: 'Leg day, Sunday run…',
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _duration,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration',
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
              if (_sport != Sport.mobility) ...[
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
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save template'),
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
      Sport.running => _distanceFields(
        detailsLabel: 'Pace, route or effort notes',
      ),
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

  List<Widget> _distanceFields({required String detailsLabel}) => [
    TextFormField(
      controller: _distance,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Distance',
        suffixText: 'km',
      ),
      validator: _optionalPositiveDouble,
    ),
    const SizedBox(height: 16),
    TextFormField(
      controller: _cadence,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Target cadence',
        suffixText: 'steps/min',
      ),
      validator: _optionalPositiveInt,
    ),
    const SizedBox(height: 16),
    TextFormField(
      controller: _sportDetails,
      minLines: 2,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: detailsLabel,
        alignLabelWithHint: true,
      ),
    ),
  ];

  Future<void> _editExercise({int? index, required bool mobility}) async {
    FocusScope.of(context).unfocus();
    final result = await showDialog<Exercise>(
      context: context,
      builder: (_) => _ExerciseDialog(
        exercise: index == null ? null : _exercises[index],
        mobility: mobility,
      ),
    );
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    if (result == null) return;
    setState(() {
      if (index == null) {
        _exercises.add(result);
      } else {
        _exercises[index] = result;
      }
    });
  }

  void _reorderExercise(int oldIndex, int newIndex) {
    setState(() {
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
    });
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
    Navigator.pop(
      context,
      WorkoutTemplate(
        id: widget.template?.id,
        title: _title.text.trim(),
        sport: _sport,
        durationMinutes: int.parse(_duration.text),
        description: _description.text.trim(),
        warmup: _sport == Sport.mobility ? '' : _warmup.text.trim(),
        hockeyType: _sport == Sport.hockey ? _hockeyType : null,
        distanceKm: _sport == Sport.running
            ? double.tryParse(_distance.text)
            : null,
        cadence: _sport == Sport.running ? int.tryParse(_cadence.text) : null,
        sportDetails: _sport == Sport.gym || _sport == Sport.mobility
            ? ''
            : _sportDetails.text.trim(),
        exercises: _sport == Sport.gym || _sport == Sport.mobility
            ? _exercises
            : const [],
        cycleCount: _sport == Sport.mobility ? int.parse(_cycles.text) : 1,
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _optionalPositiveDouble(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value);
    return number == null || number <= 0 ? 'Enter a positive number' : null;
  }

  String? _optionalPositiveInt(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = int.tryParse(value);
    return number == null || number <= 0 ? 'Enter a positive number' : null;
  }

  String? _positiveInt(String? value) {
    final number = int.tryParse(value ?? '');
    return number == null || number <= 0 ? 'Enter a number above 0' : null;
  }
}

class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog({this.exercise, required this.mobility});

  final Exercise? exercise;
  final bool mobility;

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

  @override
  void initState() {
    super.initState();
    final exercise = widget.exercise;
    _name = TextEditingController(text: exercise?.name ?? '');
    _sets = TextEditingController(text: exercise?.sets.toString() ?? '3');
    _reps = TextEditingController(text: exercise?.reps.toString() ?? '10');
    _weight = TextEditingController(text: exercise?.weightKg.toString() ?? '0');
    _unit = exercise?.unit ?? ExerciseUnit.reps;
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
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Exercise name'),
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
                onSelectionChanged: (selection) =>
                    setState(() => _unit = selection.first),
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
                    final number = double.tryParse(value ?? '');
                    return number == null ? 'Enter a number' : null;
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
        weightKg: widget.mobility ? 0 : double.parse(_weight.text),
        unit: _unit,
        perSide: _perSide,
      ),
    );
  }
}

String _exerciseSummary(Exercise exercise, {required bool mobility}) {
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
