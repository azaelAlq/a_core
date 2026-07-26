import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';

import '../../domain/entities/system.dart';
import '../../domain/entities/system_log.dart';
import '../provider/sistemas_provider.dart';
import '../widgets/create_system_sheet.dart';

class SystemDetailPage extends StatelessWidget {
  final System system;
  const SystemDetailPage({super.key, required this.system});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final sistemas = context.watch<SistemasProvider>();

    // Toma la versión más reciente del sistema desde el provider
    final current = sistemas.systems.firstWhere((s) => s.id == system.id, orElse: () => system);

    return Scaffold(
      appBar: AppBar(
        title: Text('${current.emoji} ${current.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context, uid, current),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: () => _delete(context, uid, current),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (current.identity != null && current.identity!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IDENTIDAD',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(current.identity!, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Rachas
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Racha actual',
                  value: '${current.currentStreak}',
                  emoji: '🔥',
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Mejor racha',
                  value: '${current.longestStreak}',
                  emoji: '🏆',
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text('Las 4 leyes', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _LawRow(n: '1', title: 'Hazlo obvio', value: current.cue, theme: theme),
          _LawRow(n: '2', title: 'Hazlo atractivo', value: current.craving, theme: theme),
          _LawRow(n: '3', title: 'Hazlo fácil', value: current.action, theme: theme),
          _LawRow(n: '4', title: 'Hazlo satisfactorio', value: current.reward, theme: theme),

          const SizedBox(height: 20),
          Text('Días objetivo', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (i) {
              final weekday = i + 1;
              final active = current.targetDays.contains(weekday);
              return Chip(
                label: Text(System.dayLabel(weekday)),
                backgroundColor: active
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceVariant,
              );
            }),
          ),

          const SizedBox(height: 24),
          Text('Historial', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _History(uid: uid, system: current),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, String uid, System s) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SistemasProvider>(),
        child: CreateSystemSheet(uid: uid, system: s),
      ),
    );
  }

  Future<void> _delete(BuildContext context, String uid, System s) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar sistema'),
        content: const Text('¿Seguro? Se perderá todo el historial.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true) {
      await context.read<SistemasProvider>().deleteSystem(uid, s.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final ThemeData theme;
  const _StatCard({
    required this.label,
    required this.value,
    required this.emoji,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('$emoji $value', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _LawRow extends StatelessWidget {
  final String n;
  final String title;
  final String? value;
  final ThemeData theme;
  const _LawRow({required this.n, required this.title, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(n, style: theme.textTheme.labelSmall),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary),
                ),
                Text(
                  (value == null || value!.isEmpty) ? '—' : value!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  final String uid;
  final System system;
  const _History({required this.uid, required this.system});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prov = context.read<SistemasProvider>();

    return StreamBuilder<List<SystemLog>>(
      stream: prov.historyStream(uid, system.id),
      builder: (context, snap) {
        final done = <DateTime>{
          for (final l in (snap.data ?? []))
            if (l.done) DateTime(l.date.year, l.date.month, l.date.day),
        };

        // Últimas 8 semanas (columnas = semanas, filas = L..D)
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final thisMonday = today.subtract(Duration(days: today.weekday - 1));
        const weeks = 8;
        final firstMonday = thisMonday.subtract(const Duration(days: 7 * (weeks - 1)));

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(7, (row) {
              final weekday = row + 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        System.dayLabel(weekday),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    ...List.generate(weeks, (col) {
                      final cellDate = firstMonday.add(Duration(days: col * 7 + row));
                      final scheduled = system.targetDays.contains(cellDate.weekday);
                      final isDone = done.contains(cellDate);
                      final future = cellDate.isAfter(today);
                      Color color;
                      if (isDone) {
                        color = theme.colorScheme.primary;
                      } else if (!scheduled || future) {
                        color = theme.colorScheme.surfaceVariant.withOpacity(0.4);
                      } else {
                        color = theme.colorScheme.error.withOpacity(0.15);
                      }
                      return Container(
                        margin: const EdgeInsets.all(2),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
