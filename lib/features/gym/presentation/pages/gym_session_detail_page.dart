import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/gym_session.dart';
import '../../domain/entities/routine.dart';

/// Detalle de una sesión finalizada (solo lectura).
class GymSessionDetailPage extends StatelessWidget {
  final GymSession session;
  const GymSessionDetailPage({super.key, required this.session});

  static String _durationLabel(GymSession s) {
    if (s.isInProgress) return 'En curso';
    final secs =
        s.durationSeconds ?? s.finishedAt!.difference(s.startedAt).inSeconds;
    final d = Duration(seconds: secs);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  static String _formatWeight(double? w) {
    if (w == null) return '—';
    return w == w.roundToDouble() ? w.toInt().toString() : w.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('EEE d MMM y · HH:mm', 'es');

    return Scaffold(
      appBar: AppBar(
        title: Text('${session.routineEmoji} ${session.routineName}'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Resumen ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      label: 'Inicio',
                      value: fmt.format(session.startedAt),
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      label: 'Fin',
                      value: session.finishedAt == null
                          ? 'En curso'
                          : fmt.format(session.finishedAt!),
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(label: 'Duración', value: _durationLabel(session)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('Registro', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),

              if (session.blocksSnapshot.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    session.isInProgress
                        ? 'La sesión sigue en curso; el registro se guarda al finalizar.'
                        : 'Esta sesión no tiene registro de ejercicios.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),

              ...session.blocksSnapshot.map((b) => _BlockView(block: b)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
class _BlockView extends StatelessWidget {
  final Block block;
  const _BlockView({required this.block});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = (block.label == null || block.label!.trim().isEmpty)
        ? 'Bloque'
        : block.label!;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
                Text(
                  '${block.series} series',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            ...block.exercises.map((e) => _ExerciseView(exercise: e)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _ExerciseView extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseView({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = exercise;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                e.done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: e.done
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.name.isEmpty ? 'Ejercicio' : e.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                e.perSide ? 'Por lado' : 'Peso completo',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
          if (e.notes != null && e.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              e.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
          const SizedBox(height: 8),

          // ── Tabla de series (solo lectura) ──
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
            final s = e.sets[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    child: Text('${i + 1}', style: theme.textTheme.bodyMedium),
                  ),
                  Expanded(
                    child: Text(
                      '${s.reps ?? '—'}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      GymSessionDetailPage._formatWeight(s.weight),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
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
