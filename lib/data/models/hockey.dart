import 'training.dart';

class Opponent {
  const Opponent({required this.id, required this.name, this.deleted = false});
  final int id;
  final String name;
  final bool deleted;
  factory Opponent.fromMap(Map<String, Object?> row) => Opponent(
    id: row['id'] as int,
    name: row['name'] as String,
    deleted: row['deleted'] == 1,
  );
}

class HockeyStats {
  const HockeyStats({
    required this.goals,
    required this.assists,
    required this.plusMinus,
  });
  final int goals;
  final int assists;
  final int plusMinus;
  int get points => goals + assists;
  Map<String, Object?> toMap() => {
    'goals': goals,
    'assists': assists,
    'plus_minus': plusMinus,
  };
  factory HockeyStats.fromMap(Map<String, Object?> row) => HockeyStats(
    goals: row['goals'] as int,
    assists: row['assists'] as int,
    plusMinus: row['plus_minus'] as int,
  );
  void validate() {
    if (goals < 0 || assists < 0)
      throw ArgumentError('Goals and assists must be 0 or more.');
  }
}

class HockeyRecord {
  const HockeyRecord({required this.workoutId, this.opponentId, this.stats});
  final int workoutId;
  final int? opponentId;
  final HockeyStats? stats;
  factory HockeyRecord.fromMap(Map<String, Object?> row) => HockeyRecord(
    workoutId: row['workout_id'] as int,
    opponentId: row['opponent_id'] as int?,
    stats: row['goals'] == null ? null : HockeyStats.fromMap(row),
  );
}

class TournamentGame {
  const TournamentGame({
    this.id,
    required this.workoutId,
    required this.opponentId,
    required this.playedAt,
    required this.durationMinutes,
    required this.stats,
  });
  final int? id;
  final int workoutId;
  final int opponentId;
  final DateTime playedAt;
  final int durationMinutes;
  final HockeyStats stats;
  Map<String, Object?> toMap() => {
    'workout_id': workoutId,
    'opponent_id': opponentId,
    'played_at': playedAt.toIso8601String(),
    'duration_minutes': durationMinutes,
    ...stats.toMap(),
  };
  factory TournamentGame.fromMap(Map<String, Object?> row) => TournamentGame(
    id: row['id'] as int,
    workoutId: row['workout_id'] as int,
    opponentId: row['opponent_id'] as int,
    playedAt: DateTime.parse(row['played_at'] as String),
    durationMinutes: row['duration_minutes'] as int,
    stats: HockeyStats.fromMap(row),
  );
}

class HockeyPerformance {
  const HockeyPerformance({
    required this.key,
    required this.date,
    required this.title,
    required this.opponentId,
    required this.stats,
  });
  final String key;
  final DateTime date;
  final String title;
  final int? opponentId;
  final HockeyStats stats;
}

DateTime hockeySeasonStart(DateTime now) =>
    DateTime(now.month >= 9 ? now.year : now.year - 1, 9);

List<HockeyPerformance> hockeyPerformance(
  List<Workout> workouts,
  List<HockeyRecord> records,
  List<TournamentGame> games, {
  DateTime? seasonStart,
}) {
  final byId = {for (final w in workouts) w.id: w};
  final result = <HockeyPerformance>[];
  for (final record in records) {
    final w = byId[record.workoutId];
    if (w == null ||
        w.sport != Sport.hockey ||
        w.status != WorkoutStatus.completed ||
        w.hockeyType == HockeySessionType.coaching ||
        w.hockeyType == HockeySessionType.tournament ||
        record.stats == null)
      continue;
    result.add(
      HockeyPerformance(
        key: 'workout:${w.id}',
        date: w.scheduledAt,
        title: w.title,
        opponentId: record.opponentId,
        stats: record.stats!,
      ),
    );
  }
  for (final game in games) {
    final w = byId[game.workoutId];
    if (w == null ||
        w.sport != Sport.hockey ||
        w.hockeyType != HockeySessionType.tournament)
      continue;
    result.add(
      HockeyPerformance(
        key: 'game:${game.id}',
        date: game.playedAt,
        title: '${w.title} · game',
        opponentId: game.opponentId,
        stats: game.stats,
      ),
    );
  }
  final end = seasonStart == null ? null : DateTime(seasonStart.year + 1, 9);
  result.removeWhere(
    (p) =>
        seasonStart != null &&
        (p.date.isBefore(seasonStart) || !p.date.isBefore(end!)),
  );
  result.sort((a, b) {
    final date = a.date.compareTo(b.date);
    return date != 0 ? date : a.key.compareTo(b.key);
  });
  return result;
}

HockeyStats sumHockeyStats(Iterable<HockeyStats> values) => values.fold(
  const HockeyStats(goals: 0, assists: 0, plusMinus: 0),
  (a, b) => HockeyStats(
    goals: a.goals + b.goals,
    assists: a.assists + b.assists,
    plusMinus: a.plusMinus + b.plusMinus,
  ),
);
String signedHockey(int value) => value > 0 ? '+$value' : '$value';
