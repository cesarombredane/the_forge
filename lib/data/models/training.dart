enum Sport { gym, running, hockey, mobility }

enum HockeySessionType {
  championship,
  friendly,
  training,
  coaching,
  tournament,
}

enum WorkoutStatus { planned, completed }

enum ExerciseUnit { reps, seconds }

class WeightEntry {
  const WeightEntry({
    this.id,
    required this.weightKg,
    required this.recordedAt,
  });

  final int? id;
  final double weightKg;
  final DateTime recordedAt;

  factory WeightEntry.fromMap(Map<String, Object?> map) => WeightEntry(
    id: map['id'] as int,
    weightKg: (map['weight_kg'] as num).toDouble(),
    recordedAt: DateTime.parse(map['recorded_at'] as String),
  );
}

class WeightReminder {
  const WeightReminder({
    required this.weekday,
    required this.hour,
    required this.minute,
  });

  final int weekday;
  final int hour;
  final int minute;

  DateTime scheduledOn(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);
}

class StepEntry {
  const StepEntry({required this.day, required this.steps});

  final DateTime day;
  final int steps;

  factory StepEntry.fromMap(Map<String, Object?> map) => StepEntry(
    day: DateTime.parse(map['day'] as String),
    steps: map['steps'] as int,
  );
}

class WeeklyRequirement {
  const WeeklyRequirement({
    this.id,
    required this.name,
    required this.targetCount,
    required this.templateIds,
  });

  final int? id;
  final String name;
  final int targetCount;
  final List<int> templateIds;
}

class Exercise {
  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weightKg,
    this.unit = ExerciseUnit.reps,
    this.perSide = false,
  });

  final String name;
  final int sets;
  final int reps;
  final double weightKg;
  final ExerciseUnit unit;
  final bool perSide;

  Exercise copyWith({
    String? name,
    int? sets,
    int? reps,
    double? weightKg,
    ExerciseUnit? unit,
    bool? perSide,
  }) {
    return Exercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      unit: unit ?? this.unit,
      perSide: perSide ?? this.perSide,
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
    this.warmup = '',
    this.hockeyType,
    this.distanceKm,
    this.sportDetails = '',
    this.exercises = const [],
    this.cycleCount = 1,
  });

  final int? id;
  final String title;
  final Sport sport;
  final int durationMinutes;
  final String description;
  final String warmup;
  final HockeySessionType? hockeyType;
  final double? distanceKm;
  final String sportDetails;
  final List<Exercise> exercises;
  final int cycleCount;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'sport': sport.name,
    'duration_minutes': durationMinutes,
    'description': description,
    'warmup': warmup,
    'hockey_type': hockeyType?.name,
    'distance_km': distanceKm,
    'sport_details': sportDetails,
    'cycle_count': cycleCount,
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
      warmup: map['warmup'] as String? ?? '',
      hockeyType: map['hockey_type'] == null
          ? null
          : HockeySessionType.values.byName(map['hockey_type'] as String),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      sportDetails: map['sport_details'] as String,
      exercises: exercises,
      cycleCount: map['cycle_count'] as int? ?? 1,
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
    this.warmup = '',
    required this.status,
    this.hockeyType,
    this.distanceKm,
    this.sportDetails = '',
    this.exercises = const [],
    this.comment = '',
    this.completedAt,
    this.cycleCount = 1,
  });

  final int? id;
  final int? templateId;
  final String title;
  final Sport sport;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String description;
  final String warmup;
  final WorkoutStatus status;
  final HockeySessionType? hockeyType;
  final double? distanceKm;
  final String sportDetails;
  final List<Exercise> exercises;
  final String comment;
  final DateTime? completedAt;
  final int cycleCount;

  Map<String, Object?> toMap() => {
    'id': id,
    'template_id': templateId,
    'title': title,
    'sport': sport.name,
    'scheduled_at': scheduledAt.toIso8601String(),
    'duration_minutes': durationMinutes,
    'notes': description,
    'warmup': warmup,
    'details': sportDetails,
    'status': status.name,
    'comment': comment,
    'completed_at': completedAt?.toIso8601String(),
    'hockey_type': hockeyType?.name,
    'distance_km': distanceKm,
    'cycle_count': cycleCount,
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
      warmup: map['warmup'] as String? ?? '',
      status: WorkoutStatus.values.byName(map['status'] as String),
      hockeyType: map['hockey_type'] == null
          ? null
          : HockeySessionType.values.byName(map['hockey_type'] as String),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      sportDetails: map['details'] as String,
      exercises: exercises,
      comment: map['comment'] as String,
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.parse(map['completed_at'] as String),
      cycleCount: map['cycle_count'] as int? ?? 1,
    );
  }
}

extension SportLabel on Sport {
  String get label => switch (this) {
    Sport.gym => 'Gym',
    Sport.running => 'Running',
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
