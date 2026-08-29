import 'package:sqflite/sqflite.dart';
import 'package:the_forge/data/local/app_database.dart';
import 'package:the_forge/data/models/training.dart';

class WeightRepository {
  WeightRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<List<WeightEntry>> getAll() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      'weight_entries',
      orderBy: 'recorded_at DESC',
    );
    return rows.map(WeightEntry.fromMap).toList();
  }

  Future<void> add(double weightKg, DateTime recordedAt) async {
    final database = await _appDatabase.database;
    await database.insert('weight_entries', {
      'weight_kg': weightKg,
      'recorded_at': recordedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<void> delete(int id) async {
    final database = await _appDatabase.database;
    await database.delete('weight_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<WeightReminder?> getReminder() async {
    final database = await _appDatabase.database;
    final rows = await database.query('weight_reminder', limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return WeightReminder(
      weekday: row['weekday'] as int,
      hour: row['hour'] as int,
      minute: row['minute'] as int,
    );
  }

  Future<void> saveReminder(WeightReminder reminder) async {
    final database = await _appDatabase.database;
    await database.insert('weight_reminder', {
      'id': 1,
      'weekday': reminder.weekday,
      'hour': reminder.hour,
      'minute': reminder.minute,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeReminder() async {
    final database = await _appDatabase.database;
    await database.delete('weight_reminder');
  }
}
