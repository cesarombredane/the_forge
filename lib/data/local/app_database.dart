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
      version: 2,
      onConfigure: (database) => database.execute('PRAGMA foreign_keys = ON'),
      onCreate: (database, version) async {
        await _createWorkouts(database);
        await _addTemplateSchema(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) await _addTemplateSchema(database);
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
}
