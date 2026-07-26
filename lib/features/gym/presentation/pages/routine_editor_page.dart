import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';

import '../../domain/entities/routine.dart';
import '../provider/gym_provider.dart';
import '../widgets/block_editor.dart';

class RoutineEditorPage extends StatefulWidget {
  final Routine routine;
  const RoutineEditorPage({super.key, required this.routine});

  @override
  State<RoutineEditorPage> createState() => _RoutineEditorPageState();
}

class _RoutineEditorPageState extends State<RoutineEditorPage> {
  static const _uuid = Uuid();

  late Routine _routine;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _routine = widget.routine;
    _nameCtrl = TextEditingController(text: _routine.name);
    _notesCtrl = TextEditingController(text: _routine.notes ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _update(Routine r) {
    setState(() => _routine = r);
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid != null) context.read<GymProvider>().scheduleSave(uid, r);
  }

  void _addBlock() {
    final block = Block(id: _uuid.v4());
    _update(_routine.copyWith(blocks: [..._routine.blocks, block]));
  }

  void _updateBlock(Block updated) {
    final list = _routine.blocks
        .map((b) => b.id == updated.id ? updated : b)
        .toList();
    _update(_routine.copyWith(blocks: list));
  }

  void _deleteBlock(String id) {
    final list = _routine.blocks.where((b) => b.id != id).toList();
    _update(_routine.copyWith(blocks: list));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_routine.emoji} ${_routine.name.isEmpty ? 'Rutina' : _routine.name}',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la rutina',
                ),
                style: theme.textTheme.titleLarge,
                onChanged: (v) => _update(_routine.copyWith(name: v.trim())),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas',
                  hintText: 'Calentamiento, indicaciones generales…',
                ),
                maxLines: 2,
                minLines: 1,
                onChanged: (v) => _update(_routine.copyWith(notes: v)),
              ),
              const SizedBox(height: 24),

              Text('Bloques', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              if (_routine.blocks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Agrega un bloque para empezar. Un bloque agrupa ejercicios que se hacen en circuito.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),

              ..._routine.blocks.map(
                (b) => BlockEditor(
                  key: ValueKey(b.id),
                  block: b,
                  onChanged: _updateBlock,
                  onDelete: () => _deleteBlock(b.id),
                ),
              ),

              FilledButton.tonalIcon(
                onPressed: _addBlock,
                icon: const Icon(Icons.add),
                label: const Text('Agregar bloque'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
