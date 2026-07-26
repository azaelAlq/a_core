import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/routine.dart';
import 'exercise_card.dart';

class BlockEditor extends StatefulWidget {
  final Block block;
  final ValueChanged<Block> onChanged;
  final VoidCallback onDelete;

  const BlockEditor({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<BlockEditor> {
  static const _uuid = Uuid();
  late final TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.block.label ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  void _changeSeries(int delta) {
    final n = widget.block.series + delta;
    if (n < 1) return;
    widget.onChanged(widget.block.withSeries(n));
  }

  void _addExercise() {
    final exercise = Exercise(
      id: _uuid.v4(),
      name: '',
      sets: List.generate(widget.block.series, (_) => const SetEntry()),
    );
    widget.onChanged(
      widget.block.copyWith(exercises: [...widget.block.exercises, exercise]),
    );
  }

  void _updateExercise(Exercise updated) {
    final list = widget.block.exercises
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    widget.onChanged(widget.block.copyWith(exercises: list));
  }

  void _deleteExercise(String id) {
    final list = widget.block.exercises.where((e) => e.id != id).toList();
    widget.onChanged(widget.block.copyWith(exercises: list));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = widget.block;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado: etiqueta + series + eliminar ──
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _labelCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Etiqueta (ej. Bloque A)',
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    style: theme.textTheme.titleSmall,
                    onChanged: (v) =>
                        widget.onChanged(block.copyWith(label: v)),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  tooltip: 'Eliminar bloque',
                  onPressed: widget.onDelete,
                ),
              ],
            ),

            // ── Stepper de series ──
            Row(
              children: [
                Text(
                  'Series del bloque',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: block.series > 1 ? () => _changeSeries(-1) : null,
                ),
                Text(
                  '${block.series}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () => _changeSeries(1),
                ),
              ],
            ),

            // ── Ejercicios ──
            ...block.exercises.map(
              (e) => ExerciseCard(
                key: ValueKey(e.id),
                exercise: e,
                onChanged: _updateExercise,
                onDelete: () => _deleteExercise(e.id),
              ),
            ),

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar ejercicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
