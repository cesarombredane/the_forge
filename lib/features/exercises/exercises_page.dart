import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:the_forge/data/repositories/exercise_repository.dart';

void showExerciseError(BuildContext context, Object error) =>
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error.toString())));

Future<LibraryExercise?> pickLibraryExercise(
  BuildContext context,
  AppController controller, {
  ExerciseUnit? unit,
}) => Navigator.push<LibraryExercise>(
  context,
  MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Choose exercise')),
      body: ExercisesPage(controller: controller, picking: true, unit: unit),
    ),
  ),
);

Future<int?> editLibraryExercise(
  BuildContext context,
  AppController controller, [
  LibraryExercise? exercise,
]) => showDialog<int>(
  context: context,
  builder: (_) => _LibraryDialog(controller: controller, exercise: exercise),
);

class ExercisesPage extends StatelessWidget {
  const ExercisesPage({
    super.key,
    required this.controller,
    this.picking = false,
    this.unit,
  });
  final AppController controller;
  final bool picking;
  final ExerciseUnit? unit;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final entries = controller.exerciseLibrary
          .where(
            (e) =>
                (!picking || !e.archived) && (unit == null || e.unit == unit),
          )
          .toList();
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FilledButton.icon(
            onPressed: () async {
              final id = await editLibraryExercise(context, controller);
              if (picking && id != null && context.mounted) {
                final entry = controller.exerciseLibrary.firstWhere(
                  (e) => e.id == id,
                );
                if (unit == null || entry.unit == unit)
                  Navigator.pop(context, entry);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Create exercise'),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text('Create an exercise to use it in gym workouts.'),
          for (final entry in entries)
            Card(
              child: ListTile(
                title: Text(entry.name),
                subtitle: Text(
                  '${entry.unit.name} · ${entry.weightMode == WeightMode.bodyweight ? 'Bodyweight + adjustment' : 'External load'}${entry.needsReview ? '\nReview weight mode and linked entries' : ''}${entry.archived ? '\nArchived' : ''}',
                ),
                leading: Icon(
                  entry.needsReview
                      ? Icons.warning_amber
                      : Icons.fitness_center,
                ),
                onTap: () async {
                  if (picking && !entry.needsReview) {
                    Navigator.pop(context, entry);
                    return;
                  }
                  await editLibraryExercise(context, controller, entry);
                },
                trailing: picking
                    ? const Icon(Icons.chevron_right)
                    : PopupMenuButton<String>(
                        onSelected: (action) async {
                          try {
                            if (action == 'edit')
                              await editLibraryExercise(
                                context,
                                controller,
                                entry,
                              );
                            if (action == 'archive')
                              await controller.setExerciseFlag(
                                entry.id,
                                archived: !entry.archived,
                              );
                            if (action == 'links' && context.mounted)
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _LinksPage(
                                    controller: controller,
                                    exercise: entry,
                                  ),
                                ),
                              );
                          } catch (error) {
                            if (context.mounted)
                              showExerciseError(context, error);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit / review'),
                          ),
                          const PopupMenuItem(
                            value: 'links',
                            child: Text('Review / correct links'),
                          ),
                          PopupMenuItem(
                            value: 'archive',
                            child: Text(entry.archived ? 'Restore' : 'Archive'),
                          ),
                        ],
                      ),
              ),
            ),
        ],
      );
    },
  );
}

class _LibraryDialog extends StatefulWidget {
  const _LibraryDialog({required this.controller, this.exercise});
  final AppController controller;
  final LibraryExercise? exercise;
  @override
  State<_LibraryDialog> createState() => _LibraryDialogState();
}

class _LibraryDialogState extends State<_LibraryDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.exercise?.name ?? '');
  late ExerciseUnit _unit = widget.exercise?.unit ?? ExerciseUnit.reps;
  late WeightMode _mode = widget.exercise?.weightMode ?? WeightMode.external;
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.exercise == null ? 'Create exercise' : 'Edit exercise'),
    content: Form(
      key: _form,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter a name' : null,
            ),
            DropdownButtonFormField<ExerciseUnit>(
              initialValue: _unit,
              decoration: const InputDecoration(labelText: 'Measurement'),
              items: ExerciseUnit.values
                  .map((v) => DropdownMenuItem(value: v, child: Text(v.name)))
                  .toList(),
              onChanged: (v) => _unit = v!,
            ),
            DropdownButtonFormField<WeightMode>(
              initialValue: _mode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Weight mode'),
              items: const [
                DropdownMenuItem(
                  value: WeightMode.external,
                  child: Text('External load'),
                ),
                DropdownMenuItem(
                  value: WeightMode.bodyweight,
                  child: Text('Bodyweight + adjustment'),
                ),
              ],
              onChanged: (v) => _mode = v!,
            ),
            const SizedBox(height: 12),
            const Text(
              'External load: total kg, including both dumbbells. Bodyweight: 0 unassisted, negative assistance, positive added load.',
            ),
            if (widget.exercise?.needsReview == true)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Confirm the mode for imported entries. Conflicting units remain unresolved; correct their links from the exercise menu.',
                ),
              ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _saving
            ? null
            : () async {
                if (!_form.currentState!.validate()) return;
                setState(() {
                  _saving = true;
                  _error = null;
                });
                try {
                  final id = await widget.controller.saveExercise(
                    id: widget.exercise?.id,
                    name: _name.text,
                    unit: _unit,
                    mode: _mode,
                  );
                  if (context.mounted) Navigator.pop(context, id);
                } catch (_) {
                  if (mounted)
                    setState(() {
                      _saving = false;
                      _error =
                          'Could not save. Names must be unique, ignoring case and spaces.';
                    });
                }
              },
        child: const Text('Save'),
      ),
    ],
  );
}

class _LinksPage extends StatefulWidget {
  const _LinksPage({required this.controller, required this.exercise});
  final AppController controller;
  final LibraryExercise exercise;
  @override
  State<_LinksPage> createState() => _LinksPageState();
}

class _LinksPageState extends State<_LinksPage> {
  late Future<List<ExerciseLink>> _links = widget.controller.exerciseLinks(
    widget.exercise.id,
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.exercise.name} links')),
    body: FutureBuilder<List<ExerciseLink>>(
      future: _links,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('${snapshot.error}'));
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Correct a link by selecting a reviewed exercise with the same unit. Recorded names and set values are preserved; the selected weight mode is applied to this entry.',
            ),
            for (final link in snapshot.data!)
              ListTile(
                title: Text(link.parent),
                subtitle: Text(
                  '${link.name} · ${link.unit.name}${link.mode == null ? ' · Needs review' : ' · ${link.mode!.name}'}',
                ),
                trailing: const Icon(Icons.link),
                onTap: () async {
                  final target = await pickLibraryExercise(
                    context,
                    widget.controller,
                    unit: link.unit,
                  );
                  if (target == null) return;
                  try {
                    await widget.controller.relinkExercise(link, target);
                    if (mounted)
                      setState(
                        () => _links = widget.controller.exerciseLinks(
                          widget.exercise.id,
                        ),
                      );
                  } catch (error) {
                    if (context.mounted) showExerciseError(context, error);
                  }
                },
              ),
          ],
        );
      },
    ),
  );
}
