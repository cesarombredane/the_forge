import 'package:path/path.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    return openDatabase(
      join(await getDatabasesPath(), 'the_forge.db'),
      version: 11,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: (database, version) async {
        await _createWorkouts(database);
        await _addTemplateSchema(database);
        await _addWarmupAndExerciseOptions(database);
        await _addWeightSchema(database);
        await _addMobilityCycles(database);
        await _addStepsSchema(database);
        await _simplifyRunningSchema(database);
        await _addWeeklyRequirementsSchema(database);
        await _addRunningTargets(database);
        await _addGymProgression(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) await _addTemplateSchema(database);
        if (oldVersion < 3) await _addWarmupAndExerciseOptions(database);
        if (oldVersion < 4) await _addWeightSchema(database);
        if (oldVersion < 5) await _addMobilityCycles(database);
        if (oldVersion < 6) await _removeUnsupportedWorkoutSports(database);
        if (oldVersion < 7) await _addStepsSchema(database);
        if (oldVersion < 8) await _simplifyRunningSchema(database);
        if (oldVersion < 9) await _addWeeklyRequirementsSchema(database);
        if (oldVersion < 10) await _addRunningTargets(database);
        if (oldVersion < 11) await _addGymProgression(database);
      },
    );
  }

  Future<void> _createWorkouts(Database database) async {
    await database.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        sport TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL CHECK(duration_minutes > 0),
        details TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        status TEXT NOT NULL CHECK(status IN ('planned', 'completed')),
        comment TEXT NOT NULL DEFAULT '',
        completed_at TEXT
      )
    ''');
    await database.execute(
      'CREATE INDEX workout_schedule_index ON workouts(scheduled_at)',
    );
    await database.execute(
      'CREATE INDEX workout_status_index ON workouts(status)',
    );
  }

  Future<void> _addTemplateSchema(Database database) async {
    await database.execute('''
      CREATE TABLE templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        sport TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL CHECK(duration_minutes > 0),
        description TEXT NOT NULL DEFAULT '',
        hockey_type TEXT,
        distance_km REAL,
        cadence INTEGER,
        sport_details TEXT NOT NULL DEFAULT ''
      )
    ''');
    await database.execute('''
      CREATE TABLE template_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
        position INTEGER NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL CHECK(sets > 0),
        reps INTEGER NOT NULL CHECK(reps > 0),
        weight_kg REAL NOT NULL DEFAULT 0
      )
    ''');
    await database.execute('''
      CREATE TABLE workout_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
        position INTEGER NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL CHECK(sets > 0),
        reps INTEGER NOT NULL CHECK(reps > 0),
        weight_kg REAL NOT NULL DEFAULT 0
      )
    ''');
    await database.execute(
      'ALTER TABLE workouts ADD COLUMN template_id INTEGER',
    );
    await database.execute('ALTER TABLE workouts ADD COLUMN hockey_type TEXT');
    await database.execute('ALTER TABLE workouts ADD COLUMN distance_km REAL');
    await database.execute('ALTER TABLE workouts ADD COLUMN cadence INTEGER');
  }

  Future<void> _addWarmupAndExerciseOptions(Database database) async {
    await _addColumnIfMissing(
      database,
      table: 'templates',
      column: 'warmup',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      database,
      table: 'workouts',
      column: 'warmup',
      definition: "TEXT NOT NULL DEFAULT ''",
    );
    await _addColumnIfMissing(
      database,
      table: 'template_exercises',
      column: 'unit',
      definition: "TEXT NOT NULL DEFAULT 'reps'",
    );
    await _addColumnIfMissing(
      database,
      table: 'template_exercises',
      column: 'per_side',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _addColumnIfMissing(
      database,
      table: 'workout_exercises',
      column: 'unit',
      definition: "TEXT NOT NULL DEFAULT 'reps'",
    );
    await _addColumnIfMissing(
      database,
      table: 'workout_exercises',
      column: 'per_side',
      definition: 'INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _addWeightSchema(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS weight_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight_kg REAL NOT NULL CHECK(weight_kg > 0),
        recorded_at TEXT NOT NULL
      )
    ''');
    await database.execute('''
      CREATE INDEX IF NOT EXISTS weight_recorded_at_index
      ON weight_entries(recorded_at)
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS weight_reminder (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        weekday INTEGER NOT NULL CHECK(weekday BETWEEN 1 AND 7),
        hour INTEGER NOT NULL CHECK(hour BETWEEN 0 AND 23),
        minute INTEGER NOT NULL CHECK(minute BETWEEN 0 AND 59)
      )
    ''');
  }

  Future<void> _addMobilityCycles(Database database) async {
    await _addColumnIfMissing(
      database,
      table: 'templates',
      column: 'cycle_count',
      definition: 'INTEGER NOT NULL DEFAULT 1 CHECK(cycle_count > 0)',
    );
    await _addColumnIfMissing(
      database,
      table: 'workouts',
      column: 'cycle_count',
      definition: 'INTEGER NOT NULL DEFAULT 1 CHECK(cycle_count > 0)',
    );
    await database.update(
      'templates',
      {'warmup': ''},
      where: 'sport = ?',
      whereArgs: ['mobility'],
    );
    await database.update(
      'workouts',
      {'warmup': ''},
      where: 'sport = ?',
      whereArgs: ['mobility'],
    );
  }

  Future<void> _removeUnsupportedWorkoutSports(Database database) async {
    const supportedSports = ['gym', 'running', 'hockey', 'mobility'];
    final placeholders = List.filled(supportedSports.length, '?').join(', ');
    await database.delete(
      'workouts',
      where: 'sport NOT IN ($placeholders)',
      whereArgs: supportedSports,
    );
    await database.delete(
      'templates',
      where: 'sport NOT IN ($placeholders)',
      whereArgs: supportedSports,
    );
  }

  Future<void> _addStepsSchema(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS step_entries (
        day TEXT PRIMARY KEY,
        steps INTEGER NOT NULL CHECK(steps >= 0)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS step_settings (
        id INTEGER PRIMARY KEY CHECK(id = 1),
        daily_goal INTEGER NOT NULL CHECK(daily_goal > 0)
      )
    ''');
  }

  Future<void> _simplifyRunningSchema(Database database) async {
    await database.update(
      'templates',
      {'warmup': '', 'cadence': null, 'sport_details': ''},
      where: 'sport = ?',
      whereArgs: ['running'],
    );
    await database.update(
      'workouts',
      {'warmup': '', 'cadence': null, 'details': ''},
      where: 'sport = ?',
      whereArgs: ['running'],
    );
  }

  Future<void> _addWeeklyRequirementsSchema(Database database) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS weekly_requirements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_count INTEGER NOT NULL CHECK(target_count > 0)
      )
    ''');
    await database.execute('''
      CREATE TABLE IF NOT EXISTS weekly_requirement_templates (
        requirement_id INTEGER NOT NULL
          REFERENCES weekly_requirements(id) ON DELETE CASCADE,
        template_id INTEGER NOT NULL
          REFERENCES templates(id) ON DELETE CASCADE,
        PRIMARY KEY(requirement_id, template_id)
      )
    ''');
  }

  Future<void> _addRunningTargets(Database database) async {
    await _addColumnIfMissing(
      database,
      table: 'workouts',
      column: 'target_duration_minutes',
      definition: 'INTEGER CHECK(target_duration_minutes > 0)',
    );
    await _addColumnIfMissing(
      database,
      table: 'workouts',
      column: 'target_distance_km',
      definition: 'REAL CHECK(target_distance_km > 0)',
    );
    // Completed runs have already lost their original duration. Do not guess
    // their targets from a template that may have changed since scheduling.
    await database.execute('''UPDATE workouts
      SET target_duration_minutes = duration_minutes,
          target_distance_km = CASE WHEN distance_km > 0 THEN distance_km END
      WHERE sport = 'running' AND status = 'planned'
      ''');
  }

  Future<void> _addGymProgression(Database database) async {
    await database.execute('''CREATE TABLE exercise_library (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      name_key TEXT NOT NULL UNIQUE,
      unit TEXT NOT NULL CHECK(unit IN ('reps', 'seconds')),
      weight_mode TEXT NOT NULL CHECK(weight_mode IN ('external', 'bodyweight')),
      archived INTEGER NOT NULL DEFAULT 0,
      tracked INTEGER NOT NULL DEFAULT 0,
      needs_review INTEGER NOT NULL DEFAULT 0
    )''');
    for (final table in ['template_exercises', 'workout_exercises']) {
      await _addColumnIfMissing(
        database,
        table: table,
        column: 'library_id',
        definition: 'INTEGER REFERENCES exercise_library(id)',
      );
      await _addColumnIfMissing(
        database,
        table: table,
        column: 'weight_mode',
        definition: "TEXT CHECK(weight_mode IN ('external', 'bodyweight'))",
      );
    }
    await _addColumnIfMissing(
      database,
      table: 'workouts',
      column: 'started_at',
      definition: 'TEXT',
    );
    await _addColumnIfMissing(
      database,
      table: 'workouts',
      column: 'body_weight_kg',
      definition: 'REAL CHECK(body_weight_kg > 0)',
    );
    await database.execute('''CREATE TABLE gym_sets (
      exercise_id INTEGER NOT NULL REFERENCES workout_exercises(id) ON DELETE CASCADE,
      position INTEGER NOT NULL,
      amount INTEGER NOT NULL CHECK(amount >= 0),
      weight_kg REAL NOT NULL,
      confirmed INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY(exercise_id, position)
    )''');
    final identities = <String, int>{};
    for (final source in [
      ('template_exercises', 'templates', 'template_id'),
      ('workout_exercises', 'workouts', 'workout_id'),
    ]) {
      final rows = await database.rawQuery(
        "SELECT e.* FROM ${source.$1} e JOIN ${source.$2} p ON p.id = e.${source.$3} WHERE p.sport = 'gym' ORDER BY e.id",
      );
      for (final row in rows) {
        final name = row['name'] as String;
        final key = exerciseKey(name);
        final id =
            identities[key] ??
            await database.insert('exercise_library', {
              'name': name.trim(), 'name_key': key, 'unit': row['unit'],
              // Old positive values may be added bodyweight load. Ask the owner
              // to confirm the mode instead of guessing from a name.
              'weight_mode': (row['weight_kg'] as num) <= 0
                  ? 'bodyweight'
                  : 'external',
              'needs_review': 1,
            });
        identities[key] = id;
        await database.update(
          source.$1,
          {'library_id': id},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
    await database.execute('''UPDATE workouts SET body_weight_kg = (
      SELECT weight_kg FROM weight_entries
      WHERE recorded_at <= workouts.scheduled_at ORDER BY recorded_at DESC LIMIT 1
    ) WHERE sport = 'gym' AND status = 'completed'
    ''');
    final rows = await database.rawQuery(
      '''SELECT e.*, w.status FROM workout_exercises e
      JOIN workouts w ON w.id = e.workout_id WHERE w.sport = 'gym'
    ''',
    );
    for (final row in rows) {
      for (var index = 0; index < (row['sets'] as int); index++) {
        await database.insert('gym_sets', {
          'exercise_id': row['id'],
          'position': index,
          'amount': row['reps'],
          'weight_kg': row['weight_kg'],
          'confirmed': row['status'] == 'completed' ? 1 : 0,
        });
      }
    }
  }

  Future<void> _addColumnIfMissing(
    Database database, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final columns = await database.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((row) => row['name'] == column);
    if (!exists) {
      await database.execute(
        'ALTER TABLE $table ADD COLUMN $column $definition',
      );
    }
  }
}
