import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    return openDatabase(
      join(await getDatabasesPath(), 'the_forge.db'),
      version: 9,
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
