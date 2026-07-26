import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/routine.dart';

class ExerciseCard extends StatefulWidget {
  final Exercise exercise;
  final ValueChanged<Exercise> onChanged;
  final VoidCallback onDelete;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<ExerciseCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;
  final List<TextEditingController> _repsCtrls = [];
  final List<TextEditingController> _weightCtrls = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.exercise.name);
    _notesCtrl = TextEditingController(text: widget.exercise.notes ?? '');
    _syncSetControllers();
  }

  @override
  void didUpdateWidget(covariant ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Solo ajusta filas cuando cambia el número de series del bloque;
    // el texto de cada celda lo gobierna su propio controller.
    if (widget.exercise.sets.length != _repsCtrls.length) _syncSetControllers();
  }

  void _syncSetControllers() {
    final sets = widget.exercise.sets;
    while (_repsCtrls.length > sets.length) {
      _repsCtrls.removeLast().dispose();
      _weightCtrls.removeLast().dispose();
    }
    while (_repsCtrls.length < sets.length) {
      final i = _repsCtrls.length;
      _repsCtrls.add(
        TextEditingController(text: sets[i].reps?.toString() ?? ''),
      );
      _weightCtrls.add(
        TextEditingController(text: _formatWeight(sets[i].weight)),
      );
    }
    setState(() {});
  }

  static String _formatWeight(double? w) {
    if (w == null) return '';
    return w == w.roundToDouble() ? w.toInt().toString() : w.toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _repsCtrls) {
      c.dispose();
    }
    for (final c in _weightCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _onSetChanged(int i, {String? reps, String? weight}) {
    final sets = [...widget.exercise.sets];
    final old = sets[i];
    sets[i] = SetEntry(
      reps: reps != null ? int.tryParse(reps) : old.reps,
      weight: weight != null
          ? double.tryParse(weight.replaceAll(',', '.'))
          : old.weight,
    );
    widget.onChanged(widget.exercise.copyWith(sets: sets));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = widget.exercise;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado: done + nombre + eliminar ──
          Row(
            children: [
              Checkbox(
                value: e.done,
                onChanged: (v) =>
                    widget.onChanged(e.copyWith(done: v ?? false)),
              ),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Nombre del ejercicio',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  style: theme.textTheme.titleSmall?.copyWith(
                    decoration: e.done ? TextDecoration.lineThrough : null,
                    color: e.done
                        ? theme.colorScheme.onSurface.withOpacity(0.5)
                        : null,
                  ),
                  onChanged: (v) => widget.onChanged(e.copyWith(name: v)),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                tooltip: 'Eliminar ejercicio',
                onPressed: widget.onDelete,
              ),
            ],
          ),

          // ── Peso completo / por lado ──
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Peso completo')),
              ButtonSegment(value: true, label: Text('Por lado')),
            ],
            selected: {e.perSide},
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onSelectionChanged: (s) =>
                widget.onChanged(e.copyWith(perSide: s.first)),
          ),
          const SizedBox(height: 10),

          // ── Tabla de series ──
          Row(
            children: [
              SizedBox(
                width: 44,
                child: Text('Serie', style: _headerStyle(theme)),
              ),
              Expanded(child: Text('Reps', style: _headerStyle(theme))),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.perSide ? 'Peso/lado' : 'Peso',
                  style: _headerStyle(theme),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...List.generate(e.sets.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text('${i + 1}', style: theme.textTheme.bodyMedium),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _repsCtrls[i],
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        hintText: '—',
                        isDense: true,
                      ),
                      onChanged: (v) => _onSetChanged(i, reps: v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _weightCtrls[i],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: const InputDecoration(
                        hintText: '—',
                        isDense: true,
                      ),
                      onChanged: (v) => _onSetChanged(i, weight: v),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ── Notas ──
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              hintText: 'Notas (opcional)',
              isDense: true,
              border: InputBorder.none,
            ),
            style: theme.textTheme.bodySmall,
            onChanged: (v) => widget.onChanged(e.copyWith(notes: v)),
          ),
        ],
      ),
    );
  }

  TextStyle? _headerStyle(ThemeData theme) =>
      theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.5),
        letterSpacing: 0.5,
      );
}
