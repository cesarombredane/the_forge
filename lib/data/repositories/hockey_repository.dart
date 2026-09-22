import 'package:sqflite/sqflite.dart';
import 'package:the_forge/data/local/app_database.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:the_forge/data/models/hockey.dart';

class HockeyRepository {
  HockeyRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;
  final AppDatabase _database;
  Future<List<Opponent>> opponents() async =>
      (await (await _database.database).query(
        'hockey_opponents',
        orderBy: 'name COLLATE NOCASE, id',
      )).map(Opponent.fromMap).toList();
  Future<List<HockeyRecord>> records() async =>
      (await (await _database.database).query(
        'hockey_records',
      )).map(HockeyRecord.fromMap).toList();
  Future<List<TournamentGame>> games() async =>
      (await (await _database.database).query(
        'hockey_games',
        orderBy: 'played_at, id',
      )).map(TournamentGame.fromMap).toList();
  Future<int> saveOpponent(String name, {int? id}) async {
    if (name.trim().isEmpty) throw ArgumentError('Enter an opponent name.');
    final db = await _database.database;
    final values = {'name': name.trim(), 'name_key': exerciseKey(name)};
    if (id == null) return db.insert('hockey_opponents', values);
    await db.update(
      'hockey_opponents',
      values,
      where: 'id = ?',
      whereArgs: [id],
    );
    return id;
  }

  Future<void> deleteOpponent(int id) async =>
      (await _database.database).update(
        'hockey_opponents',
        {'deleted': 1},
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<void> _opponent(Transaction tx, int? id, int? previous) async {
    if (id == null) return;
    final rows = await tx.query(
      'hockey_opponents',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty || (rows.single['deleted'] == 1 && id != previous))
      throw StateError('Select an available opponent.');
  }

  Future<void> saveSession(
    Workout workout, {
    required int? opponentId,
    required HockeyStats? stats,
  }) async {
    if (workout.durationMinutes <= 0)
      throw ArgumentError('Enter a positive duration.');
    stats?.validate();
    final db = await _database.database;
    await db.transaction((tx) async {
      final rows = await tx.query(
        'workouts',
        where: 'id = ? AND sport = ?',
        whereArgs: [workout.id, 'hockey'],
      );
      if (rows.isEmpty) throw StateError('Hockey session no longer exists.');
      final stored = rows.single;
      final type = stored['hockey_type'];
      if (type == 'tournament')
        throw StateError('Use the tournament game editor.');
      final requiredStats = type == 'championship' || type == 'friendly';
      if (requiredStats && (stats == null || opponentId == null))
        throw ArgumentError('Games require an opponent and all statistics.');
      if (type == 'coaching' && (stats != null || opponentId != null))
        throw ArgumentError('Coaching records duration and notes only.');
      final previous = await tx.query(
        'hockey_records',
        where: 'workout_id = ?',
        whereArgs: [workout.id],
      );
      await _opponent(
        tx,
        opponentId,
        previous.firstOrNull?['opponent_id'] as int?,
      );
      await tx.insert('hockey_records', {
        'workout_id': workout.id,
        'opponent_id': opponentId,
        'goals': stats?.goals,
        'assists': stats?.assists,
        'plus_minus': stats?.plusMinus,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      await tx.update(
        'workouts',
        {
          'duration_minutes': workout.durationMinutes,
          'comment': workout.comment,
          'status': 'completed',
          if (stored['status'] != 'completed')
            'completed_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [workout.id],
      );
    });
  }

  Future<Map<String, Object?>> _tournament(Transaction tx, int id) async {
    final rows = await tx.query(
      'workouts',
      where: 'id = ? AND sport = ? AND hockey_type = ?',
      whereArgs: [id, 'hockey', 'tournament'],
    );
    if (rows.isEmpty) throw StateError('Tournament no longer exists.');
    return rows.single;
  }

  Future<void> _duration(Transaction tx, int id) async {
    final rows = await tx.rawQuery(
      'SELECT SUM(duration_minutes) AS total FROM hockey_games WHERE workout_id = ?',
      [id],
    );
    final total = rows.single['total'] as int?;
    if (total != null)
      await tx.update(
        'workouts',
        {'duration_minutes': total},
        where: 'id = ?',
        whereArgs: [id],
      );
  }

  Future<void> saveGame(TournamentGame game) async {
    game.stats.validate();
    if (game.durationMinutes <= 0)
      throw ArgumentError('Enter a positive game duration.');
    final db = await _database.database;
    await db.transaction((tx) async {
      await _tournament(tx, game.workoutId);
      final old = game.id == null
          ? <Map<String, Object?>>[]
          : await tx.query(
              'hockey_games',
              where: 'id = ? AND workout_id = ?',
              whereArgs: [game.id, game.workoutId],
            );
      if (game.id != null && old.isEmpty)
        throw StateError('Game no longer exists.');
      await _opponent(
        tx,
        game.opponentId,
        old.firstOrNull?['opponent_id'] as int?,
      );
      if (game.id == null) {
        await tx.insert('hockey_games', game.toMap());
      } else {
        await tx.update(
          'hockey_games',
          game.toMap(),
          where: 'id = ?',
          whereArgs: [game.id],
        );
      }
      await _duration(tx, game.workoutId);
    });
  }

  Future<void> deleteGame(TournamentGame game) async {
    final db = await _database.database;
    await db.transaction((tx) async {
      final parent = await _tournament(tx, game.workoutId);
      final rows = await tx.query(
        'hockey_games',
        where: 'workout_id = ?',
        whereArgs: [game.workoutId],
      );
      if (parent['status'] == 'completed' && rows.length <= 1)
        throw StateError('A completed tournament must keep at least one game.');
      await tx.delete(
        'hockey_games',
        where: 'id = ? AND workout_id = ?',
        whereArgs: [game.id, game.workoutId],
      );
      await _duration(tx, game.workoutId);
    });
  }

  Future<void> saveTournament(
    int id,
    String comment, {
    bool finish = false,
  }) async {
    final db = await _database.database;
    await db.transaction((tx) async {
      final parent = await _tournament(tx, id);
      final games = await tx.query(
        'hockey_games',
        where: 'workout_id = ?',
        whereArgs: [id],
      );
      if (finish && games.isEmpty)
        throw StateError('Save at least one game before finishing.');
      await _duration(tx, id);
      await tx.update(
        'workouts',
        {
          'comment': comment,
          if (finish) 'status': 'completed',
          if (finish && parent['status'] != 'completed')
            'completed_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }
}
