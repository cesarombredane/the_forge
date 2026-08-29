import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:the_forge/features/templates/template_form_page.dart';
import 'package:the_forge/features/steps/steps_page.dart';
import 'package:the_forge/features/workouts/workout_completion_dialog.dart';
import 'package:the_forge/features/weight/weight_page.dart';
import 'package:the_forge/theme/app_colors.dart';

enum _Page { planning, templates, history, weight, steps }

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  _Page _page = _Page.planning;
  bool _planningCalendarView = false;
  bool _missingTemplateBannerVisible = false;
  DateTime _selectedDay = _dateOnly(DateTime.now());
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(_pageTitle),
          actions: [
            if (_page == _Page.planning)
              IconButton(
                tooltip: _planningCalendarView
                    ? 'Seven-day list'
                    : 'Calendar view',
                onPressed: () => setState(
                  () => _planningCalendarView = !_planningCalendarView,
                ),
                icon: Icon(
                  _planningCalendarView
                      ? Icons.view_agenda_outlined
                      : Icons.calendar_month_outlined,
                ),
              ),
            if (widget.controller.error != null)
              IconButton(
                tooltip: 'Show error',
                onPressed: _showError,
                icon: const Icon(
                  Icons.error_outline,
                  color: AppColors.moodNegative,
                ),
              ),
          ],
        ),
        drawer: _NavigationDrawer(
          page: _page,
          onSelected: (page) {
            Navigator.pop(context);
            _dismissMissingTemplateMessage();
            setState(() => _page = page);
          },
        ),
        body: _body(),
        floatingActionButton: _floatingActionButton(),
      ),
    );
  }

  String get _pageTitle => switch (_page) {
    _Page.planning => 'Planning',
    _Page.templates => 'Templates',
    _Page.history => 'History',
    _Page.weight => 'Weight',
    _Page.steps => 'Steps',
  };

  Widget _body() {
    if (widget.controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return switch (_page) {
      _Page.planning =>
        _planningCalendarView ? _calendarPlanningView() : _weekPlanningView(),
      _Page.templates => _templatesView(),
      _Page.history => _historyView(),
      _Page.weight => WeightPage(controller: widget.controller),
      _Page.steps => StepsPage(controller: widget.controller),
    };
  }

  Widget? _floatingActionButton() {
    return switch (_page) {
      _Page.templates => FloatingActionButton.extended(
        onPressed: () => _openTemplateForm(),
        icon: const Icon(Icons.add),
        label: const Text('New template'),
      ),
      _Page.planning => FloatingActionButton.extended(
        onPressed: _schedule,
        icon: const Icon(Icons.add),
        label: const Text('Add to calendar'),
      ),
      _Page.history => null,
      _Page.weight => null,
      _Page.steps => null,
    };
  }

  Widget _templatesView() {
    final templates = widget.controller.templates;
    if (templates.isEmpty) {
      return _EmptyState(
        icon: Icons.copy_all_outlined,
        title: 'No templates yet',
        message: 'Create a reusable training before adding it to the calendar.',
        actionLabel: 'Create template',
        onAction: _openTemplateForm,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: templates.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final template = templates[index];
        return _TrainingCard(
          title: template.title,
          sport: template.sport,
          subtitle: '${template.durationMinutes} min',
          details: _templateDetails(template),
          description: template.description,
          warmup: template.warmup,
          primaryLabel: 'Schedule',
          primaryIcon: Icons.calendar_month_outlined,
          onPrimary: () => _schedule(template),
          onEdit: () => _openTemplateForm(template),
          onDelete: () => _deleteTemplate(template),
        );
      },
    );
  }

  Widget _weekPlanningView() {
    final today = _dateOnly(DateTime.now());
    final days = List.generate(7, (index) => today.add(Duration(days: index)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final workouts = widget.controller.planned
            .where((workout) => _sameDay(workout.scheduledAt, day))
            .toList();
        return _PlanningDaySection(
          day: day,
          workouts: workouts,
          isToday: index == 0,
          onComplete: _complete,
          onReschedule: _reschedule,
          onDelete: _deleteWorkout,
          onSchedule: () => _scheduleForDay(day),
          weightReminder: _reminderForDay(day),
          onWeighIn: _recordWeight,
        );
      },
    );
  }

  Widget _calendarPlanningView() {
    final dayWorkouts = widget.controller.planned
        .where((workout) => _sameDay(workout.scheduledAt, _selectedDay))
        .toList();
    return Column(
      children: [
        _MonthCalendar(
          visibleMonth: _visibleMonth,
          selectedDay: _selectedDay,
          workouts: widget.controller.planned,
          weightReminder: widget.controller.weightReminder,
          onMonthChanged: (month) => setState(() => _visibleMonth = month),
          onDaySelected: (day) => setState(() => _selectedDay = day),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _longDate(_selectedDay),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        Expanded(
          child: dayWorkouts.isEmpty && _reminderForDay(_selectedDay) == null
              ? const Center(
                  child: Text(
                    'Rest day',
                    style: TextStyle(
                      color: AppColors.textDisabled,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  children: [
                    if (_reminderForDay(_selectedDay) case final reminder?) ...[
                      _WeightReminderTile(
                        scheduledAt: reminder.scheduledOn(_selectedDay),
                        onWeighIn: _sameDay(_selectedDay, DateTime.now())
                            ? _recordWeight
                            : null,
                      ),
                      const SizedBox(height: 8),
                    ],
                    for (final workout in dayWorkouts) ...[
                      _TrainingCard(
                        title: workout.title,
                        sport: workout.sport,
                        subtitle:
                            '${_time(workout.scheduledAt)} · ${workout.durationMinutes} min',
                        details: _workoutDetails(workout),
                        description: workout.description,
                        warmup: workout.warmup,
                        primaryLabel: 'Mark as done',
                        primaryIcon: Icons.check,
                        onPrimary: () => _complete(workout),
                        onEdit: () => _reschedule(workout),
                        editLabel: 'Reschedule',
                        onDelete: () => _deleteWorkout(workout),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _historyView() {
    final workouts = widget.controller.completed;
    if (workouts.isEmpty) {
      return const _EmptyState(
        icon: Icons.history,
        title: 'No history yet',
        message: 'Completed workouts will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: workouts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return _TrainingCard(
          title: workout.title,
          sport: workout.sport,
          subtitle:
              '${_shortDate(workout.scheduledAt)} at ${_time(workout.scheduledAt)} · ${workout.durationMinutes} min',
          details: _workoutDetails(workout),
          description: workout.description,
          warmup: workout.warmup,
          comment: workout.comment,
          onDelete: () => _deleteWorkout(workout),
        );
      },
    );
  }

  Future<void> _openTemplateForm([WorkoutTemplate? template]) async {
    final result = await Navigator.push<WorkoutTemplate>(
      context,
      MaterialPageRoute(builder: (_) => TemplateFormPage(template: template)),
    );
    if (result != null && mounted) {
      await _perform(() => widget.controller.saveTemplate(result));
    }
  }

  Future<void> _schedule([WorkoutTemplate? initialTemplate]) async {
    if (widget.controller.templates.isEmpty) {
      _showMissingTemplateMessage();
      return;
    }
    final result = await showDialog<_ScheduleResult>(
      context: context,
      builder: (_) => _ScheduleDialog(
        templates: widget.controller.templates,
        initialTemplate: initialTemplate,
        initialDate: _selectedDay,
      ),
    );
    if (result == null || !mounted) return;
    await _perform(
      () => widget.controller.schedule(result.template, result.dateTime),
    );
    if (mounted) {
      setState(() {
        _page = _Page.planning;
        _selectedDay = _dateOnly(result.dateTime);
        _visibleMonth = DateTime(result.dateTime.year, result.dateTime.month);
      });
    }
  }

  void _scheduleForDay(DateTime day) {
    if (widget.controller.templates.isEmpty) {
      _showMissingTemplateMessage();
      return;
    }
    setState(() => _selectedDay = day);
    _schedule();
  }

  Future<void> _reschedule(Workout workout) async {
    final dateTime = await _pickDateTime(workout.scheduledAt);
    if (dateTime != null && mounted) {
      await _perform(() => widget.controller.reschedule(workout, dateTime));
      setState(() {
        _selectedDay = _dateOnly(dateTime);
        _visibleMonth = DateTime(dateTime.year, dateTime.month);
      });
    }
  }

  Future<void> _complete(Workout workout) async {
    final result = await showDialog<WorkoutCompletion>(
      context: context,
      builder: (_) => WorkoutCompletionDialog(workout: workout),
    );
    if (result == null || !mounted) return;
    await _perform(
      () => widget.controller.complete(
        workout,
        durationMinutes: result.durationMinutes,
        comment: result.comment,
        exercises: result.exercises,
      ),
    );
  }

  Future<void> _recordWeight() async {
    final weight = await showWeightEntryDialog(
      context,
      initialWeight: widget.controller.weightEntries.firstOrNull?.weightKg,
    );
    if (weight != null && mounted) {
      await _perform(() => widget.controller.addWeight(weight));
    }
  }

  WeightReminder? _reminderForDay(DateTime day) {
    final reminder = widget.controller.weightReminder;
    return reminder?.weekday == day.weekday ? reminder : null;
  }

  Future<void> _deleteTemplate(WorkoutTemplate template) async {
    if (await _confirmDelete(template.title) && mounted) {
      await _perform(() => widget.controller.deleteTemplate(template));
    }
  }

  Future<void> _deleteWorkout(Workout workout) async {
    if (await _confirmDelete(workout.title) && mounted) {
      await _perform(() => widget.controller.deleteWorkout(workout));
    }
  }

  Future<bool> _confirmDelete(String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete permanently?'),
            content: Text('“$title” will be deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (selectedTime == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  Future<void> _perform(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      if (mounted) _showError();
    }
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.controller.error ?? 'Something went wrong.'),
      ),
    );
  }

  void _showMissingTemplateMessage() {
    if (_missingTemplateBannerVisible) return;
    final messenger = ScaffoldMessenger.of(context);
    _missingTemplateBannerVisible = true;
    messenger.showMaterialBanner(
      MaterialBanner(
        leading: const Icon(Icons.error_outline, color: AppColors.moodNegative),
        content: const Text('Create a workout template before scheduling it.'),
        backgroundColor: const Color(0xFF3A2020),
        actions: [
          TextButton(
            onPressed: () {
              _dismissMissingTemplateMessage();
              setState(() => _page = _Page.templates);
            },
            child: const Text(
              'Go to templates',
              style: TextStyle(color: AppColors.moodNegative),
            ),
          ),
        ],
      ),
    );
  }

  void _dismissMissingTemplateMessage() {
    if (!_missingTemplateBannerVisible) return;
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    _missingTemplateBannerVisible = false;
  }
}

class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({required this.page, required this.onSelected});

  final _Page page;
  final ValueChanged<_Page> onSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const ListTile(
              title: Text(
                'THE FORGE',
                style: TextStyle(
                  color: AppColors.yellow,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const Divider(),
            _item(Icons.calendar_month_outlined, 'Planning', _Page.planning),
            _item(Icons.copy_all_outlined, 'Templates', _Page.templates),
            _item(Icons.history, 'History', _Page.history),
            _item(Icons.monitor_weight_outlined, 'Weight', _Page.weight),
            _item(Icons.directions_walk, 'Steps', _Page.steps),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, _Page target) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: page == target,
      onTap: () => onSelected(target),
    );
  }
}

class _PlanningDaySection extends StatelessWidget {
  const _PlanningDaySection({
    required this.day,
    required this.workouts,
    required this.isToday,
    required this.onComplete,
    required this.onReschedule,
    required this.onDelete,
    required this.onSchedule,
    required this.weightReminder,
    required this.onWeighIn,
  });

  final DateTime day;
  final List<Workout> workouts;
  final bool isToday;
  final ValueChanged<Workout> onComplete;
  final ValueChanged<Workout> onReschedule;
  final ValueChanged<Workout> onDelete;
  final VoidCallback onSchedule;
  final WeightReminder? weightReminder;
  final VoidCallback onWeighIn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isToday ? AppColors.yellow : AppColors.surfaceRaised,
            width: isToday ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isToday
                          ? 'TODAY · ${_agendaDate(day)}'
                          : _agendaDate(day),
                      style: TextStyle(
                        color: isToday
                            ? AppColors.yellow
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Schedule on this day',
                    onPressed: onSchedule,
                    icon: const Icon(Icons.add, size: 20),
                  ),
                ],
              ),
            ),
            if (workouts.isEmpty && weightReminder == null)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 2, 16, 16),
                child: Text(
                  'Rest day',
                  style: TextStyle(
                    color: AppColors.textDisabled,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else ...[
              if (weightReminder != null)
                _WeightReminderTile(
                  scheduledAt: weightReminder!.scheduledOn(day),
                  onWeighIn: _sameDay(day, DateTime.now()) ? onWeighIn : null,
                ),
              for (var index = 0; index < workouts.length; index++) ...[
                if (index > 0 || weightReminder != null)
                  const Divider(height: 1, indent: 16, endIndent: 16),
                _PlanningWorkoutTile(
                  workout: workouts[index],
                  onComplete: () => onComplete(workouts[index]),
                  onReschedule: () => onReschedule(workouts[index]),
                  onDelete: () => onDelete(workouts[index]),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanningWorkoutTile extends StatelessWidget {
  const _PlanningWorkoutTile({
    required this.workout,
    required this.onComplete,
    required this.onReschedule,
    required this.onDelete,
  });

  final Workout workout;
  final VoidCallback onComplete;
  final VoidCallback onReschedule;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(12, 2, 4, 4),
      leading: _SportIcon(sport: workout.sport, compact: true),
      title: Text(workout.title),
      subtitle: Text(
        '${_time(workout.scheduledAt)} · ${workout.sport.label} · ${workout.durationMinutes} min',
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Mark as done',
            onPressed: onComplete,
            icon: const Icon(Icons.check_circle_outline),
          ),
          PopupMenuButton<String>(
            onSelected: (action) {
              if (action == 'reschedule') onReschedule();
              if (action == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'reschedule', child: Text('Reschedule')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightReminderTile extends StatelessWidget {
  const _WeightReminderTile({
    required this.scheduledAt,
    required this.onWeighIn,
  });

  final DateTime scheduledAt;
  final VoidCallback? onWeighIn;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(12, 2, 8, 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.monitor_weight_outlined,
          color: AppColors.yellow,
        ),
      ),
      title: const Text('Weekly weigh-in'),
      subtitle: Text(
        _time(scheduledAt),
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: onWeighIn == null
          ? null
          : FilledButton(
              onPressed: onWeighIn,
              child: const Text('Enter weight'),
            ),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.visibleMonth,
    required this.selectedDay,
    required this.workouts,
    required this.weightReminder,
    required this.onMonthChanged,
    required this.onDaySelected,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final List<Workout> workouts;
  final WeightReminder? weightReminder;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final days = DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final offset = first.weekday - 1;
    final cells = ((offset + days + 6) ~/ 7) * 7;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => onMonthChanged(
                  DateTime(visibleMonth.year, visibleMonth.month - 1),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _monthYear(visibleMonth),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => onMonthChanged(
                  DateTime(visibleMonth.year, visibleMonth.month + 1),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (final day in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(child: Center(child: Text(day))),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.05,
            ),
            itemCount: cells,
            itemBuilder: (context, index) {
              final dayNumber = index - offset + 1;
              if (dayNumber < 1 || dayNumber > days) return const SizedBox();
              final day = DateTime(
                visibleMonth.year,
                visibleMonth.month,
                dayNumber,
              );
              final selected = _sameDay(day, selectedDay);
              final today = _sameDay(day, DateTime.now());
              final hasWorkout = workouts.any(
                (workout) => _sameDay(workout.scheduledAt, day),
              );
              final hasWeightReminder = weightReminder?.weekday == day.weekday;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onDaySelected(day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.yellow : null,
                    shape: BoxShape.circle,
                    border: today
                        ? Border.all(
                            color: selected
                                ? AppColors.yellowSoft
                                : AppColors.yellow,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          color: selected
                              ? AppColors.background
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (hasWorkout || hasWeightReminder)
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.background
                                : AppColors.yellow,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrainingCard extends StatelessWidget {
  const _TrainingCard({
    required this.title,
    required this.sport,
    required this.subtitle,
    required this.details,
    required this.description,
    required this.warmup,
    this.comment = '',
    this.primaryLabel,
    this.primaryIcon,
    this.onPrimary,
    this.onEdit,
    this.editLabel = 'Edit',
    required this.onDelete,
  });

  final String title;
  final Sport sport;
  final String subtitle;
  final String details;
  final String description;
  final String warmup;
  final String comment;
  final String? primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback? onPrimary;
  final VoidCallback? onEdit;
  final String editLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SportIcon(sport: sport),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${sport.label} · $subtitle',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') onEdit?.call();
                    if (action == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      PopupMenuItem(value: 'edit', child: Text(editLabel)),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(details),
            ],
            if (description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            if (warmup.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Warm-up', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                warmup,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            if (comment.isNotEmpty) ...[
              const Divider(height: 24),
              Text('“$comment”'),
            ],
            if (onPrimary != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onPrimary,
                  icon: Icon(primaryIcon),
                  label: Text(primaryLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SportIcon extends StatelessWidget {
  const _SportIcon({required this.sport, this.compact = false});

  final Sport sport;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final icon = switch (sport) {
      Sport.gym => Icons.fitness_center,
      Sport.running => Icons.directions_run,
      Sport.hockey => Icons.sports_hockey,
      Sport.mobility => Icons.self_improvement,
    };
    return Container(
      width: compact ? 36 : 44,
      height: compact ? 36 : 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.yellow),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScheduleResult {
  const _ScheduleResult(this.template, this.dateTime);

  final WorkoutTemplate template;
  final DateTime dateTime;
}

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog({
    required this.templates,
    required this.initialTemplate,
    required this.initialDate,
  });

  final List<WorkoutTemplate> templates;
  final WorkoutTemplate? initialTemplate;
  final DateTime initialDate;

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  late WorkoutTemplate _template;
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _template = widget.initialTemplate ?? widget.templates.first;
    _date = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add to calendar'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<WorkoutTemplate>(
              initialValue: _template,
              decoration: const InputDecoration(labelText: 'Template'),
              items: widget.templates
                  .map(
                    (template) => DropdownMenuItem(
                      value: template,
                      child: Text(template.title),
                    ),
                  )
                  .toList(),
              onChanged: (template) => setState(() => _template = template!),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Date'),
              subtitle: Text(_shortDate(_date)),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Time'),
              subtitle: Text(_time.format(context)),
              onTap: _pickTime,
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
          onPressed: () => Navigator.pop(
            context,
            _ScheduleResult(
              _template,
              DateTime(
                _date.year,
                _date.month,
                _date.day,
                _time.hour,
                _time.minute,
              ),
            ),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (result != null) setState(() => _date = result);
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(context: context, initialTime: _time);
    if (result != null) setState(() => _time = result);
  }
}

String _templateDetails(WorkoutTemplate template) {
  return _details(
    sport: template.sport,
    hockeyType: template.hockeyType,
    distanceKm: template.distanceKm,
    cadence: template.cadence,
    sportDetails: template.sportDetails,
    exercises: template.exercises,
    cycleCount: template.cycleCount,
  );
}

String _workoutDetails(Workout workout) {
  return _details(
    sport: workout.sport,
    hockeyType: workout.hockeyType,
    distanceKm: workout.distanceKm,
    cadence: workout.cadence,
    sportDetails: workout.sportDetails,
    exercises: workout.exercises,
    cycleCount: workout.cycleCount,
  );
}

String _details({
  required Sport sport,
  required HockeySessionType? hockeyType,
  required double? distanceKm,
  required int? cadence,
  required String sportDetails,
  required List<Exercise> exercises,
  required int cycleCount,
}) {
  final lines = <String>[];
  if (hockeyType != null) lines.add(hockeyType.label);
  if (distanceKm != null) lines.add('${_number(distanceKm)} km');
  if (cadence != null) lines.add('$cadence steps/min');
  if (sportDetails.isNotEmpty) lines.add(sportDetails);
  if (sport == Sport.mobility) {
    lines.add('$cycleCount ${cycleCount == 1 ? 'cycle' : 'cycles'}');
  }
  for (final exercise in exercises) {
    final weight = exercise.weightKg == 0
        ? 'bodyweight'
        : '${_number(exercise.weightKg)} kg';
    final amount = exercise.unit == ExerciseUnit.reps
        ? '${exercise.reps} reps'
        : '${exercise.reps} sec';
    final side = exercise.perSide ? ' · per side' : '';
    if (sport == Sport.mobility) {
      lines.add('${exercise.name}: $amount$side');
    } else {
      lines.add('${exercise.name}: ${exercise.sets} × $amount$side · $weight');
    }
  }
  return lines.join('\n');
}

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _time(DateTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
String _shortDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
String _longDate(DateTime value) {
  const days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return '${days[value.weekday - 1]}, ${_shortDate(value)}';
}

String _agendaDate(DateTime value) {
  const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  return '${days[value.weekday - 1]} ${months[value.month - 1]} ${value.day}';
}

String _monthYear(DateTime value) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[value.month - 1]} ${value.year}';
}
