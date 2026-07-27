import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/training_note.dart';

/// Bottom sheet para crear o editar una [TrainingNote].
/// Devuelve la nota lista para guardar, o null si se cancela.
class AddNoteSheet extends StatefulWidget {
  final TrainingNote? initial;
  const AddNoteSheet({super.key, this.initial});

  static Future<TrainingNote?> show(
    BuildContext context, {
    TrainingNote? initial,
  }) {
    return showModalBottomSheet<TrainingNote>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => AddNoteSheet(initial: initial),
    );
  }

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  late DateTime _date;
  int? _fatigue;
  late final TextEditingController _textCtrl;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _date = widget.initial?.date ?? DateTime.now();
    _fatigue = widget.initial?.fatigue;
    _textCtrl = TextEditingController(text: widget.initial?.text ?? '');
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final base = widget.initial;
    final note = TrainingNote(
      id: base?.id ?? '',
      userId: base?.userId ?? '',
      date: _date,
      fatigue: _fatigue,
      text: text,
      createdAt: base?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(note);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditing ? 'Editar nota' : 'Nueva nota',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(DateFormat('EEE d MMM y', 'es').format(_date)),
            ),
            const SizedBox(height: 16),

            Text('Fatiga (opcional)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(5, (i) {
                final v = i + 1;
                return ChoiceChip(
                  label: Text('$v'),
                  selected: _fatigue == v,
                  onSelected: (sel) =>
                      setState(() => _fatigue = sel ? v : null),
                );
              }),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _textCtrl,
              autofocus: !_isEditing,
              decoration: const InputDecoration(
                labelText: 'Nota',
                hintText: '¿Cómo fue el entrenamiento?',
              ),
              minLines: 3,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _textCtrl.text.trim().isEmpty ? null : _save,
                  child: Text(_isEditing ? 'Guardar' : 'Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
