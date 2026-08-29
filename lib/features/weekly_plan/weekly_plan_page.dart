import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:the_forge/theme/app_colors.dart';

class WeeklyRequirementProgress {
  const WeeklyRequirementProgress({
    required this.completed,
    required this.target,
  });

  final int completed;
  final int target;

  int get missing => (target - completed).clamp(0, target);
  bool get satisfied => completed >= target;
}

WeeklyRequirementProgress weeklyRequirementProgress(
  AppController controller,
  WeeklyRequirement requirement,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final monday = today.subtract(Duration(days: today.weekday - 1));
  final nextMonday = monday.add(const Duration(days: 7));
  final count = controller.workouts.where((workout) {
    return workout.templateId != null &&
        requirement.templateIds.contains(workout.templateId) &&
        !workout.scheduledAt.isBefore(monday) &&
        workout.scheduledAt.isBefore(nextMonday);
  }).length;
  return WeeklyRequirementProgress(
    completed: count,
    target: requirement.targetCount,
  );
}

class WeeklyPlanPage extends StatelessWidget {
  const WeeklyPlanPage({
    super.key,
    required this.controller,
    required this.onSchedule,
  });

  final AppController controller;
  final ValueChanged<WorkoutTemplate> onSchedule;

  @override
  Widget build(BuildContext context) {
    final requirements = controller.weeklyRequirements;
    if (requirements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.checklist,
                size: 56,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: 16),
              Text(
                'No weekly requirements',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'Define how many workouts from one template or a group of templates you need each week.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: controller.templates.isEmpty
                    ? null
                    : () => _editRequirement(context),
                icon: const Icon(Icons.add),
                label: const Text('Add requirement'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        _WeekHeader(
          requirements: requirements,
          controller: controller,
          onAdd: () => _editRequirement(context),
        ),
        const SizedBox(height: 12),
        for (final requirement in requirements)
          _RequirementCard(
            requirement: requirement,
            templates: controller.templates,
            progress: weeklyRequirementProgress(controller, requirement),
            onSchedule: () => _scheduleRequirement(context, requirement),
            onEdit: () => _editRequirement(context, requirement),
            onDelete: () => controller.deleteWeeklyRequirement(requirement),
          ),
      ],
    );
  }

  Future<void> _editRequirement(
    BuildContext context, [
    WeeklyRequirement? requirement,
  ]) async {
    final result = await showDialog<WeeklyRequirement>(
      context: context,
      builder: (_) => _RequirementDialog(
        templates: controller.templates,
        requirement: requirement,
      ),
    );
    if (result != null && context.mounted) {
      await controller.saveWeeklyRequirement(result);
    }
  }

  Future<void> _scheduleRequirement(
    BuildContext context,
    WeeklyRequirement requirement,
  ) async {
    final eligible = controller.templates
        .where((template) => requirement.templateIds.contains(template.id))
        .toList();
    if (eligible.isEmpty) return;
    WorkoutTemplate? selected;
    if (eligible.length == 1) {
      selected = eligible.first;
    } else {
      selected = await showDialog<WorkoutTemplate>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Choose a workout'),
          children: [
            for (final template in eligible)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, template),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(template.title),
                  subtitle: Text(template.sport.label),
                ),
              ),
          ],
        ),
      );
    }
    if (selected != null && context.mounted) onSchedule(selected);
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.requirements,
    required this.controller,
    required this.onAdd,
  });

  final List<WeeklyRequirement> requirements;
  final AppController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final satisfied = requirements
        .where(
          (requirement) =>
              weeklyRequirementProgress(controller, requirement).satisfied,
        )
        .length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              satisfied == requirements.length
                  ? Icons.check_circle
                  : Icons.pending_actions,
              size: 42,
              color: satisfied == requirements.length
                  ? AppColors.moodPositive
                  : AppColors.yellow,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$satisfied / ${requirements.length} requirements met',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Text(
                    'Current week · Monday to Sunday',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Add requirement',
              onPressed: onAdd,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({
    required this.requirement,
    required this.templates,
    required this.progress,
    required this.onSchedule,
    required this.onEdit,
    required this.onDelete,
  });

  final WeeklyRequirement requirement;
  final List<WorkoutTemplate> templates;
  final WeeklyRequirementProgress progress;
  final VoidCallback onSchedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final eligibleNames = templates
        .where((template) => requirement.templateIds.contains(template.id))
        .map((template) => template.title)
        .join(', ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  progress.satisfied
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: progress.satisfied
                      ? AppColors.moodPositive
                      : AppColors.yellow,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    requirement.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            Text(
              eligibleNames,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (progress.completed / progress.target).clamp(0.0, 1.0),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${progress.completed} / ${progress.target} scheduled or completed',
                  ),
                ),
                if (!progress.satisfied)
                  FilledButton.icon(
                    onPressed: onSchedule,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('Schedule'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequirementDialog extends StatefulWidget {
  const _RequirementDialog({required this.templates, this.requirement});

  final List<WorkoutTemplate> templates;
  final WeeklyRequirement? requirement;

  @override
  State<_RequirementDialog> createState() => _RequirementDialogState();
}

class _RequirementDialogState extends State<_RequirementDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.requirement?.name ?? '');
    _target = TextEditingController(
      text: widget.requirement?.targetCount.toString() ?? '1',
    );
    _selectedIds = {...?widget.requirement?.templateIds};
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.requirement == null ? 'Add requirement' : 'Edit requirement',
      ),
      content: Form(
        key: _key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _name,
                autofocus: widget.requirement == null,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Requirement name',
                  hintText: 'Strength, cardio, daily mobility…',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _target,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Times per week'),
                validator: (value) {
                  final count = int.tryParse(value ?? '');
                  return count == null || count <= 0
                      ? 'Enter a number above 0'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Eligible templates',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              for (final template in widget.templates)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(template.title),
                  subtitle: Text(template.sport.label),
                  value: _selectedIds.contains(template.id),
                  onChanged: (selected) => setState(() {
                    if (selected!) {
                      _selectedIds.add(template.id!);
                    } else {
                      _selectedIds.remove(template.id);
                    }
                  }),
                ),
              if (_selectedIds.isEmpty)
                const Text(
                  'Select at least one template.',
                  style: TextStyle(color: AppColors.moodNegative),
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
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    if (!_key.currentState!.validate() || _selectedIds.isEmpty) {
      setState(() {});
      return;
    }
    Navigator.pop(
      context,
      WeeklyRequirement(
        id: widget.requirement?.id,
        name: _name.text.trim(),
        targetCount: int.parse(_target.text),
        templateIds: _selectedIds.toList(),
      ),
    );
  }
}
