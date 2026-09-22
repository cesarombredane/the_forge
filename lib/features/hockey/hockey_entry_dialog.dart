import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';
import 'package:the_forge/data/models/training.dart';
import 'package:the_forge/data/models/hockey.dart';
import 'opponent_field.dart';

Future<bool?> showHockeyEntry(
  BuildContext context,
  AppController controller,
  Workout workout, {
  bool tournamentGame = false,
  TournamentGame? game,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => HockeyEntryDialog(
    controller: controller,
    workout: workout,
    tournamentGame: tournamentGame,
    game: game,
  ),
);

class HockeyEntryDialog extends StatefulWidget {
  const HockeyEntryDialog({
    super.key,
    required this.controller,
    required this.workout,
    this.tournamentGame = false,
    this.game,
  });
  final AppController controller;
  final Workout workout;
  final bool tournamentGame;
  final TournamentGame? game;
  @override
  State<HockeyEntryDialog> createState() => _HockeyEntryDialogState();
}

class _HockeyEntryDialogState extends State<HockeyEntryDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _duration, _goals, _assists, _plus, _comment;
  int? _opponent;
  late bool _record;
  late DateTime _date;
  bool _busy = false;
  String? _error;
  bool get _training =>
      !widget.tournamentGame &&
      (widget.workout.hockeyType == HockeySessionType.training ||
          widget.workout.hockeyType == null);
  bool get _coaching =>
      !widget.tournamentGame &&
      widget.workout.hockeyType == HockeySessionType.coaching;
  @override
  void initState() {
    super.initState();
    final record = widget.controller.hockeyRecords
        .where((r) => r.workoutId == widget.workout.id)
        .firstOrNull;
    final stats = widget.tournamentGame ? widget.game?.stats : record?.stats;
    _opponent = widget.tournamentGame
        ? widget.game?.opponentId
        : record?.opponentId;
    _record = !_training || stats != null;
    _date = widget.game?.playedAt ?? widget.workout.scheduledAt;
    _duration = TextEditingController(
      text: widget.tournamentGame
          ? widget.game?.durationMinutes.toString() ?? ''
          : '${widget.workout.durationMinutes}',
    );
    _goals = TextEditingController(text: stats?.goals.toString() ?? '');
    _assists = TextEditingController(text: stats?.assists.toString() ?? '');
    _plus = TextEditingController(text: stats?.plusMinus.toString() ?? '');
    _comment = TextEditingController(text: widget.workout.comment);
  }

  @override
  void dispose() {
    for (final c in [_duration, _goals, _assists, _plus, _comment]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _number(
    TextEditingController controller,
    String label, {
    bool signed = false,
    bool positive = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(signed: signed),
    decoration: InputDecoration(labelText: label),
    validator: (v) {
      final number = int.tryParse((v ?? '').trim());
      return number == null || (!signed && number < (positive ? 1 : 0))
          ? (signed
                ? 'Enter a signed whole number'
                : positive
                ? 'Enter a whole number above 0'
                : 'Enter 0 or a positive whole number')
          : null;
    },
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(
        widget.tournamentGame
            ? (widget.game == null
                  ? 'Add tournament game'
                  : 'Edit tournament game')
            : widget.workout.status == WorkoutStatus.completed
            ? 'Edit hockey statistics'
            : 'Complete hockey session',
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.tournamentGame)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Game date and time'),
                    subtitle: Text(
                      '${MaterialLocalizations.of(context).formatMediumDate(_date)} · ${TimeOfDay.fromDateTime(_date).format(context)}',
                    ),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: _busy ? null : _pickDate,
                  ),
                _number(
                  _duration,
                  widget.tournamentGame || !_training && !_coaching
                      ? 'Whole game duration (minutes)'
                      : 'Duration (minutes)',
                  positive: true,
                ),
                if (!_coaching)
                  OpponentField(
                    controller: widget.controller,
                    value: _opponent,
                    optional: _training,
                    onChanged: (id) => setState(() => _opponent = id),
                  ),
                if (_training)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Record statistics'),
                    subtitle: const Text('Off means not recorded, not zero.'),
                    value: _record,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _record = v),
                  ),
                if (!_coaching && _record) ...[
                  _number(_goals, 'Goals'),
                  _number(_assists, 'Assists'),
                  _number(_plus, 'Plus-minus (+ / −)', signed: true),
                ],
                if (!widget.tournamentGame)
                  TextFormField(
                    controller: _comment,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Training comment',
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time != null && mounted)
      setState(
        () => _date = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!_coaching && !_training && _opponent == null) {
      setState(() => _error = 'Select an opponent.');
      return;
    }
    final stats = !_coaching && _record
        ? HockeyStats(
            goals: int.parse(_goals.text.trim()),
            assists: int.parse(_assists.text.trim()),
            plusMinus: int.parse(_plus.text.trim()),
          )
        : null;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.tournamentGame) {
        await widget.controller.saveHockeyGame(
          TournamentGame(
            id: widget.game?.id,
            workoutId: widget.workout.id!,
            opponentId: _opponent!,
            playedAt: _date,
            durationMinutes: int.parse(_duration.text.trim()),
            stats: stats!,
          ),
        );
      } else {
        await widget.controller.saveHockey(
          widget.workout.copyWith(
            durationMinutes: int.parse(_duration.text.trim()),
            comment: _comment.text.trim(),
          ),
          opponentId: _coaching ? null : _opponent,
          stats: stats,
        );
      }
      if (mounted) {
        setState(() => _busy = false);
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = '$error';
        });
    }
  }
}
