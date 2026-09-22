import 'package:flutter/material.dart';
import 'package:the_forge/app/app_controller.dart';

class OpponentField extends StatelessWidget {
  const OpponentField({
    super.key,
    required this.controller,
    required this.value,
    required this.onChanged,
    this.optional = false,
  });
  final AppController controller;
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool optional;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(optional ? 'Opponent (optional)' : 'Opponent'),
      subtitle: Text(
        value == null
            ? (optional ? 'No opponent' : 'Select an opponent')
            : controller.opponentName(value),
      ),
      trailing: const Icon(Icons.expand_more),
      onTap: () async {
        final result = await showDialog<int>(
          context: context,
          builder: (_) =>
              _OpponentPicker(controller: controller, optional: optional),
        );
        if (result != null) onChanged(result == -1 ? null : result);
      },
    ),
  );
}

class _OpponentPicker extends StatefulWidget {
  const _OpponentPicker({required this.controller, required this.optional});
  final AppController controller;
  final bool optional;
  @override
  State<_OpponentPicker> createState() => _OpponentPickerState();
}

class _OpponentPickerState extends State<_OpponentPicker> {
  String? _error;
  Future<void> _name({int? id, String initial = ''}) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _OpponentName(
        controller: widget.controller,
        id: id,
        initial: initial,
      ),
    );
    if (mounted && id == null && result != null) Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Select opponent'),
    content: SizedBox(
      width: 400,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => ListView(
          shrinkWrap: true,
          children: [
            if (widget.optional)
              ListTile(
                title: const Text('No opponent'),
                onTap: () => Navigator.pop(context, -1),
              ),
            for (final opponent in widget.controller.opponents.where(
              (o) => !o.deleted,
            ))
              ListTile(
                title: Text(opponent.name),
                onTap: () => Navigator.pop(context, opponent.id),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'rename') {
                      await _name(id: opponent.id, initial: opponent.name);
                      return;
                    }
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete ${opponent.name}?'),
                        content: const Text(
                          'Remove from future selections. Existing records and statistics will be kept.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
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
                      await widget.controller.deleteOpponent(opponent.id);
                    } catch (error) {
                      if (mounted) setState(() => _error = '$error');
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: () => _name(),
        icon: const Icon(Icons.add),
        label: const Text('Create opponent'),
      ),
    ],
  );
}

class _OpponentName extends StatefulWidget {
  const _OpponentName({
    required this.controller,
    required this.id,
    required this.initial,
  });
  final AppController controller;
  final int? id;
  final String initial;
  @override
  State<_OpponentName> createState() => _OpponentNameState();
}

class _OpponentNameState extends State<_OpponentName> {
  late final _name = TextEditingController(text: widget.initial);
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.id == null ? 'Create opponent' : 'Rename opponent'),
    content: TextField(
      controller: _name,
      autofocus: true,
      decoration: InputDecoration(labelText: 'Name', errorText: _error),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy
            ? null
            : () async {
                if (_name.text.trim().isEmpty) {
                  setState(() => _error = 'Enter a name.');
                  return;
                }
                setState(() {
                  _busy = true;
                  _error = null;
                });
                try {
                  final id = await widget.controller.saveOpponent(
                    _name.text,
                    id: widget.id,
                  );
                  if (context.mounted) Navigator.pop(context, id);
                } catch (_) {
                  if (mounted)
                    setState(() {
                      _busy = false;
                      _error = 'Could not save. Use a unique opponent name.';
                    });
                }
              },
        child: const Text('Save'),
      ),
    ],
  );
}
