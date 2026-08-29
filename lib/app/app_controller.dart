import 'package:flutter/foundation.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:the_forge/data/repositories/template_repository.dart';
import 'package:the_forge/data/repositories/step_repository.dart';
import 'package:the_forge/data/repositories/workout_repository.dart';
import 'package:the_forge/data/repositories/weight_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    TemplateRepository? templateRepository,
    WorkoutRepository? workoutRepository,
    WeightRepository? weightRepository,
    StepRepository? stepRepository,
  }) : _templateRepository = templateRepository ?? TemplateRepository(),
       _workoutRepository = workoutRepository ?? WorkoutRepository(),
       _weightRepository = weightRepository ?? WeightRepository(),
       _stepRepository = stepRepository ?? StepRepository();

  final TemplateRepository _templateRepository;
  final WorkoutRepository _workoutRepository;
  final WeightRepository _weightRepository;
  final StepRepository _stepRepository;
  final List<WorkoutTemplate> _templates = [];
  final List<Workout> _workouts = [];
  final List<WeightEntry> _weightEntries = [];
  WeightReminder? _weightReminder;
  final List<StepEntry> _stepEntries = [];
  int? _dailyStepGoal;
  bool _loading = true;
  String? _error;

  List<WorkoutTemplate> get templates => List.unmodifiable(_templates);
  List<Workout> get planned => _workouts
      .where((workout) => workout.status == WorkoutStatus.planned)
      .toList();
  List<Workout> get completed => _workouts
      .where((workout) => workout.status == WorkoutStatus.completed)
      .toList()
      .reversed
      .toList();
  List<WeightEntry> get weightEntries => List.unmodifiable(_weightEntries);
  WeightReminder? get weightReminder => _weightReminder;
  List<StepEntry> get stepEntries => List.unmodifiable(_stepEntries);
  int? get dailyStepGoal => _dailyStepGoal;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> initialize() async {
    _loading = true;
    notifyListeners();
    try {
      _error = null;
      await _loadAll();
    } catch (error) {
      _error = 'Could not load local data. $error';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveTemplate(WorkoutTemplate template) {
    return _run(() => _templateRepository.save(template));
  }

  Future<void> deleteTemplate(WorkoutTemplate template) {
    if (template.id == null) return Future.value();
    return _run(() => _templateRepository.delete(template.id!));
  }

  Future<void> schedule(WorkoutTemplate template, DateTime scheduledAt) {
    return _run(() => _workoutRepository.schedule(template, scheduledAt));
  }

  Future<void> reschedule(Workout workout, DateTime scheduledAt) {
    if (workout.id == null) return Future.value();
    return _run(() => _workoutRepository.reschedule(workout.id!, scheduledAt));
  }

  Future<void> deleteWorkout(Workout workout) {
    if (workout.id == null) return Future.value();
    return _run(() => _workoutRepository.delete(workout.id!));
  }

  Future<void> complete(
    Workout workout, {
    required int durationMinutes,
    required String comment,
    required List<Exercise> exercises,
  }) {
    return _run(
      () => _workoutRepository.complete(
        workout,
        durationMinutes: durationMinutes,
        comment: comment,
        exercises: exercises,
      ),
    );
  }

  Future<void> addWeight(double weightKg, {DateTime? recordedAt}) {
    return _run(
      () => _weightRepository.add(weightKg, recordedAt ?? DateTime.now()),
    );
  }

  Future<void> deleteWeight(WeightEntry entry) {
    if (entry.id == null) return Future.value();
    return _run(() => _weightRepository.delete(entry.id!));
  }

  Future<void> saveWeightReminder(WeightReminder reminder) {
    return _run(() => _weightRepository.saveReminder(reminder));
  }

  Future<void> removeWeightReminder() {
    return _run(_weightRepository.removeReminder);
  }

  Future<void> saveSteps(DateTime day, int steps) {
    return _run(() => _stepRepository.save(day, steps));
  }

  Future<void> saveDailyStepGoal(int dailyGoal) {
    return _run(() => _stepRepository.saveDailyGoal(dailyGoal));
  }

  Future<void> _run(Future<void> Function() operation) async {
    try {
      _error = null;
      await operation();
      await _loadAll();
    } catch (error) {
      _error = 'Could not save local data. $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      _templateRepository.getAll(),
      _workoutRepository.getAll(),
      _weightRepository.getAll(),
      _weightRepository.getReminder(),
      _stepRepository.getAll(),
      _stepRepository.getDailyGoal(),
    ]);
    _templates
      ..clear()
      ..addAll(results[0] as List<WorkoutTemplate>);
    _workouts
      ..clear()
      ..addAll(results[1] as List<Workout>);
    _weightEntries
      ..clear()
      ..addAll(results[2] as List<WeightEntry>);
    _weightReminder = results[3] as WeightReminder?;
    _stepEntries
      ..clear()
      ..addAll(results[4] as List<StepEntry>);
    _dailyStepGoal = results[5] as int?;
    notifyListeners();
  }
}
