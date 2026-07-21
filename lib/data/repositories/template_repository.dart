import 'package:sqflite/sqflite.dart';
import 'package:the_forge/data/local/app_database.dart';
import 'package:the_forge/data/models/training.dart';

class TemplateRepository {
  TemplateRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<List<WorkoutTemplate>> getAll() async {
    final database = await _appDatabase.database;
    final rows = await database.query('templates', orderBy: 'sport, title');
    final templates = <WorkoutTemplate>[];
    for (final row in rows) {
      templates.add(
        WorkoutTemplate.fromMap(
          row,
          exercises: await _getExercises(database, row['id'] as int),
        ),
      );
    }
    return templates;
  }

  Future<void> save(WorkoutTemplate template) async {
    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final values = template.toMap()..remove('id');
      final id = template.id == null
          ? await transaction.insert('templates', values)
          : template.id!;
      if (template.id != null) {
        await transaction.update(
          'templates',
          values,
          where: 'id = ?',
          whereArgs: [id],
        );
        await transaction.delete(
          'template_exercises',
          where: 'template_id = ?',
          whereArgs: [id],
        );
      }
      await _insertExercises(transaction, id, template.exercises);
    });
  }

  Future<void> delete(int id) async {
    final database = await _appDatabase.database;
    await database.delete('templates', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Exercise>> _getExercises(
    Database database,
    int templateId,
  ) async {
    final rows = await database.query(
      'template_exercises',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'position',
    );
    return rows
        .map(
          (row) => Exercise(
            name: row['name'] as String,
            sets: row['sets'] as int,
            reps: row['reps'] as int,
            weightKg: (row['weight_kg'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<void> _insertExercises(
    Transaction transaction,
    int templateId,
    List<Exercise> exercises,
  ) async {
    for (var index = 0; index < exercises.length; index++) {
      final exercise = exercises[index];
      await transaction.insert('template_exercises', {
        'template_id': templateId,
        'position': index,
        'name': exercise.name,
        'sets': exercise.sets,
        'reps': exercise.reps,
        'weight_kg': exercise.weightKg,
      });
    }
  }
}
