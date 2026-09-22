import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:the_forge/data/models/hockey.dart';
import 'hockey_entry_dialog.dart';

class TournamentPage extends StatefulWidget {
  const TournamentPage({
    super.key,
    required this.controller,
    required this.workout,
  });
  final AppController controller;
  final Workout workout;
  @override
  State<TournamentPage> createState() => _TournamentPageState();
}

class _TournamentPageState extends State<TournamentPage> {
  late final _comment = TextEditingController(text: widget.workout.comment);
  bool _busy = false;
  bool _leaving = false;
  String? _error;
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save({bool finish = false, bool leave = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.saveTournament(
        widget.workout.id!,
        _comment.text.trim(),
        finish: finish,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _leaving = leave || finish;
      });
      if (_leaving)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = '$error';
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _leaving,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _save(leave: true);
    },
    child: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final workout =
            widget.controller.workouts
                .where((w) => w.id == widget.workout.id)
                .firstOrNull ??
            widget.workout;
        final games = widget.controller.hockeyGames
            .where((g) => g.workoutId == workout.id)
            .toList();
        final total = sumHockeyStats(games.map((g) => g.stats));
        final minutes = games.fold(0, (sum, g) => sum + g.durationMinutes);
        return Scaffold(
          appBar: AppBar(title: Text(workout.title)),
          body: AbsorbPointer(
            absorbing: _busy,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${games.length} games · $minutes min',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  games.isEmpty
                      ? 'Statistics not recorded'
                      : '${total.goals} goals · ${total.assists} assists · ${total.points} points · ${signedHockey(total.plusMinus)} plus-minus',
                ),
                const SizedBox(height: 12),
                const Text(
                  'Each saved game counts in Performance immediately. Total duration is the sum of game durations.',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => showHockeyEntry(
                    context,
                    widget.controller,
                    workout,
                    tournamentGame: true,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add game'),
                ),
                for (var i = 0; i < games.length; i++)
                  Card(
                    child: ListTile(
                      title: Text(
                        'Game ${i + 1} · ${widget.controller.opponentName(games[i].opponentId)}',
                      ),
                      subtitle: Text(
                        '${MaterialLocalizations.of(context).formatMediumDate(games[i].playedAt)} · ${TimeOfDay.fromDateTime(games[i].playedAt).format(context)} · ${games[i].durationMinutes} min\n${games[i].stats.goals} goals · ${games[i].stats.assists} assists · ${signedHockey(games[i].stats.plusMinus)} plus-minus',
                      ),
                      onTap: () => showHockeyEntry(
                        context,
                        widget.controller,
                        workout,
                        tournamentGame: true,
                        game: games[i],
                      ),
                      trailing: IconButton(
                        tooltip: 'Delete game',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final game = games[i];
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete game?'),
                              content: const Text(
                                'This removes its statistics from the tournament and Performance.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                          try {
                            await widget.controller.deleteHockeyGame(game);
                          } catch (error) {
                            if (mounted) setState(() => _error = '$error');
                          }
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _comment,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Tournament comment',
                  ),
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                const SizedBox(height: 16),
                if (workout.status == WorkoutStatus.planned)
                  FilledButton(
                    onPressed: games.isEmpty ? null : () => _save(finish: true),
                    child: const Text('Finish tournament'),
                  ),
                TextButton(
                  onPressed: () => _save(leave: true),
                  child: Text(
                    workout.status == WorkoutStatus.completed
                        ? 'Save and close'
                        : 'Save and leave — resume later',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
