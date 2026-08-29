import 'package:sqflite/sqflite.dart';
import 'package:the_forge/data/local/app_database.dart';
import 'package:the_forge/data/models/training.dart';

class StepRepository {
  StepRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<List<StepEntry>> getAll() async {
    final database = await _appDatabase.database;
    final rows = await database.query('step_entries', orderBy: 'day DESC');
    return rows.map(StepEntry.fromMap).toList();
  }

  Future<void> save(DateTime day, int steps) async {
    final database = await _appDatabase.database;
    await database.insert('step_entries', {
      'day': _dateKey(day),
      'steps': steps,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int?> getDailyGoal() async {
    final database = await _appDatabase.database;
    final rows = await database.query('step_settings', limit: 1);
    return rows.isEmpty ? null : rows.first['daily_goal'] as int;
  }

  Future<void> saveDailyGoal(int dailyGoal) async {
    final database = await _appDatabase.database;
    await database.insert('step_settings', {
      'id': 1,
      'daily_goal': dailyGoal,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

String _dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
