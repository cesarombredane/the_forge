import 'package:flutter/material.dart';

/// Pace is derived, so corrected results never leave a stale stored pace.
int? runningPaceSeconds(int? minutes, double? distanceKm) {
  if (minutes == null ||
      minutes <= 0 ||
      distanceKm == null ||
      !distanceKm.isFinite ||
      distanceKm <= 0) {
    return null;
  }
  final pace = minutes * 60 / distanceKm;
  return pace.isFinite ? pace.round() : null;
}

String formatRunningPace(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

String _distance(double value) =>
    value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

class RunningComparison extends StatelessWidget {
  const RunningComparison({
    super.key,
    required this.targetMinutes,
    required this.targetDistanceKm,
    required this.actualMinutes,
    required this.actualDistanceKm,
  });

  final int? targetMinutes;
  final double? targetDistanceKm;
  final int? actualMinutes;
  final double? actualDistanceKm;

  @override
  Widget build(BuildContext context) {
    final minutes = actualMinutes != null && actualMinutes! > 0
        ? actualMinutes
        : null;
    final distance =
        actualDistanceKm != null &&
            actualDistanceKm!.isFinite &&
            actualDistanceKm! > 0
        ? actualDistanceKm
        : null;
    final targetPace = runningPaceSeconds(targetMinutes, targetDistanceKm);
    final actualPace = runningPaceSeconds(minutes, distance);
    final durationDifference = minutes == null || targetMinutes == null
        ? null
        : minutes - targetMinutes!;
    final distanceDifference = distance == null || targetDistanceKm == null
        ? null
        : distance - targetDistanceKm!;
    final paceDifference = actualPace == null || targetPace == null
        ? null
        : actualPace - targetPace;
    final rows = <List<String>>[
      ['', 'Target', 'Actual', 'Difference'],
      [
        'Duration',
        targetMinutes == null ? '—' : '$targetMinutes min',
        minutes == null ? '—' : '$minutes min',
        durationDifference == null
            ? '—'
            : '${durationDifference > 0 ? '+' : ''}$durationDifference min',
      ],
      [
        'Distance',
        targetDistanceKm == null ? '—' : '${_distance(targetDistanceKm!)} km',
        distance == null ? '—' : '${_distance(distance)} km',
        distanceDifference == null
            ? '—'
            : '${distanceDifference > 0 ? '+' : ''}${_distance(distanceDifference)} km',
      ],
      [
        'Pace\nmin/km',
        targetPace == null ? '—' : formatRunningPace(targetPace),
        actualPace == null ? '—' : formatRunningPace(actualPace),
        paceDifference == null
            ? '—'
            : paceDifference == 0
            ? 'On target'
            : '${formatRunningPace(paceDifference.abs())} ${paceDifference < 0 ? 'faster' : 'slower'}',
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1.1),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
            3: FlexColumnWidth(1.3),
          },
          children: [
            for (var index = 0; index < rows.length; index++)
              TableRow(
                children: [
                  for (final text in rows[index])
                    Padding(
                      padding: const EdgeInsets.only(right: 6, bottom: 10),
                      child: Text(
                        text,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: index == 0 ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
        if (targetMinutes == null || targetDistanceKm == null)
          const Text(
            'Original targets unavailable.',
            style: TextStyle(fontSize: 12),
          ),
      ],
    );
  }
}
