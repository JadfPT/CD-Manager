import 'package:flutter/material.dart';

class NoteEditorCard extends StatefulWidget {
  const NoteEditorCard({
    required this.initialNote,
    required this.isBusy,
    required this.onSave,
    required this.onDelete,
    super.key,
  });

  final String? initialNote;
  final bool isBusy;
  final Future<void> Function(String note) onSave;
  final Future<void> Function() onDelete;

  @override
  State<NoteEditorCard> createState() => _NoteEditorCardState();
}

class _NoteEditorCardState extends State<NoteEditorCard> {
  late final TextEditingController _controller;
  String _lastInitial = '';

  @override
  void initState() {
    super.initState();
    _lastInitial = widget.initialNote ?? '';
    _controller = TextEditingController(text: _lastInitial);
  }

  @override
  void didUpdateWidget(covariant NoteEditorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextInitial = widget.initialNote ?? '';

    if (nextInitial != _lastInitial && _controller.text == _lastInitial) {
      _controller.text = nextInitial;
      _lastInitial = nextInitial;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A minha nota',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              minLines: 4,
              maxLines: 8,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Escreve uma nota pessoal sobre este CD...',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.isBusy
                        ? null
                        : () => widget.onSave(_controller.text.trim()),
                    icon: widget.isBusy
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Guardar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.isBusy || !hasText
                        ? null
                        : () async {
                            await widget.onDelete();
                            if (mounted) {
                              _controller.clear();
                              setState(() {});
                            }
                          },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Apagar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
