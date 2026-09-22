import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/data/models/hockey.dart';
import 'performance_page.dart';

class HockeyPerformanceTab extends StatefulWidget {
  const HockeyPerformanceTab({super.key, required this.controller});
  final AppController controller;
  @override
  State<HockeyPerformanceTab> createState() => _HockeyPerformanceTabState();
}

class _HockeyPerformanceTabState extends State<HockeyPerformanceTab> {
  bool _season = false;
  int _opponent =
      -1; // -1 all; 0 no opponent; positive stable opponent identity.
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final start = hockeySeasonStart(DateTime.now());
    final all = hockeyPerformance(
      controller.workouts,
      controller.hockeyRecords,
      controller.hockeyGames,
      seasonStart: _season ? start : null,
    );
    final filtered = all
        .where(
          (p) =>
              _opponent == -1 ||
              (_opponent == 0
                  ? p.opponentId == null
                  : p.opponentId == _opponent),
        )
        .toList();
    final total = sumHockeyStats(filtered.map((p) => p.stats));
    final ids = all.map((p) => p.opponentId).toSet().toList()
      ..sort(
        (a, b) =>
            controller.opponentName(a).compareTo(controller.opponentName(b)),
      );
    List<PerformancePoint> points(bool plus) => filtered
        .map(
          (p) => PerformancePoint(
            p.date,
            '${p.title} · ${controller.opponentName(p.opponentId)}',
            plus ? p.stats.plusMinus.toDouble() : p.stats.goals.toDouble(),
            plus ? null : p.stats.assists.toDouble(),
            '${p.stats.goals} goals · ${p.stats.assists} assists · ${p.stats.points} points · ${signedHockey(p.stats.plusMinus)} plus-minus',
          ),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('All time')),
            ButtonSegment(value: true, label: Text('This year')),
          ],
          selected: {_season},
          onSelectionChanged: (v) => setState(() => _season = v.first),
        ),
        if (_season)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Season: 1 Sep ${start.year} – 31 Aug ${start.year + 1}',
            ),
          ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _opponent,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Opponent'),
          items: [
            const DropdownMenuItem(value: -1, child: Text('All opponents')),
            const DropdownMenuItem(value: 0, child: Text('No opponent')),
            for (final o in controller.opponents)
              DropdownMenuItem(
                value: o.id,
                child: Text('${o.name}${o.deleted ? ' (deleted)' : ''}'),
              ),
          ],
          onChanged: (v) => setState(() => _opponent = v!),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          children: [
            _total('Goals', '${total.goals}'),
            _total('Assists', '${total.assists}'),
            _total('Points', '${total.points}'),
            _total('Plus-minus', signedHockey(total.plusMinus)),
          ],
        ),
        Text('${filtered.length} recorded sessions/games'),
        const Text(
          'Includes recorded training statistics and saved tournament games. Coaching and unrecorded statistics are excluded.',
        ),
        PerformanceChart(
          key: ValueKey('production:$_season:$_opponent'),
          title: 'Goals and assists',
          firstLabel: 'Goals',
          secondLabel: 'Assists',
          points: points(false),
          sharedScale: true,
        ),
        PerformanceChart(
          key: ValueKey('plus:$_season:$_opponent'),
          title: 'Plus-minus',
          firstLabel: 'Plus-minus',
          points: points(true),
        ),
        const SizedBox(height: 12),
        Text(
          'Opponent comparison · ${_season ? 'this season' : 'all time'}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const Text('All opponents in the selected period.'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Opponent')),
              DataColumn(label: Text('Sessions / games'), numeric: true),
              DataColumn(label: Text('G'), numeric: true),
              DataColumn(label: Text('A'), numeric: true),
              DataColumn(label: Text('Points'), numeric: true),
              DataColumn(label: Text('+ / −'), numeric: true),
            ],
            rows: [for (final id in ids) _row(id, all)],
          ),
        ),
      ],
    );
  }

  Widget _total(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      Text(value, style: Theme.of(context).textTheme.headlineSmall),
    ],
  );
  DataRow _row(int? id, List<HockeyPerformance> entries) {
    final group = entries.where((p) => p.opponentId == id).toList();
    final stats = sumHockeyStats(group.map((p) => p.stats));
    return DataRow(
      cells: [
        DataCell(
          Text(
            '${widget.controller.opponentName(id)}${widget.controller.opponents.any((o) => o.id == id && o.deleted) ? ' (deleted)' : ''}',
          ),
        ),
        DataCell(Text('${group.length}')),
        DataCell(Text('${stats.goals}')),
        DataCell(Text('${stats.assists}')),
        DataCell(Text('${stats.points}')),
        DataCell(Text(signedHockey(stats.plusMinus))),
      ],
    );
  }
}
