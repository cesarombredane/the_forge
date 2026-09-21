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
        sportDetails: template.sportDetails,
        exercises: template.exercises,
        cycleCount: template.cycleCount,
        targetDurationMinutes: template.sport == Sport.running
            ? template.durationMinutes
            : null,
        targetDistanceKm: template.sport == Sport.running
            ? template.distanceKm
            : null,
      );
      final values = workout.toMap()..remove('id');
      final workoutId = await transaction.insert('workouts', values);
      await _replaceExercises(transaction, workoutId, workout.exercises);
    });
  }

  Future<void> updateCompleted(Workout workout) async {
    if (workout.id == null || workout.status != WorkoutStatus.completed) {
      throw ArgumentError('An existing completed workout is required.');
    }
    if (workout.sport == Sport.gym)
      validateGymWorkout(workout, finishing: true);
    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final values = workout.toMap()
        ..remove('id')
        ..remove('template_id')
        ..remove('status')
        ..remove('completed_at')
        ..remove('target_duration_minutes')
        ..remove('target_distance_km')
        ..remove('started_at');
      final count = await transaction.update(
        'workouts',
        values,
        where: 'id = ? AND status = ?',
        whereArgs: [workout.id, WorkoutStatus.completed.name],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      if (count != 1) throw StateError('Completed workout no longer exists.');
      await _replaceExercises(transaction, workout.id!, workout.exercises);
    });
  }

  Future<void> startGym(int workoutId) async {
    final db = await _appDatabase.database;
    await db.transaction((tx) async {
      final rows = await tx.query(
        'workouts',
        where: 'id = ? AND sport = ? AND status = ?',
        whereArgs: [workoutId, 'gym', 'planned'],
      );
      if (rows.isEmpty)
        throw StateError('This gym workout is no longer planned.');
      if (rows.single['started_at'] != null) return;
      final exercises = await _getExercises(tx, workoutId);
      for (final exercise in exercises) {
        final library = await tx.query(
          'exercise_library',
          where: 'id = ?',
          whereArgs: [exercise.libraryId],
        );
        if (library.isEmpty ||
            library.single['needs_review'] == 1 ||
            exercise.weightMode == null) {
          throw StateError(
            'Review ${exercise.name} in Exercises before starting.',
          );
        }
      }
      final weights = await tx.query(
        'weight_entries',
        where: 'recorded_at <= ?',
        whereArgs: [DateTime.now().toIso8601String()],
        orderBy: 'recorded_at DESC',
        limit: 1,
      );
      final bodyweight = weights.isEmpty
          ? null
          : (weights.single['weight_kg'] as num).toDouble();
      if (bodyweight == null &&
          exercises.any((e) => e.weightMode == WeightMode.bodyweight)) {
        throw StateError('Record a bodyweight in Weight before starting.');
      }
      await tx.update(
        'workouts',
        {
          'started_at': DateTime.now().toIso8601String(),
          'body_weight_kg': bodyweight,
        },
        where: 'id = ?',
        whereArgs: [workoutId],
      );
    });
  }

  Future<void> saveGym(Workout workout, {bool finish = false}) async {
    validateGymWorkout(workout, finishing: finish);
    final db = await _appDatabase.database;
    await db.transaction((tx) async {
      final rows = await tx.query(
        'workouts',
        where: 'id = ? AND sport = ? AND status = ? AND started_at IS NOT NULL',
        whereArgs: [workout.id, 'gym', 'planned'],
      );
      if (rows.isEmpty)
        throw StateError('This session is no longer in progress.');
      if ((rows.single['body_weight_kg'] as num?)?.toDouble() !=
          workout.bodyWeightKg) {
        throw StateError('The session bodyweight snapshot is fixed.');
      }
      final original = await _getExercises(tx, workout.id!);
      if (original.length != workout.exercises.length)
        throw StateError('Session exercises are fixed.');
      for (var i = 0; i < original.length; i++) {
        if (original[i].libraryId != workout.exercises[i].libraryId ||
            original[i].unit != workout.exercises[i].unit ||
            original[i].weightMode != workout.exercises[i].weightMode ||
            original[i].prescribedSets.length !=
                workout.exercises[i].prescribedSets.length) {
          throw StateError('Session exercises and set counts are fixed.');
        }
      }
      await tx.update(
        'workouts',
        {
          'duration_minutes': workout.durationMinutes,
          'comment': workout.comment,
          if (finish) 'status': 'completed',
          if (finish) 'completed_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [workout.id],
      );
      await _replaceExercises(tx, workout.id!, workout.exercises);
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
    double? distanceKm,
  }) async {
    if (workout.sport == Sport.gym)
      throw StateError('Use Start workout for gym sessions.');
    if (workout.sport == Sport.running &&
        (distanceKm == null || !distanceKm.isFinite || distanceKm <= 0)) {
      throw ArgumentError('A positive actual running distance is required.');
    }
    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final count = await transaction.update(
        'workouts',
        {
          'status': WorkoutStatus.completed.name,
          'duration_minutes': durationMinutes,
          if (workout.sport == Sport.running) 'distance_km': distanceKm,
          'comment': comment,
          'completed_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ? AND status = ?',
        whereArgs: [workout.id, WorkoutStatus.planned.name],
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      if (count != 1) throw StateError('Planned workout no longer exists.');
      await _replaceExercises(transaction, workout.id!, exercises);
    });
  }

  Future<List<Exercise>> _getExercises(
    DatabaseExecutor database,
    int workoutId,
  ) async {
    final rows = await database.query(
      'workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'position',
    );
    final result = <Exercise>[];
    for (final row in rows) {
      final sets = await database.query(
        'gym_sets',
        where: 'exercise_id = ?',
        whereArgs: [row['id']],
        orderBy: 'position',
      );
      result.add(
        Exercise(
          name: row['name'] as String,
          sets: row['sets'] as int,
          reps: row['reps'] as int,
          weightKg: (row['weight_kg'] as num).toDouble(),
          unit: ExerciseUnit.values.byName(row['unit'] as String),
          perSide: row['per_side'] == 1,
          libraryId: row['library_id'] as int?,
          weightMode: row['weight_mode'] == null
              ? null
              : WeightMode.values.byName(row['weight_mode'] as String),
          workingSets: sets.map(WorkingSet.fromMap).toList(),
        ),
      );
    }
    return result;
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
      final exerciseId = await transaction.insert('workout_exercises', {
        'workout_id': workoutId,
        'library_id': exercise.libraryId,
        'weight_mode': exercise.weightMode?.name,
        'position': index,
        'name': exercise.name,
        'sets': exercise.sets,
        'reps': exercise.reps,
        'weight_kg': exercise.weightKg,
        'unit': exercise.unit.name,
        'per_side': exercise.perSide ? 1 : 0,
      });
      if (exercise.libraryId != null) {
        final sets = exercise.prescribedSets;
        for (var position = 0; position < sets.length; position++) {
          await transaction.insert('gym_sets', {
            'exercise_id': exerciseId,
            'position': position,
            ...sets[position].toMap(),
          });
        }
      }
    }
  }
}
