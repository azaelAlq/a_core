import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/system.dart';
import '../provider/sistemas_provider.dart';

const _emojis = [
  '🎯',
  '💪',
  '📚',
  '🏃',
  '🧘',
  '💧',
  '🥗',
  '😴',
  '✍️',
  '🌿',
  '💰',
  '🧠',
  '☀️',
  '🔥',
];
const _dayNames = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

class CreateSystemSheet extends StatefulWidget {
  final String uid;
  final System? system; // si viene, es edición

  const CreateSystemSheet({super.key, required this.uid, this.system});

  @override
  State<CreateSystemSheet> createState() => _CreateSystemSheetState();
}

class _CreateSystemSheetState extends State<CreateSystemSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _identityCtrl;
  late final TextEditingController _cueCtrl;
  late final TextEditingController _cravingCtrl;
  late final TextEditingController _actionCtrl;
  late final TextEditingController _rewardCtrl;

  late String _emoji;
  late Set<int> _days; // 1..7

  bool get _isEdit => widget.system != null;

  @override
  void initState() {
    super.initState();
    final s = widget.system;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _identityCtrl = TextEditingController(text: s?.identity ?? '');
    _cueCtrl = TextEditingController(text: s?.cue ?? '');
    _cravingCtrl = TextEditingController(text: s?.craving ?? '');
    _actionCtrl = TextEditingController(text: s?.action ?? '');
    _rewardCtrl = TextEditingController(text: s?.reward ?? '');
    _emoji = s?.emoji ?? '🎯';
    _days = {
      ...(s?.targetDays ?? const [1, 2, 3, 4, 5, 6, 7]),
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _identityCtrl.dispose();
    _cueCtrl.dispose();
    _cravingCtrl.dispose();
    _actionCtrl.dispose();
    _rewardCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _actionCtrl.text.trim().isEmpty || _days.isEmpty) return;

    final prov = context.read<SistemasProvider>();
    final days = (_days.toList()..sort());

    if (_isEdit) {
      final updated = widget.system!.copyWith(
        name: _nameCtrl.text.trim(),
        identity: _identityCtrl.text.trim().isEmpty ? null : _identityCtrl.text.trim(),
        cue: _cueCtrl.text.trim().isEmpty ? null : _cueCtrl.text.trim(),
        craving: _cravingCtrl.text.trim().isEmpty ? null : _cravingCtrl.text.trim(),
        action: _actionCtrl.text.trim(),
        reward: _rewardCtrl.text.trim().isEmpty ? null : _rewardCtrl.text.trim(),
        emoji: _emoji,
        targetDays: days,
      );
      await prov.updateSystem(widget.uid, updated);
    } else {
      await prov.createSystem(
        userId: widget.uid,
        name: _nameCtrl.text.trim(),
        identity: _identityCtrl.text.trim().isEmpty ? null : _identityCtrl.text.trim(),
        cue: _cueCtrl.text.trim().isEmpty ? null : _cueCtrl.text.trim(),
        craving: _cravingCtrl.text.trim().isEmpty ? null : _cravingCtrl.text.trim(),
        action: _actionCtrl.text.trim(),
        reward: _rewardCtrl.text.trim().isEmpty ? null : _rewardCtrl.text.trim(),
        emoji: _emoji,
        targetDays: days,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loading = context.watch<SistemasProvider>().loading;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
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
            Text(_isEdit ? 'Editar sistema' : 'Nuevo sistema', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),

            Text('Ícono', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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
              decoration: const InputDecoration(
                labelText: 'Nombre del sistema *',
                hintText: 'Ej. Entrenar mi cuerpo',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _identityCtrl,
              decoration: const InputDecoration(
                labelText: 'Identidad',
                hintText: 'Quiero ser una persona que...',
              ),
            ),
            const SizedBox(height: 20),

            _LawLabel(number: '1', title: 'Hazlo obvio · Señal', theme: theme),
            TextField(
              controller: _cueCtrl,
              decoration: const InputDecoration(hintText: 'Cuándo y dónde lo haré'),
            ),
            const SizedBox(height: 16),

            _LawLabel(number: '2', title: 'Hazlo atractivo · Motivación', theme: theme),
            TextField(
              controller: _cravingCtrl,
              decoration: const InputDecoration(hintText: 'Por qué me importa'),
            ),
            const SizedBox(height: 16),

            _LawLabel(number: '3', title: 'Hazlo fácil · Acción *', theme: theme),
            TextField(
              controller: _actionCtrl,
              decoration: const InputDecoration(hintText: 'La versión de 2 minutos'),
            ),
            const SizedBox(height: 16),

            _LawLabel(number: '4', title: 'Hazlo satisfactorio · Recompensa', theme: theme),
            TextField(
              controller: _rewardCtrl,
              decoration: const InputDecoration(hintText: 'Cómo lo celebro'),
            ),
            const SizedBox(height: 20),

            Text('Días objetivo *', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(7, (i) {
                final weekday = i + 1;
                final selected = _days.contains(weekday);
                return FilterChip(
                  label: Text(_dayNames[i]),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    if (selected) {
                      _days.remove(weekday);
                    } else {
                      _days.add(weekday);
                    }
                  }),
                );
              }),
            ),

            const SizedBox(height: 32),
            FilledButton(
              onPressed: loading ? null : _save,
              child: loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEdit ? 'Guardar cambios' : 'Crear sistema'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LawLabel extends StatelessWidget {
  final String number;
  final String title;
  final ThemeData theme;
  const _LawLabel({required this.number, required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              number,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
