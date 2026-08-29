import 'package:the_forge/data/local/app_database.dart';
import 'package:the_forge/data/models/training.dart';

class WeeklyRequirementRepository {
  WeeklyRequirementRepository({AppDatabase? appDatabase})
    : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  Future<List<WeeklyRequirement>> getAll() async {
    final database = await _appDatabase.database;
    final rows = await database.query('weekly_requirements', orderBy: 'name');
    final requirements = <WeeklyRequirement>[];
    for (final row in rows) {
      final links = await database.query(
        'weekly_requirement_templates',
        columns: ['template_id'],
        where: 'requirement_id = ?',
        whereArgs: [row['id']],
      );
      requirements.add(
        WeeklyRequirement(
          id: row['id'] as int,
          name: row['name'] as String,
          targetCount: row['target_count'] as int,
          templateIds: links.map((link) => link['template_id'] as int).toList(),
        ),
      );
    }
    return requirements;
  }

  Future<void> save(WeeklyRequirement requirement) async {
    final database = await _appDatabase.database;
    await database.transaction((transaction) async {
      final values = {
        'name': requirement.name,
        'target_count': requirement.targetCount,
      };
      final id = requirement.id == null
          ? await transaction.insert('weekly_requirements', values)
          : requirement.id!;
      if (requirement.id != null) {
        await transaction.update(
          'weekly_requirements',
          values,
          where: 'id = ?',
          whereArgs: [id],
        );
        await transaction.delete(
          'weekly_requirement_templates',
          where: 'requirement_id = ?',
          whereArgs: [id],
        );
      }
      for (final templateId in requirement.templateIds) {
        await transaction.insert('weekly_requirement_templates', {
          'requirement_id': id,
          'template_id': templateId,
        });
      }
    });
  }

  Future<void> delete(int id) async {
    final database = await _appDatabase.database;
    await database.delete(
      'weekly_requirements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
