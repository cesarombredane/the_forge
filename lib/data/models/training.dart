enum Sport { gym, running, walking, hockey, mobility }

enum HockeySessionType {
  championship,
  friendly,
  training,
  coaching,
  tournament,
}

enum WorkoutStatus { planned, completed }

class Exercise {
  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weightKg,
  });

  final String name;
  final int sets;
  final int reps;
  final double weightKg;

  Exercise copyWith({String? name, int? sets, int? reps, double? weightKg}) {
    return Exercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
    );
  }
}

class WorkoutTemplate {
  const WorkoutTemplate({
    this.id,
    required this.title,
    required this.sport,
    required this.durationMinutes,
    required this.description,
    this.hockeyType,
    this.distanceKm,
    this.cadence,
    this.sportDetails = '',
    this.exercises = const [],
  });

  final int? id;
  final String title;
  final Sport sport;
  final int durationMinutes;
  final String description;
  final HockeySessionType? hockeyType;
  final double? distanceKm;
  final int? cadence;
  final String sportDetails;
  final List<Exercise> exercises;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'sport': sport.name,
    'duration_minutes': durationMinutes,
    'description': description,
    'hockey_type': hockeyType?.name,
    'distance_km': distanceKm,
    'cadence': cadence,
    'sport_details': sportDetails,
  };

  factory WorkoutTemplate.fromMap(
    Map<String, Object?> map, {
    List<Exercise> exercises = const [],
  }) {
    return WorkoutTemplate(
      id: map['id'] as int,
      title: map['title'] as String,
      sport: Sport.values.byName(map['sport'] as String),
      durationMinutes: map['duration_minutes'] as int,
      description: map['description'] as String,
      hockeyType: map['hockey_type'] == null
          ? null
          : HockeySessionType.values.byName(map['hockey_type'] as String),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      cadence: map['cadence'] as int?,
      sportDetails: map['sport_details'] as String,
      exercises: exercises,
    );
  }
}

class Workout {
  const Workout({
    this.id,
    this.templateId,
    required this.title,
    required this.sport,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.description,
    required this.status,
    this.hockeyType,
    this.distanceKm,
    this.cadence,
    this.sportDetails = '',
    this.exercises = const [],
    this.comment = '',
    this.completedAt,
  });

  final int? id;
  final int? templateId;
  final String title;
  final Sport sport;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String description;
  final WorkoutStatus status;
  final HockeySessionType? hockeyType;
  final double? distanceKm;
  final int? cadence;
  final String sportDetails;
  final List<Exercise> exercises;
  final String comment;
  final DateTime? completedAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'template_id': templateId,
    'title': title,
    'sport': sport.name,
    'scheduled_at': scheduledAt.toIso8601String(),
    'duration_minutes': durationMinutes,
    'notes': description,
    'details': sportDetails,
    'status': status.name,
    'comment': comment,
    'completed_at': completedAt?.toIso8601String(),
    'hockey_type': hockeyType?.name,
    'distance_km': distanceKm,
    'cadence': cadence,
  };

  factory Workout.fromMap(
    Map<String, Object?> map, {
    List<Exercise> exercises = const [],
  }) {
    return Workout(
      id: map['id'] as int,
      templateId: map['template_id'] as int?,
      title: map['title'] as String,
      sport: Sport.values.byName(map['sport'] as String),
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      durationMinutes: map['duration_minutes'] as int,
      description: map['notes'] as String,
      status: WorkoutStatus.values.byName(map['status'] as String),
      hockeyType: map['hockey_type'] == null
          ? null
          : HockeySessionType.values.byName(map['hockey_type'] as String),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      cadence: map['cadence'] as int?,
      sportDetails: map['details'] as String,
      exercises: exercises,
      comment: map['comment'] as String,
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
    );
  }
}

extension SportLabel on Sport {
  String get label => switch (this) {
    Sport.gym => 'Gym',
    Sport.running => 'Running',
    Sport.walking => 'Walking',
    Sport.hockey => 'Hockey',
    Sport.mobility => 'Mobility',
  };
}

extension HockeySessionTypeLabel on HockeySessionType {
  String get label => switch (this) {
    HockeySessionType.championship => 'Championship game',
    HockeySessionType.friendly => 'Friendly game',
    HockeySessionType.training => 'Training',
    HockeySessionType.coaching => 'Coaching',
    HockeySessionType.tournament => 'Tournament',
  };
}
