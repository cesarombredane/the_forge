import 'package:the_forge/data/local/app_database.dart';
import 'package:the_forge/data/models/training.dart';

class ExerciseLink {
  const ExerciseLink(
    this.table,
    this.id,
    this.parent,
    this.name,
    this.unit,
    this.mode,
  );
  final String table;
  final int id;
  final String parent;
  final String name;
  final ExerciseUnit unit;
  final WeightMode? mode;
}

class ExerciseRepository {
  ExerciseRepository({AppDatabase? appDatabase})
    : _database = appDatabase ?? AppDatabase.instance;
  final AppDatabase _database;

  Future<List<LibraryExercise>> getAll() async {
    final db = await _database.database;
    return (await db.query(
      'exercise_library',
      orderBy: 'name COLLATE NOCASE',
    )).map(LibraryExercise.fromMap).toList();
  }

  Future<int> save({
    int? id,
    required String name,
    required ExerciseUnit unit,
    required WeightMode mode,
  }) async {
    if (name.trim().isEmpty) throw ArgumentError('Enter an exercise name.');
    final db = await _database.database;
    return db.transaction((tx) async {
      final values = {
        'name': name.trim(),
        'name_key': exerciseKey(name),
        'unit': unit.name,
        'weight_mode': mode.name,
        'needs_review': 0,
      };
      final result = id ?? await tx.insert('exercise_library', values);
      if (id != null)
        await tx.update(
          'exercise_library',
          values,
          where: 'id = ?',
          whereArgs: [id],
        );
      // Resolve unclassified migration snapshots only. Later library edits must
      // not rewrite established historical measurement conventions.
      for (final table in ['template_exercises', 'workout_exercises']) {
        await tx.update(
          table,
          {'weight_mode': mode.name},
          where: 'library_id = ? AND weight_mode IS NULL AND unit = ?',
          whereArgs: [result, unit.name],
        );
      }
      return result;
    });
  }

  Future<void> setFlag(int id, {bool? archived, bool? tracked}) async {
    final db = await _database.database;
    await db.update(
      'exercise_library',
      {
        if (archived != null) 'archived': archived ? 1 : 0,
        if (tracked != null) 'tracked': tracked ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ExerciseLink>> links(int libraryId) async {
    final db = await _database.database;
    final result = <ExerciseLink>[];
    for (final source in [
      ('template_exercises', 'templates', 'template_id'),
      ('workout_exercises', 'workouts', 'workout_id'),
    ]) {
      final rows = await db.rawQuery(
        "SELECT e.*, p.title AS parent_title, ${source.$2 == 'workouts' ? 'p.scheduled_at' : 'NULL'} AS training_date FROM ${source.$1} e JOIN ${source.$2} p ON p.id = e.${source.$3} WHERE e.library_id = ? ORDER BY e.id",
        [libraryId],
      );
      for (final row in rows) {
        result.add(
          ExerciseLink(
            source.$1,
            row['id'] as int,
            '${source.$2 == 'templates' ? 'Template' : 'Workout ${row['training_date']}'}: ${row['parent_title']}',
            row['name'] as String,
            ExerciseUnit.values.byName(row['unit'] as String),
            row['weight_mode'] == null
                ? null
                : WeightMode.values.byName(row['weight_mode'] as String),
          ),
        );
      }
    }
    return result;
  }

  Future<void> relink(ExerciseLink link, LibraryExercise target) async {
    if (!['template_exercises', 'workout_exercises'].contains(link.table) ||
        link.unit != target.unit ||
        target.needsReview) {
      throw ArgumentError(
        'Choose a reviewed exercise with the same measurement unit.',
      );
    }
    final db = await _database.database;
    await db.transaction((tx) async {
      if (link.table == 'workout_exercises') {
        final active = await tx.rawQuery(
          '''SELECT w.id FROM workouts w
          JOIN workout_exercises e ON e.workout_id = w.id
          WHERE e.id = ? AND w.started_at IS NOT NULL AND w.status = 'planned'
          ''',
          [link.id],
        );
        if (active.isNotEmpty)
          throw StateError(
            'Finish the in-progress session before correcting its exercise links.',
          );
      }
      await tx.update(
        link.table,
        {'library_id': target.id, 'weight_mode': target.weightMode.name},
        where: 'id = ?',
        whereArgs: [link.id],
      );
    });
  }
}
