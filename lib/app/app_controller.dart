import 'package:flutter/foundation.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:the_forge/data/repositories/template_repository.dart';
import 'package:the_forge/data/repositories/workout_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    TemplateRepository? templateRepository,
    WorkoutRepository? workoutRepository,
  }) : _templateRepository = templateRepository ?? TemplateRepository(),
       _workoutRepository = workoutRepository ?? WorkoutRepository();

  final TemplateRepository _templateRepository;
  final WorkoutRepository _workoutRepository;
  final List<WorkoutTemplate> _templates = [];
  final List<Workout> _workouts = [];
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
    ]);
    _templates
      ..clear()
      ..addAll(results[0] as List<WorkoutTemplate>);
    _workouts
      ..clear()
      ..addAll(results[1] as List<Workout>);
    notifyListeners();
  }
}
