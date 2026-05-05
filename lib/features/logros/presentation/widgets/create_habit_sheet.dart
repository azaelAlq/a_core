import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/habit.dart';
import '../provider/logros_provider.dart';

const _emojis = ['💪', '📚', '🏃', '💧', '🧘', '🥗', '😴', '✍️', '🎯', '🌿', '🎨', '🎵'];

class CreateHabitSheet extends StatefulWidget {
  final String uid;
  const CreateHabitSheet({super.key, required this.uid});

  @override
  State<CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends State<CreateHabitSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();

  String _emoji = '💪';
  HabitFrequency _frequency = HabitFrequency.daily;
  HabitType _type = HabitType.yesNo;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    await context.read<LogrosProvider>().createHabit(
      userId: widget.uid,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      emoji: _emoji,
      frequency: _frequency,
      type: _type,
      targetValue: _type != HabitType.yesNo ? double.tryParse(_targetCtrl.text) : null,
      unit: _type != HabitType.yesNo && _unitCtrl.text.trim().isNotEmpty
          ? _unitCtrl.text.trim()
          : null,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logros = context.watch<LogrosProvider>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (_, ctrl) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: ListView(
          controller: ctrl,
          children: [
            Text('Nuevo hábito', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),

            // ── Emoji picker ──────────────
            Text('Ícono', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _emojis.map((e) {
                final selected = _emoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: selected ? Border.all(color: theme.colorScheme.primary) : null,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 16),

            // ── Frecuencia ────────────────
            Text('Frecuencia', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            SegmentedButton<HabitFrequency>(
              segments: const [
                ButtonSegment(value: HabitFrequency.daily, label: Text('Diario')),
                ButtonSegment(value: HabitFrequency.weekly, label: Text('Semanal')),
              ],
              selected: {_frequency},
              onSelectionChanged: (s) => setState(() => _frequency = s.first),
            ),
            const SizedBox(height: 16),

            // ── Tipo ──────────────────────
            Text('Tipo de registro', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            SegmentedButton<HabitType>(
              segments: const [
                ButtonSegment(value: HabitType.yesNo, label: Text('Sí/No')),
                ButtonSegment(value: HabitType.quantity, label: Text('Cantidad')),
                ButtonSegment(value: HabitType.time, label: Text('Tiempo')),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),

            if (_type != HabitType.yesNo) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _type == HabitType.time
                            ? 'Minutos objetivo'
                            : 'Cantidad objetivo',
                      ),
                    ),
                  ),
                  if (_type == HabitType.quantity) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _unitCtrl,
                        decoration: const InputDecoration(labelText: 'Unidad'),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            const SizedBox(height: 32),
            FilledButton(
              onPressed: logros.loading ? null : _save,
              child: logros.loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar hábito'),
            ),
          ],
        ),
      ),
    );
  }
}
