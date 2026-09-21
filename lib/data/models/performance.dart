import 'training.dart';

class GymPerformance {
  const GymPerformance(this.workout, this.weight, this.total, this.unit);
  final Workout workout;
  final double weight;
  final double total;
  final ExerciseUnit unit;
}

List<GymPerformance> gymPerformance(
  List<Workout> workouts,
  int libraryId,
  ExerciseUnit unit,
) {
  final points = <GymPerformance>[];
  for (final workout in workouts) {
    if (workout.sport != Sport.gym || workout.status != WorkoutStatus.completed)
      continue;
    double? highest;
    var total = 0.0;
    var unknown = false;
    for (final exercise in workout.exercises.where(
      (e) => e.libraryId == libraryId && e.unit == unit,
    )) {
      for (final set in exercise.workingSets.where(
        (s) => s.confirmed && s.amount > 0,
      )) {
        if (exercise.weightMode == null ||
            (exercise.weightMode == WeightMode.bodyweight &&
                workout.bodyWeightKg == null)) {
          unknown = true;
          continue;
        }
        final weight =
            set.weightKg +
            (exercise.weightMode == WeightMode.bodyweight
                ? workout.bodyWeightKg!
                : 0);
        if (!weight.isFinite || weight < 0) {
          unknown = true;
          continue;
        }
        highest = highest == null || weight > highest ? weight : highest;
        total += weight * set.amount;
      }
    }
    // Never show a partial total as though the entire exercise were known.
    if (!unknown && highest != null && total.isFinite)
      points.add(GymPerformance(workout, highest, total, unit));
  }
  points.sort((a, b) {
    final date = a.workout.scheduledAt.compareTo(b.workout.scheduledAt);
    return date != 0 ? date : (a.workout.id ?? 0).compareTo(b.workout.id ?? 0);
  });
  return points;
}

Workout? previousGymWorkout(
  List<Workout> workouts,
  Workout current,
  Exercise exercise,
) {
  final candidates = workouts
      .where(
        (w) =>
            w.id != current.id &&
            w.sport == Sport.gym &&
            w.status == WorkoutStatus.completed &&
            w.scheduledAt.isBefore(current.startedAt ?? current.scheduledAt) &&
            w.exercises.any(
              (e) =>
                  e.libraryId == exercise.libraryId &&
                  e.unit == exercise.unit &&
                  e.workingSets.any((s) => s.confirmed && s.amount > 0),
            ),
      )
      .toList();
  candidates.sort((a, b) {
    final date = b.scheduledAt.compareTo(a.scheduledAt);
    return date != 0 ? date : (b.id ?? 0).compareTo(a.id ?? 0);
  });
  return candidates.firstOrNull;
}
