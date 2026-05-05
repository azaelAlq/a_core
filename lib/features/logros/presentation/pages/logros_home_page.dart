import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:a_core/core/routes/app_router.dart';
import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';

import '../../domain/entities/habit.dart';
import '../provider/logros_provider.dart';
import '../widgets/achievement_banner.dart';
import '../widgets/create_habit_sheet.dart';
import '../widgets/log_habit_sheet.dart';

class LogrosHomePage extends StatefulWidget {
  const LogrosHomePage({super.key});

  @override
  State<LogrosHomePage> createState() => _LogrosHomePageState();
}

class _LogrosHomePageState extends State<LogrosHomePage> {
  String? _selectedHabitId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<LogrosProvider>().init(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final logros = context.watch<LogrosProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final theme = Theme.of(context);
    final today = DateTime.now();
    final completedToday = logros.habits.where((h) => logros.isCompletedToday(h.id)).length;
    final total = logros.habits.length;

    // Banner de logro desbloqueado
    if (logros.newAchievement != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          builder: (_) => AchievementBanner(
            achievement: logros.newAchievement!,
            onClose: () {
              Navigator.of(context, rootNavigator: true).pop();
              logros.clearNewAchievement();
            },
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hábitos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreateSheet(context, uid)),
        ],
      ),
      body: logros.habits.isEmpty
          ? _EmptyState(onAdd: () => _showCreateSheet(context, uid))
          : CustomScrollView(
              slivers: [
                // ── Resumen del día ───────────────
                SliverToBoxAdapter(
                  child: _DaySummary(
                    completed: completedToday,
                    total: total,
                    date: today,
                    theme: theme,
                  ),
                ),

                // ── Selector de hábito para calendario ──
                SliverToBoxAdapter(
                  child: _HabitSelector(
                    habits: logros.habits,
                    selectedId: _selectedHabitId,
                    onSelected: (id) => setState(() => _selectedHabitId = id),
                  ),
                ),

                // ── Calendario del hábito seleccionado ──
                if (_selectedHabitId != null)
                  SliverToBoxAdapter(
                    child: _HabitCalendar(habitId: _selectedHabitId!, uid: uid),
                  ),

                // ── Lista de hábitos de hoy ───────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Text('Hoy', style: theme.textTheme.titleMedium),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList.separated(
                    itemCount: logros.habits.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final habit = logros.habits[i];
                      final completed = logros.isCompletedToday(habit.id);
                      final log = logros.logForDay(habit.id, today);
                      return _HabitTile(
                        habit: habit,
                        completed: completed,
                        value: log?.value,
                        streak: habit.currentStreak,
                        onTap: () => _showLogSheet(context, uid, habit),
                        onDelete: () => logros.deleteHabit(uid, habit.id),
                        onNavigate: () {
                          setState(() => _selectedHabitId = habit.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context, String uid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<LogrosProvider>(),
        child: CreateHabitSheet(uid: uid),
      ),
    );
  }

  Future<void> _showLogSheet(BuildContext context, String uid, Habit habit) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<LogrosProvider>(),
        child: LogHabitSheet(uid: uid, habit: habit),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _DaySummary extends StatelessWidget {
  final int completed;
  final int total;
  final DateTime date;
  final ThemeData theme;

  const _DaySummary({
    required this.completed,
    required this.total,
    required this.date,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    final dateStr = DateFormat('EEEE d MMMM', 'es').format(date);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateStr, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            '$completed de $total hábitos',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress == 1.0 ? '¡Día perfecto! 🎉' : '${(progress * 100).toInt()}% completado',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _HabitSelector extends StatelessWidget {
  final List<Habit> habits;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _HabitSelector({required this.habits, required this.selectedId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Calendario por hábito', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: habits.map((h) {
                final selected = selectedId == h.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${h.emoji} ${h.name}'),
                    selected: selected,
                    onSelected: (_) => onSelected(selected ? null : h.id),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _HabitCalendar extends StatelessWidget {
  final String habitId;
  final String uid;

  const _HabitCalendar({required this.habitId, required this.uid});

  @override
  Widget build(BuildContext context) {
    final logros = context.watch<LogrosProvider>();
    final completedDays = logros.completedDaysFor(habitId);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        child: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.now(),
          focusedDay: logros.selectedMonth,
          calendarFormat: CalendarFormat.month,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: theme.textTheme.titleSmall!,
          ),
          onPageChanged: (focused) => logros.changeMonth(uid, focused),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focused) {
              final d = DateTime(day.year, day.month, day.day);
              final done = completedDays.contains(d);
              if (!done) return null;
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            todayBuilder: (context, day, focused) {
              final d = DateTime(day.year, day.month, day.day);
              final done = completedDays.contains(d);
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: done ? theme.colorScheme.primary : theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: done ? Colors.white : theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _HabitTile extends StatelessWidget {
  final Habit habit;
  final bool completed;
  final double? value;
  final int streak;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onNavigate;

  const _HabitTile({
    required this.habit,
    required this.completed,
    required this.streak,
    required this.onTap,
    required this.onDelete,
    required this.onNavigate,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: completed ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(completed ? '✅' : habit.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
        ),
        title: Text(habit.name, style: theme.textTheme.titleSmall),
        subtitle: Row(
          children: [
            if (streak > 0) ...[
              const Text('🔥', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 2),
              Text(
                '$streak días',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 8),
            ],
            if (habit.type != HabitType.yesNo && value != null)
              Text(
                '${value!.toInt()} ${habit.unit ?? ''}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              useRootNavigator: true,
              builder: (ctx) => AlertDialog(
                title: const Text('Eliminar hábito'),
                content: const Text('¿Seguro? Se perderá todo el historial.'),
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
            if (confirmed == true) onDelete();
          },
        ),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.track_changes_outlined,
            size: 56,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin hábitos todavía',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Crear primer hábito'),
          ),
        ],
      ),
    );
  }
}
