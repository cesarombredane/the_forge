import 'package:sqflite/sqflite.dart';
import 'package:the_forge/data/local/app_database.dart';
import 'package:the_forge/data/models/training.dart';

class WorkoutRepository {
  WorkoutRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<List<Workout>> getAll() async {
    final database = await _appDatabase.database;
    final rows = await database.query('workouts', orderBy: 'scheduled_at ASC');
    final workouts = <Workout>[];
    for (final row in rows) {
      workouts.add(
        Workout.fromMap(
          row,
          exercises: await _getExercises(database, row['id'] as int),
        ),
      );
    }
    return workouts;
  }

  Future<void> schedule(WorkoutTemplate template, DateTime scheduledAt) async {
    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final workout = Workout(
        templateId: template.id,
        title: template.title,
        sport: template.sport,
        scheduledAt: scheduledAt,
        durationMinutes: template.durationMinutes,
        description: template.description,
        warmup: template.warmup,
        status: WorkoutStatus.planned,
        hockeyType: template.hockeyType,
        distanceKm: template.distanceKm,
        cadence: template.cadence,
        sportDetails: template.sportDetails,
        exercises: template.exercises,
      );
      final values = workout.toMap()..remove('id');
      final workoutId = await transaction.insert('workouts', values);
      await _replaceExercises(transaction, workoutId, workout.exercises);
    });
  }

  Future<void> reschedule(int workoutId, DateTime scheduledAt) async {
    final database = await _appDatabase.database;
    await database.update(
      'workouts',
      {'scheduled_at': scheduledAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [workoutId],
    );
  }

  Future<void> delete(int id) async {
    final database = await _appDatabase.database;
    await database.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> complete(
    Workout workout, {
    required int durationMinutes,
    required String comment,
    required List<Exercise> exercises,
  }) async {
    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      await transaction.update(
        'workouts',
        {
          'status': WorkoutStatus.completed.name,
          'duration_minutes': durationMinutes,
          'comment': comment,
          'completed_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [workout.id],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await _replaceExercises(transaction, workout.id!, exercises);
    });
  }

  Future<List<Exercise>> _getExercises(Database database, int workoutId) async {
    final rows = await database.query(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'position',
    );
    return rows
        .map(
          (row) => Exercise(
            name: row['name'] as String,
            sets: row['sets'] as int,
            reps: row['reps'] as int,
            weightKg: (row['weight_kg'] as num).toDouble(),
            unit: ExerciseUnit.values.byName(row['unit'] as String),
            perSide: (row['per_side'] as int) == 1,
          ),
        )
        .toList();
  }

  Future<void> _replaceExercises(
    Transaction transaction,
    int workoutId,
    List<Exercise> exercises,
  ) async {
    await transaction.delete(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
    for (var index = 0; index < exercises.length; index++) {
      final exercise = exercises[index];
      await transaction.insert('workout_exercises', {
        'workout_id': workoutId,
        'position': index,
        'name': exercise.name,
        'sets': exercise.sets,
        'reps': exercise.reps,
        'weight_kg': exercise.weightKg,
        'unit': exercise.unit.name,
        'per_side': exercise.perSide ? 1 : 0,
      });
    }
  }
}
