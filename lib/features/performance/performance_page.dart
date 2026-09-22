import 'dart:math' as math;
import 'hockey_performance_tab.dart';
import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:the_forge/data/models/performance.dart';
import 'package:the_forge/features/exercises/exercises_page.dart';
import 'package:the_forge/features/workouts/running_comparison.dart';

class PerformancePage extends StatelessWidget {
  const PerformancePage({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Column(
      children: [
        const TabBar(
          tabs: [
            Tab(text: 'Gym'),
            Tab(text: 'Running'),
            Tab(text: 'Hockey'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _gym(context),
              _running(),
              HockeyPerformanceTab(controller: controller),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _gym(BuildContext context) {
    final selected = controller.exerciseLibrary
        .where((e) => e.tracked)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OutlinedButton.icon(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Exercises to track'),
              content: SizedBox(
                width: 400,
                child: ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => ListView(
                    shrinkWrap: true,
                    children: [
                      if (controller.exerciseLibrary.isEmpty)
                        const Text(
                          'Create exercises in the Exercises page first.',
                        ),
                      for (final exercise in controller.exerciseLibrary)
                        CheckboxListTile(
                          title: Text(exercise.name),
                          subtitle: exercise.archived
                              ? const Text('Archived')
                              : null,
                          value: exercise.tracked,
                          onChanged: (value) async {
                            try {
                              await controller.setExerciseFlag(
                                exercise.id,
                                tracked: value,
                              );
                            } catch (error) {
                              if (context.mounted)
                                showExerciseError(context, error);
                            }
                          },
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          icon: const Icon(Icons.checklist),
          label: const Text('Choose exercises'),
        ),
        if (selected.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Choose the exercises whose progression you want to follow.',
            ),
          ),
        for (final exercise in selected) _gymChart(exercise),
      ],
    );
  }

  Widget _gymChart(LibraryExercise exercise) {
    final values = gymPerformance(
      controller.workouts,
      exercise.id,
      exercise.unit,
    );
    final unit = exercise.unit == ExerciseUnit.reps ? 'kg·reps' : 'kg·seconds';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PerformanceChart(
          title: exercise.name,
          firstLabel: 'Highest weight (kg)',
          secondLabel: 'Total ($unit)',
          points: values
              .map(
                (value) => PerformancePoint(
                  value.workout.scheduledAt,
                  value.workout.title,
                  value.weight,
                  value.total,
                  '${value.weight.toStringAsFixed(2)} kg · ${value.total.toStringAsFixed(2)} $unit\n${value.workout.exercises.where((e) => e.libraryId == exercise.id && e.unit == exercise.unit).expand((e) => e.workingSets.map((s) => '${s.weightKg} kg × ${s.amount} ${e.unit.name}${s.amount == 0 ? ' (skipped)' : ''}')).join(' / ')}',
                ),
              )
              .toList(),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: Text(
            'Working sets only. Entries with unknown weight mode/bodyweight or a different unit are excluded. Review exercise links or edit History to correct them.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _running() {
    final runs =
        controller.completed
            .where(
              (w) =>
                  w.sport == Sport.running &&
                  runningPaceSeconds(w.durationMinutes, w.distanceKm) != null,
            )
            .toList()
          ..sort((a, b) {
            final date = a.scheduledAt.compareTo(b.scheduledAt);
            return date != 0 ? date : (a.id ?? 0).compareTo(b.id ?? 0);
          });
    List<PerformancePoint> points(
      double Function(Workout) value,
      String Function(Workout) label,
    ) => runs
        .map(
          (w) => PerformancePoint(
            w.scheduledAt,
            w.title,
            value(w),
            null,
            label(w),
          ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Actual results · one point per completed run'),
        PerformanceChart(
          title: 'Pace',
          firstLabel: 'min/km',
          firstFormat: (value) => formatRunningPace(value.round()),
          points: points(
            (w) =>
                runningPaceSeconds(w.durationMinutes, w.distanceKm)!.toDouble(),
            (w) =>
                '${formatRunningPace(runningPaceSeconds(w.durationMinutes, w.distanceKm)!)} min/km',
          ),
        ),
        PerformanceChart(
          title: 'Distance',
          firstLabel: 'km',
          points: points((w) => w.distanceKm!, (w) => '${w.distanceKm} km'),
        ),
        PerformanceChart(
          title: 'Duration',
          firstLabel: 'minutes',
          points: points(
            (w) => w.durationMinutes.toDouble(),
            (w) => '${w.durationMinutes} minutes',
          ),
        ),
      ],
    );
  }
}

class PerformancePoint {
  const PerformancePoint(
    this.date,
    this.title,
    this.first,
    this.second,
    this.details,
  );
  final DateTime date;
  final String title;
  final double first;
  final double? second;
  final String details;
}

class PerformanceChart extends StatefulWidget {
  const PerformanceChart({
    super.key,
    required this.title,
    required this.firstLabel,
    required this.points,
    this.secondLabel,
    this.firstFormat,
    this.sharedScale = false,
  });
  final String title;
  final String firstLabel;
  final String? secondLabel;
  final bool sharedScale;
  final String Function(double)? firstFormat;
  final List<PerformancePoint> points;
  @override
  State<PerformanceChart> createState() => _PerformanceChartState();
}

class _PerformanceChartState extends State<PerformanceChart> {
  int? _selected;
  @override
  Widget build(BuildContext context) {
    final points = widget.points;
    final index = points.isEmpty
        ? null
        : (_selected ?? points.length - 1).clamp(0, points.length - 1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              children: [
                Text(
                  '● ${widget.firstLabel} · left axis',
                  style: const TextStyle(color: Colors.amber),
                ),
                if (widget.secondLabel != null)
                  Text(
                    '● ${widget.secondLabel} · right axis',
                    style: const TextStyle(color: Colors.cyanAccent),
                  ),
              ],
            ),
            if (points.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No completed performances with known values yet.'),
              )
            else ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (event) {
                    final width = math.max(1.0, constraints.maxWidth - 92);
                    var nearest = 0;
                    var difference = double.infinity;
                    for (var i = 0; i < points.length; i++) {
                      final dx =
                          (46 +
                                  _fraction(points, i) * width -
                                  event.localPosition.dx)
                              .abs();
                      if (dx < difference) {
                        nearest = i;
                        difference = dx;
                      }
                    }
                    setState(() => _selected = nearest);
                  },
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _ChartPainter(
                        points,
                        index!,
                        widget.firstFormat,
                        widget.secondLabel != null,
                        widget.sharedScale,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous workout',
                    onPressed: index! <= 0
                        ? null
                        : () => setState(() => _selected = index - 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      '${MaterialLocalizations.of(context).formatMediumDate(points[index].date)} · ${points[index].title}',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next workout',
                    onPressed: index >= points.length - 1
                        ? null
                        : () => setState(() => _selected = index + 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Text(points[index].details),
            ],
          ],
        ),
      ),
    );
  }
}

double _fraction(List<PerformancePoint> points, int index) {
  final span =
      points.last.date.millisecondsSinceEpoch -
      points.first.date.millisecondsSinceEpoch;
  if (span == 0) return points.length == 1 ? 0.5 : index / (points.length - 1);
  return (points[index].date.millisecondsSinceEpoch -
          points.first.date.millisecondsSinceEpoch) /
      span;
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(
    this.points,
    this.selected,
    this.format,
    this.dual,
    this.sharedScale,
  );
  final List<PerformancePoint> points;
  final int selected;
  final String Function(double)? format;
  final bool dual;
  final bool sharedScale;
  void _text(Canvas canvas, String text, Offset position, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 46);
    painter.paint(canvas, position);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = math.max(1.0, size.width - 92);
    final height = size.height - 36;
    final top = 8.0;
    final firstMin = math.min(0.0, points.map((p) => p.first).reduce(math.min));
    final secondMin = math.min(
      0.0,
      points.map((p) => p.second ?? 0).reduce(math.min),
    );
    final minFirst = sharedScale ? math.min(firstMin, secondMin) : firstMin;
    final minSecond = sharedScale ? minFirst : secondMin;
    var maxFirst = math.max(1.0, points.map((p) => p.first).reduce(math.max));
    var maxSecond = math.max(
      1.0,
      points.map((p) => p.second ?? 0).reduce(math.max),
    );
    if (sharedScale) {
      maxFirst = math.max(maxFirst, maxSecond);
      maxSecond = maxFirst;
    }
    for (var tick = 0; tick <= 4; tick++) {
      final fraction = tick / 4;
      final y = top + height * (1 - fraction);
      canvas.drawLine(
        Offset(46, y),
        Offset(size.width - 46, y),
        Paint()..color = Colors.white12,
      );
      _text(
        canvas,
        format?.call(minFirst + (maxFirst - minFirst) * fraction) ??
            (minFirst + (maxFirst - minFirst) * fraction).toStringAsFixed(1),
        Offset(0, y - 6),
        Colors.amber,
      );
      if (dual)
        _text(
          canvas,
          (minSecond + (maxSecond - minSecond) * fraction).toStringAsFixed(0),
          Offset(size.width - 42, y - 6),
          Colors.cyanAccent,
        );
    }
    void line(bool second, Color color, double minimum, double maximum) {
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final value = second ? points[i].second! : points[i].first;
        final point = Offset(
          46 + _fraction(points, i) * width,
          top + height * (1 - (value - minimum) / (maximum - minimum)),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawCircle(point, i == selected ? 5 : 3, Paint()..color = color);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    line(false, Colors.amber, minFirst, maxFirst);
    if (dual) line(true, Colors.cyanAccent, minSecond, maxSecond);
    String date(DateTime d) => '${d.day}/${d.month}/${d.year}';
    _text(
      canvas,
      date(points.first.date),
      Offset(46, size.height - 20),
      Colors.white70,
    );
    if (points.length > 1)
      _text(
        canvas,
        date(points.last.date),
        Offset(size.width - 88, size.height - 20),
        Colors.white70,
      );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => true;
}
