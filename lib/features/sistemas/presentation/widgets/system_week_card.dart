import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';

import '../../domain/entities/system.dart';
import '../provider/sistemas_provider.dart';

class SystemWeekCard extends StatelessWidget {
  final System system;
  final VoidCallback onOpen;

  const SystemWeekCard({super.key, required this.system, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sistemas = context.watch<SistemasProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final (done, total) = sistemas.weekProgress(system);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado ──
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Text(system.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          system.name,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (system.action.isNotEmpty)
                          Text(
                            system.action,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.55),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (system.currentStreak > 0) ...[
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 2),
                    Text(
                      '${system.currentStreak}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Fila de la semana ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: sistemas.weekDates.map((day) {
                final scheduled = system.targetDays.contains(day.weekday);
                final done = sistemas.isDone(system.id, day);
                final future = sistemas.isFuture(day);
                return _DayCell(
                  day: day,
                  scheduled: scheduled,
                  done: done,
                  disabled: !scheduled || future,
                  onTap: (!scheduled || future) ? null : () => sistemas.toggleDay(uid, system, day),
                  theme: theme,
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              total == 0 ? 'Sin días objetivo' : '$done de $total días esta semana',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool scheduled;
  final bool done;
  final bool disabled;
  final VoidCallback? onTap;
  final ThemeData theme;

  const _DayCell({
    required this.day,
    required this.scheduled,
    required this.done,
    required this.disabled,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (done) {
      bg = theme.colorScheme.primary;
      fg = Colors.white;
    } else if (!scheduled) {
      bg = Colors.transparent;
      fg = theme.colorScheme.onSurface.withOpacity(0.25);
    } else {
      bg = theme.colorScheme.surfaceVariant;
      fg = theme.colorScheme.onSurface.withOpacity(disabled ? 0.35 : 0.75);
    }

    return Column(
      children: [
        Text(
          System.dayLabel(day.weekday),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: scheduled && !done
                  ? Border.all(color: theme.colorScheme.outline.withOpacity(0.3))
                  : null,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check, size: 18, color: Colors.white)
                  : Text('${day.day}', style: TextStyle(fontSize: 12, color: fg)),
            ),
          ),
        ),
      ],
    );
  }
}
