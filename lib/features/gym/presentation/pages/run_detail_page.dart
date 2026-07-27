import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';

import '../../domain/entities/run_activity.dart';
import '../provider/gym_provider.dart';
import '../widgets/add_run_sheet.dart';
import '../widgets/run_formats.dart';
import 'carrera_home_page.dart' show activityIcon;

/// Detalle de una actividad de carrera (solo lectura, con editar/eliminar).
class RunDetailPage extends StatelessWidget {
  final String runId;
  const RunDetailPage({super.key, required this.runId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gym = context.watch<GymProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    RunActivity? run;
    for (final r in gym.runs) {
      if (r.id == runId) {
        run = r;
        break;
      }
    }

    if (run == null) {
      // La actividad fue eliminada mientras se veía el detalle.
      return Scaffold(
        appBar: AppBar(title: const Text('Actividad')),
        body: const Center(child: Text('Esta actividad ya no existe.')),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 1200 ? 900.0 : 700.0;
    final dateStr = DateFormat(
      "EEEE d 'de' MMMM y · HH:mm",
      'es',
    ).format(run.performedAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(run.activity),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar actividad',
            onPressed: () => _edit(context, uid, run!),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            tooltip: 'Eliminar actividad',
            onPressed: () => _delete(context, uid, run!),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            children: [
              // ── Encabezado ──
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      activityIcon(run.activity),
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(run.activity, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Métricas principales ──
              _MetricGrid(
                metrics: [
                  _Metric(
                    'Distancia',
                    formatDistance(run.distanceKm),
                    Icons.straighten,
                  ),
                  _Metric(
                    'Duración',
                    formatRunDuration(run.durationSeconds),
                    Icons.timer_outlined,
                  ),
                  _Metric(
                    'Ritmo',
                    formatPace(run.paceSecondsPerKm),
                    Icons.speed,
                  ),
                  if (run.steps != null)
                    _Metric('Pasos', '${run.steps}', Icons.directions_walk),
                  if (run.activeCalories != null)
                    _Metric(
                      'Kcal activas',
                      '${run.activeCalories}',
                      Icons.local_fire_department_outlined,
                    ),
                  if (run.totalCalories != null)
                    _Metric(
                      'Kcal totales',
                      '${run.totalCalories}',
                      Icons.local_fire_department,
                    ),
                  if (run.avgHr != null)
                    _Metric(
                      'LPM promedio',
                      '${run.avgHr}',
                      Icons.favorite_outline,
                    ),
                  if (run.maxHr != null)
                    _Metric('LPM máximo', '${run.maxHr}', Icons.favorite),
                  if (run.perceivedFatigue != null)
                    _Metric(
                      'Fatiga',
                      '${run.perceivedFatigue}/5',
                      Icons.battery_alert_outlined,
                    ),
                ],
              ),

              // ── Notas ──
              if (run.notes != null && run.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Notas', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(run.notes!, style: theme.textTheme.bodyMedium),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, String uid, RunActivity run) async {
    final updated = await AddRunSheet.show(context, initial: run);
    if (updated == null || !context.mounted) return;
    await context.read<GymProvider>().updateRun(uid, updated);
  }

  Future<void> _delete(
    BuildContext context,
    String uid,
    RunActivity run,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: const Text('¿Seguro que quieres eliminar esta actividad?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<GymProvider>().deleteRun(uid, run.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}

// ─────────────────────────────────────────────
class _Metric {
  final String label;
  final String value;
  final IconData icon;
  const _Metric(this.label, this.value, this.icon);
}

class _MetricGrid extends StatelessWidget {
  final List<_Metric> metrics;
  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 700 ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 86,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, i) {
        final m = metrics[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(m.icon, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      m.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                m.value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
