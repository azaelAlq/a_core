import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/habit.dart';
import '../provider/logros_provider.dart';

class LogHabitSheet extends StatefulWidget {
  final String uid;
  final Habit habit;
  const LogHabitSheet({super.key, required this.uid, required this.habit});

  @override
  State<LogHabitSheet> createState() => _LogHabitSheetState();
}

class _LogHabitSheetState extends State<LogHabitSheet> {
  final _valueCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _completed = true;

  @override
  void dispose() {
    _valueCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await context.read<LogrosProvider>().logHabit(
      userId: widget.uid,
      habit: widget.habit,
      completed: _completed,
      value: widget.habit.type != HabitType.yesNo ? double.tryParse(_valueCtrl.text) : null,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logros = context.watch<LogrosProvider>();
    final habit = widget.habit;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(habit.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Text(habit.name, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 20),

          if (habit.type == HabitType.yesNo) ...[
            Text('¿Lo completaste hoy?', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('✅ Sí')),
                ButtonSegment(value: false, label: Text('❌ No')),
              ],
              selected: {_completed},
              onSelectionChanged: (s) => setState(() => _completed = s.first),
            ),
          ] else ...[
            Text(
              habit.type == HabitType.time ? '¿Cuántos minutos?' : '¿Cuánto ${habit.unit ?? ''}?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _valueCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: habit.type == HabitType.time
                          ? 'Minutos'
                          : (habit.unit ?? 'Cantidad'),
                      suffixText: habit.targetValue != null
                          ? '/ ${habit.targetValue!.toInt()}'
                          : null,
                    ),
                    onChanged: (v) {
                      final val = double.tryParse(v) ?? 0;
                      setState(() {
                        _completed = habit.targetValue != null
                            ? val >= habit.targetValue!
                            : val > 0;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(labelText: 'Nota (opcional)'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: logros.loading ? null : _save,
              child: logros.loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
