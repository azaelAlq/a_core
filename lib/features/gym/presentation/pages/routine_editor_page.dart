import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';

import '../../domain/entities/gym_session.dart';
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
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _routine = widget.routine;
    _nameCtrl = TextEditingController(text: _routine.name);
    _notesCtrl = TextEditingController(text: _routine.notes ?? '');
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _uid => context.read<AuthProvider>().user?.uid ?? '';

  void _update(Routine r) {
    setState(() => _routine = r);
    if (_uid.isNotEmpty) context.read<GymProvider>().scheduleSave(_uid, r);
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

  // ── Sesión ────────────────────────────────

  /// Mantiene el cronómetro corriendo solo mientras hay sesión activa.
  void _syncTicker(bool active) {
    if (active && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!active && _ticker != null) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _uncheckAll() async {
    final updated = await context.read<GymProvider>().uncheckAllCompleted(
      _uid,
      _routine,
    );
    if (mounted) setState(() => _routine = updated);
  }

  static String _formatElapsed(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gym = context.watch<GymProvider>();
    final active = gym.activeSessionFor(_routine.id);
    _syncTicker(active != null);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_routine.emoji} ${_routine.name.isEmpty ? 'Rutina' : _routine.name}',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // ── Barra de sesión fija ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _SessionBar(
                  active: active,
                  elapsed: active == null
                      ? null
                      : _formatElapsed(
                          DateTime.now().difference(active.startedAt),
                        ),
                  onStart: () => gym.startRoutine(_uid, _routine),
                  onFinish: () => gym.finishRoutine(_uid, _routine),
                  onUncheckAll: _uncheckAll,
                ),
              ),

              // ── Contenido scrolleable ──
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la rutina',
                      ),
                      style: theme.textTheme.titleLarge,
                      onChanged: (v) =>
                          _update(_routine.copyWith(name: v.trim())),
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _SessionBar extends StatelessWidget {
  final GymSession? active;
  final String? elapsed;
  final VoidCallback onStart;
  final VoidCallback onFinish;
  final VoidCallback onUncheckAll;

  const _SessionBar({
    required this.active,
    required this.elapsed,
    required this.onStart,
    required this.onFinish,
    required this.onUncheckAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inProgress = active != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: inProgress
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (inProgress) ...[
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  elapsed ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'En curso',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(
                      0.7,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: inProgress ? null : onStart,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Iniciar rutina'),
              ),
              FilledButton.tonalIcon(
                onPressed: inProgress ? onFinish : null,
                icon: const Icon(Icons.stop, size: 18),
                label: const Text('Finalizar'),
              ),
              OutlinedButton.icon(
                onPressed: onUncheckAll,
                icon: const Icon(Icons.remove_done, size: 18),
                label: const Text('Desmarcar completados'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
