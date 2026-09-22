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

enum WeightMode { external, bodyweight }

String exerciseKey(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

class LibraryExercise {
  const LibraryExercise({
    required this.id,
    required this.name,
    required this.unit,
    required this.weightMode,
    this.archived = false,
    this.tracked = false,
    this.needsReview = false,
  });
  final int id;
  final String name;
  final ExerciseUnit unit;
  final WeightMode weightMode;
  final bool archived;
  final bool tracked;
  final bool needsReview;
  factory LibraryExercise.fromMap(Map<String, Object?> row) => LibraryExercise(
    id: row['id'] as int,
    name: row['name'] as String,
    unit: ExerciseUnit.values.byName(row['unit'] as String),
    weightMode: WeightMode.values.byName(row['weight_mode'] as String),
    archived: row['archived'] == 1,
    tracked: row['tracked'] == 1,
    needsReview: row['needs_review'] == 1,
  );
}

class WorkingSet {
  const WorkingSet({
    required this.amount,
    required this.weightKg,
    this.confirmed = false,
  });
  final int amount;
  final double weightKg;
  final bool confirmed;
  WorkingSet copyWith({int? amount, double? weightKg, bool? confirmed}) =>
      WorkingSet(
        amount: amount ?? this.amount,
        weightKg: weightKg ?? this.weightKg,
        confirmed: confirmed ?? this.confirmed,
      );
  Map<String, Object?> toMap() => {
    'amount': amount,
    'weight_kg': weightKg,
    'confirmed': confirmed ? 1 : 0,
  };
  factory WorkingSet.fromMap(Map<String, Object?> row) => WorkingSet(
    amount: row['amount'] as int,
    weightKg: (row['weight_kg'] as num).toDouble(),
    confirmed: row['confirmed'] == 1,
  );
}

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
    this.libraryId,
    this.weightMode,
    this.workingSets = const [],
  });

  final String name;
  final int sets;
  final int reps;
  final double weightKg;
  final ExerciseUnit unit;
  final bool perSide;
  final int? libraryId;
  final WeightMode? weightMode;
  final List<WorkingSet> workingSets;
  List<WorkingSet> get prescribedSets => workingSets.isNotEmpty
      ? workingSets
      : List.generate(
          sets,
          (_) => WorkingSet(amount: reps, weightKg: weightKg),
        );

  Exercise copyWith({
    String? name,
    int? sets,
    int? reps,
    double? weightKg,
    ExerciseUnit? unit,
    bool? perSide,
    int? libraryId,
    WeightMode? weightMode,
    List<WorkingSet>? workingSets,
  }) {
    return Exercise(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      unit: unit ?? this.unit,
      perSide: perSide ?? this.perSide,
      libraryId: libraryId ?? this.libraryId,
      weightMode: weightMode ?? this.weightMode,
      workingSets: workingSets ?? this.workingSets,
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
    this.targetDurationMinutes,
    this.targetDistanceKm,
    this.startedAt,
    this.bodyWeightKg,
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
  final int? targetDurationMinutes;
  final double? targetDistanceKm;
  final DateTime? startedAt;
  final double? bodyWeightKg;

  Workout copyWith({
    String? title,
    DateTime? scheduledAt,
    int? durationMinutes,
    String? comment,
    List<Exercise>? exercises,
    DateTime? startedAt,
    double? bodyWeightKg,
  }) => Workout(
    id: id,
    templateId: templateId,
    title: title ?? this.title,
    sport: sport,
    scheduledAt: scheduledAt ?? this.scheduledAt,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    description: description,
    warmup: warmup,
    status: status,
    hockeyType: hockeyType,
    distanceKm: distanceKm,
    sportDetails: sportDetails,
    exercises: exercises ?? this.exercises,
    comment: comment ?? this.comment,
    completedAt: completedAt,
    cycleCount: cycleCount,
    targetDurationMinutes: targetDurationMinutes,
    targetDistanceKm: targetDistanceKm,
    startedAt: startedAt ?? this.startedAt,
    bodyWeightKg: bodyWeightKg ?? this.bodyWeightKg,
  );

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
    'target_duration_minutes': targetDurationMinutes,
    'target_distance_km': targetDistanceKm,
    'started_at': startedAt?.toIso8601String(),
    'body_weight_kg': bodyWeightKg,
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
      targetDurationMinutes: map['target_duration_minutes'] as int?,
      targetDistanceKm: (map['target_distance_km'] as num?)?.toDouble(),
      startedAt: map['started_at'] == null
          ? null
          : DateTime.parse(map['started_at'] as String),
      bodyWeightKg: (map['body_weight_kg'] as num?)?.toDouble(),
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

void validateGymWorkout(Workout workout, {required bool finishing}) {
  if (workout.durationMinutes <= 0)
    throw ArgumentError('Enter a positive duration.');
  for (final exercise in workout.exercises) {
    if (exercise.libraryId == null || exercise.weightMode == null)
      throw StateError('Review exercise links and weight modes first.');
    for (final set in exercise.prescribedSets) {
      if (set.amount < 0 || !set.weightKg.isFinite)
        throw ArgumentError('Enter valid set values.');
      if (finishing && !set.confirmed)
        throw StateError('Confirm every working set, including skipped sets.');
      if (exercise.weightMode == WeightMode.external && set.weightKg < 0)
        throw ArgumentError(
          'External load cannot be negative. Use bodyweight mode for assistance.',
        );
      if (exercise.weightMode == WeightMode.bodyweight) {
        final bodyweight = workout.bodyWeightKg;
        if (bodyweight == null || !bodyweight.isFinite || bodyweight <= 0)
          throw StateError('A bodyweight snapshot is required.');
        if (bodyweight + set.weightKg < 0)
          throw ArgumentError('Assistance cannot exceed bodyweight.');
      }
    }
  }
}

// For mobility, workingSets contains one result per cycle; its load is always zero.
void validateMobilityWorkout(
  Workout workout, {
  required bool finishing,
  bool allowUnknown = false,
}) {
  if (workout.durationMinutes <= 0 ||
      workout.cycleCount <= 0 ||
      workout.exercises.isEmpty)
    throw ArgumentError(
      'Enter a positive duration, cycles, and at least one movement.',
    );
  for (final e in workout.exercises) {
    if (allowUnknown && e.workingSets.isEmpty) continue;
    if (e.workingSets.length != workout.cycleCount)
      throw ArgumentError(
        'Edit ${e.name}: record a result for each of the ${workout.cycleCount} cycles.',
      );
    if (e.workingSets.any(
      (s) => s.amount < 0 || s.weightKg != 0 || (finishing && !s.confirmed),
    ))
      throw ArgumentError('Confirm every movement or enter 0 to skip.');
  }
}
