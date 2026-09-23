import 'dart:convert';
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
    if (workout.sport == Sport.mobility)
      validateMobilityWorkout(workout, finishing: true, allowUnknown: true);
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
      if (workout.sport == Sport.hockey &&
          workout.hockeyType == HockeySessionType.tournament) {
        final totals = await transaction.rawQuery(
          'SELECT SUM(duration_minutes) AS total FROM hockey_games WHERE workout_id = ?',
          [workout.id],
        );
        final total = totals.single['total'] as int?;
        if (total != null)
          await transaction.update(
            'workouts',
            {'duration_minutes': total},
            where: 'id = ?',
            whereArgs: [workout.id],
          );
      }
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
      await _backup(tx, rows.single, exercises);
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
      if (finish) await _propagateGymPrescriptions(tx, workout);
      if (finish)
        await tx.delete(
          'session_backups',
          where: 'workout_id = ?',
          whereArgs: [workout.id],
        );
    });
  }

  Future<void> _propagateGymPrescriptions(
    Transaction tx,
    Workout workout,
  ) async {
    final seen = <int>{};
    for (final exercise in workout.exercises) {
      final id = exercise.libraryId;
      // The first occurrence owns the reference, even when its first set is skipped.
      if (id == null || !seen.add(id) || exercise.weightMode == null) continue;
      final first = exercise.workingSets.firstOrNull;
      if (first == null || !first.confirmed || first.amount <= 0) continue;
      final match = [id, exercise.unit.name, exercise.weightMode!.name];
      final values = {'reps': first.amount, 'weight_kg': first.weightKg};
      await tx.update(
        'template_exercises',
        values,
        where:
            "library_id = ? AND unit = ? AND weight_mode = ? AND template_id IN (SELECT id FROM templates WHERE sport = 'gym')",
        whereArgs: match,
      );
      const eligible =
          "library_id = ? AND unit = ? AND weight_mode = ? AND workout_id IN (SELECT id FROM workouts WHERE sport = 'gym' AND status = 'planned' AND started_at IS NULL)";
      // Update both the prescription and its prefilled sets without changing structure.
      await tx.rawUpdate(
        'UPDATE gym_sets SET amount = ?, weight_kg = ?, confirmed = 0 WHERE exercise_id IN (SELECT id FROM workout_exercises WHERE $eligible)',
        [first.amount, first.weightKg, ...match],
      );
      await tx.update(
        'workout_exercises',
        values,
        where: eligible,
        whereArgs: match,
      );
    }
  }

  Future<void> _backup(
    Transaction tx,
    Map<String, Object?> row,
    List<Exercise> exercises,
  ) async {
    final data = {
      'duration_minutes': row['duration_minutes'],
      'comment': row['comment'],
      'body_weight_kg': row['body_weight_kg'],
      'exercises': [
        for (final e in exercises)
          {
            'name': e.name,
            'sets': e.sets,
            'reps': e.reps,
            'weight_kg': e.weightKg,
            'unit': e.unit.name,
            'per_side': e.perSide,
            'library_id': e.libraryId,
            'weight_mode': e.weightMode?.name,
            'results': [for (final result in e.workingSets) result.toMap()],
          },
      ],
    };
    await tx.insert('session_backups', {
      'workout_id': row['id'],
      'snapshot': jsonEncode(data),
    });
  }

  Future<void> cancelSession(int id) async {
    final db = await _appDatabase.database;
    await db.transaction((tx) async {
      final rows = await tx.query(
        'workouts',
        where:
            "id = ? AND status = 'planned' AND sport IN ('gym','mobility') AND started_at IS NOT NULL",
        whereArgs: [id],
      );
      if (rows.isEmpty)
        throw StateError('This session is no longer in progress.');
      final backups = await tx.query(
        'session_backups',
        where: 'workout_id = ?',
        whereArgs: [id],
      );
      List<Exercise> exercises;
      final values = <String, Object?>{
        'started_at': null,
        'body_weight_kg': null,
        'comment': '',
      };
      if (backups.isNotEmpty) {
        final data =
            jsonDecode(backups.single['snapshot'] as String)
                as Map<String, dynamic>;
        for (final key in ['duration_minutes', 'comment', 'body_weight_kg']) {
          values[key] = data[key];
        }
        exercises = (data['exercises'] as List).map((raw) {
          final e = raw as Map<String, dynamic>;
          return Exercise(
            name: e['name'],
            sets: e['sets'],
            reps: e['reps'],
            weightKg: (e['weight_kg'] as num).toDouble(),
            unit: ExerciseUnit.values.byName(e['unit']),
            perSide: e['per_side'],
            libraryId: e['library_id'],
            weightMode: e['weight_mode'] == null
                ? null
                : WeightMode.values.byName(e['weight_mode']),
            workingSets: (e['results'] as List)
                .map((r) => WorkingSet.fromMap(Map<String, Object?>.from(r)))
                .toList(),
          );
        }).toList();
      } else {
        // Version-12 sessions have no pre-start duration snapshot.
        exercises = (await _getExercises(tx, id))
            .map(
              (e) => e.copyWith(
                workingSets: List.generate(
                  e.sets,
                  (_) => WorkingSet(amount: e.reps, weightKg: e.weightKg),
                ),
              ),
            )
            .toList();
      }
      await tx.update('workouts', values, where: 'id = ?', whereArgs: [id]);
      await _replaceExercises(tx, id, exercises);
      await tx.delete(
        'session_backups',
        where: 'workout_id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> startMobility(int id) async {
    final db = await _appDatabase.database;
    await db.transaction((tx) async {
      final rows = await tx.query(
        'workouts',
        where: "id = ? AND sport = 'mobility' AND status = 'planned'",
        whereArgs: [id],
      );
      if (rows.isEmpty) throw StateError('This routine is no longer planned.');
      final row = rows.single;
      if (row['started_at'] != null) return;
      final exercises = await _getExercises(tx, id);
      if (exercises.isEmpty)
        throw StateError('The routine needs at least one movement.');
      await _backup(tx, row, exercises);
      await _replaceExercises(
        tx,
        id,
        exercises
            .map(
              (e) => e.copyWith(
                workingSets: List.generate(
                  row['cycle_count'] as int,
                  (_) => WorkingSet(amount: e.reps, weightKg: 0),
                ),
              ),
            )
            .toList(),
      );
      await tx.update(
        'workouts',
        {'started_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> saveMobility(Workout workout, {bool finish = false}) async {
    validateMobilityWorkout(workout, finishing: finish);
    final db = await _appDatabase.database;
    await db.transaction((tx) async {
      final rows = await tx.query(
        'workouts',
        where:
            "id = ? AND sport = 'mobility' AND status = 'planned' AND started_at IS NOT NULL",
        whereArgs: [workout.id],
      );
      if (rows.isEmpty)
        throw StateError('This routine is no longer in progress.');
      final old = await _getExercises(tx, workout.id!);
      if (old.length != workout.exercises.length ||
          rows.single['cycle_count'] != workout.cycleCount)
        throw StateError('Movements and cycles are fixed.');
      for (var i = 0; i < old.length; i++) {
        final next = workout.exercises[i];
        if (old[i].name != next.name ||
            old[i].unit != next.unit ||
            old[i].perSide != next.perSide ||
            old[i].reps != next.reps)
          throw StateError('Movement prescriptions are fixed.');
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
      if (finish)
        await tx.delete(
          'session_backups',
          where: 'workout_id = ?',
          whereArgs: [workout.id],
        );
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
    if (workout.sport == Sport.gym || workout.sport == Sport.mobility)
      throw StateError('Use the start/resume session workflow.');
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
      final cycles = await database.query(
        'mobility_cycles',
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
          workingSets: cycles.isNotEmpty
              ? cycles
                    .map(
                      (r) => WorkingSet(
                        amount: r['amount'] as int,
                        weightKg: 0,
                        confirmed: r['confirmed'] == 1,
                      ),
                    )
                    .toList()
              : sets.map(WorkingSet.fromMap).toList(),
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
    final parent = await transaction.query(
      'workouts',
      columns: ['sport'],
      where: 'id = ?',
      whereArgs: [workoutId],
    );
    final sport = parent.single['sport'];
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
      if (sport == 'mobility' && exercise.workingSets.isNotEmpty) {
        for (
          var position = 0;
          position < exercise.workingSets.length;
          position++
        ) {
          final value = exercise.workingSets[position];
          await transaction.insert('mobility_cycles', {
            'exercise_id': exerciseId,
            'position': position,
            'amount': value.amount,
            'confirmed': value.confirmed ? 1 : 0,
          });
        }
      }
      if (sport == 'gym') {
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
