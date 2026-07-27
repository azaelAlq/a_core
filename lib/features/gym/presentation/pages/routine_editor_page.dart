import 'dart:async';

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

  Future<void> _uncheckAll() async {
    final updated = await context.read<GymProvider>().uncheckAllCompleted(
      _uid,
      _routine,
    );
    if (mounted) setState(() => _routine = updated);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Solo se reconstruye esta página cuando cambia si hay sesión activa
    // o cuándo empezó, no ante cualquier otro cambio del provider
    // (p. ej. el propio guardado con debounce de esta misma rutina).
    final (sessionActive, sessionStartedAt) = context
        .select<GymProvider, (bool, DateTime?)>((gym) {
          final active = gym.activeSessionFor(_routine.id);
          return (active != null, active?.startedAt);
        });

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
                  active: sessionActive,
                  startedAt: sessionStartedAt,
                  onStart: () =>
                      context.read<GymProvider>().startRoutine(_uid, _routine),
                  onFinish: () =>
                      context.read<GymProvider>().finishRoutine(_uid, _routine),
                  onUncheckAll: _uncheckAll,
                ),
              ),

              // ── Contenido scrolleable ──
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  // Encabezado (nombre + notas + título) + bloques + botón agregar.
                  itemCount: _routine.blocks.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) return _buildHeader(theme);

                    if (index == _routine.blocks.length + 1) {
                      return FilledButton.tonalIcon(
                        onPressed: _addBlock,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar bloque'),
                      );
                    }

                    final block = _routine.blocks[index - 1];
                    return BlockEditor(
                      key: ValueKey(block.id),
                      block: block,
                      onChanged: _updateBlock,
                      onDelete: () => _deleteBlock(block.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Nombre de la rutina'),
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
      ],
    );
  }
}

// ─────────────────────────────────────────────
/// Breakpoints locales (móvil <700, tablet 700–1199, desktop ≥1200),
/// siguiendo el mismo criterio usado en otras pantallas del proyecto.
class _SessionBar extends StatelessWidget {
  final bool active;
  final DateTime? startedAt;
  final VoidCallback onStart;
  final VoidCallback onFinish;
  final VoidCallback onUncheckAll;

  const _SessionBar({
    required this.active,
    required this.startedAt,
    required this.onStart,
    required this.onFinish,
    required this.onUncheckAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (active) ...[
            // Chip compacto del cronómetro en su propia línea: el único
            // widget que se reconstruye cada segundo (ver _ElapsedClock).
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  _ElapsedClock(
                    startedAt: startedAt!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 6),
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
            ),
            const SizedBox(height: 10),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SessionActionButton(
                icon: Icons.play_arrow,
                label: 'Iniciar rutina',
                shortLabel: 'Iniciar',
                compact: isMobile,
                variant: _ButtonVariant.filled,
                onPressed: active ? null : onStart,
              ),
              _SessionActionButton(
                icon: Icons.stop,
                label: 'Finalizar rutina',
                shortLabel: 'Finalizar',
                compact: isMobile,
                variant: _ButtonVariant.tonal,
                onPressed: active ? onFinish : null,
              ),
              _SessionActionButton(
                icon: Icons.remove_done,
                label: 'Desmarcar completados',
                shortLabel: 'Desmarcar',
                compact: isMobile,
                variant: _ButtonVariant.outlined,
                onPressed: onUncheckAll,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _ButtonVariant { filled, tonal, outlined }

/// Botón compacto para la barra de sesión: en móvil usa densidad
/// compacta y texto corto; en tablet/desktop, texto completo.
/// Mantiene un alto mínimo de 44 para un área de toque cómoda.
class _SessionActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String shortLabel;
  final bool compact;
  final _ButtonVariant variant;
  final VoidCallback? onPressed;

  const _SessionActionButton({
    required this.icon,
    required this.label,
    required this.shortLabel,
    required this.compact,
    required this.variant,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: 8),
      ),
      textStyle: WidgetStatePropertyAll(
        Theme.of(context).textTheme.labelMedium,
      ),
    );
    final iconWidget = Icon(icon, size: 18);
    final labelWidget = Text(
      compact ? shortLabel : label,
      overflow: TextOverflow.ellipsis,
    );

    switch (variant) {
      case _ButtonVariant.filled:
        return FilledButton.icon(
          onPressed: onPressed,
          icon: iconWidget,
          label: labelWidget,
          style: style,
        );
      case _ButtonVariant.tonal:
        return FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: iconWidget,
          label: labelWidget,
          style: style,
        );
      case _ButtonVariant.outlined:
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: iconWidget,
          label: labelWidget,
          style: style,
        );
    }
  }
}

/// Aísla el "tick" del cronómetro: solo este texto se reconstruye cada
/// segundo, no el resto de la página (nombre, notas, bloques, etc.).
class _ElapsedClock extends StatefulWidget {
  final DateTime startedAt;
  final TextStyle? style;

  const _ElapsedClock({required this.startedAt, required this.style});

  @override
  State<_ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<_ElapsedClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(DateTime.now().difference(widget.startedAt)),
      style: widget.style,
    );
  }
}
