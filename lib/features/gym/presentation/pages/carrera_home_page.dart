import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';

import '../../domain/entities/run_activity.dart';
import '../../domain/entities/training_note.dart';
import '../provider/gym_provider.dart';
import '../widgets/add_note_sheet.dart';
import '../widgets/add_run_sheet.dart';
import '../widgets/run_formats.dart';
import 'run_detail_page.dart';

class CarreraHomePage extends StatefulWidget {
  const CarreraHomePage({super.key});

  @override
  State<CarreraHomePage> createState() => _CarreraHomePageState();
}

class _CarreraHomePageState extends State<CarreraHomePage> {
  int _tab = 0; // 0 = Actividades, 1 = Notas

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<GymProvider>().init(uid);
    });
  }

  String get _uid => context.read<AuthProvider>().user?.uid ?? '';

  // ── Actividades ───────────────────────────

  Future<void> _addRun() async {
    final run = await AddRunSheet.show(context);
    if (run == null || !mounted) return;
    await context.read<GymProvider>().createRun(_uid, run);
  }

  void _openRunDetail(RunActivity run) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<GymProvider>(),
          child: RunDetailPage(runId: run.id),
        ),
      ),
    );
  }

  Future<void> _deleteRun(RunActivity run) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar actividad'),
        content: Text(
          '¿Seguro que quieres eliminar "${run.activity}" del '
          '${DateFormat('d MMM y', 'es').format(run.performedAt)}?',
        ),
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
    if (confirmed == true && mounted) {
      await context.read<GymProvider>().deleteRun(_uid, run.id);
    }
  }

  // ── Notas ─────────────────────────────────

  Future<void> _addNote() async {
    final note = await AddNoteSheet.show(context);
    if (note == null || !mounted) return;
    await context.read<GymProvider>().createNote(_uid, note);
  }

  Future<void> _editNote(TrainingNote note) async {
    final updated = await AddNoteSheet.show(context, initial: note);
    if (updated == null || !mounted) return;
    await context.read<GymProvider>().updateNote(_uid, updated);
  }

  Future<void> _deleteNote(TrainingNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text('¿Seguro que quieres eliminar esta nota?'),
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
    if (confirmed == true && mounted) {
      await context.read<GymProvider>().deleteNote(_uid, note.id);
    }
  }

  // ─────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final gym = context.watch<GymProvider>();
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 1200 ? 1000.0 : 800.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrera'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: _tab == 0 ? 'Agregar actividad' : 'Agregar nota',
            onPressed: _tab == 0 ? _addRun : _addNote,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      icon: Icon(Icons.directions_run, size: 18),
                      label: Text('Actividades'),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: Icon(Icons.notes, size: 18),
                      label: Text('Notas'),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
              Expanded(
                child: _tab == 0
                    ? _RunsTab(
                        runs: gym.runs,
                        onAdd: _addRun,
                        onOpen: _openRunDetail,
                        onDelete: _deleteRun,
                      )
                    : _NotesTab(
                        notes: gym.notes,
                        onAdd: _addNote,
                        onEdit: _editNote,
                        onDelete: _deleteNote,
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: width < 700
          ? FloatingActionButton(
              onPressed: _tab == 0 ? _addRun : _addNote,
              tooltip: _tab == 0 ? 'Agregar actividad' : 'Agregar nota',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ─────────────────────────────────────────────
class _RunsTab extends StatelessWidget {
  final List<RunActivity> runs;
  final VoidCallback onAdd;
  final ValueChanged<RunActivity> onOpen;
  final ValueChanged<RunActivity> onDelete;

  const _RunsTab({
    required this.runs,
    required this.onAdd,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (runs.isEmpty) {
      return _EmptyState(
        icon: Icons.directions_run,
        title: 'Aún no hay actividades',
        message:
            'Registra tu primera carrera, caminata o vuelta en bici con el botón +.',
        actionLabel: 'Agregar actividad',
        onAdd: onAdd,
      );
    }

    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final weekRuns = runs
        .where((r) => !r.performedAt.isBefore(startOfWeek))
        .toList();
    final weekKm = weekRuns.fold<double>(0, (sum, r) => sum + r.distanceKm);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: runs.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return _WeekSummary(count: weekRuns.length, km: weekKm);
        }
        final run = runs[i - 1];
        return _RunCard(
          key: ValueKey(run.id),
          run: run,
          onOpen: () => onOpen(run),
          onDelete: () => onDelete(run),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
class _WeekSummary extends StatelessWidget {
  final int count;
  final double km;

  const _WeekSummary({required this.count, required this.km});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insights,
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta semana: $count ${count == 1 ? 'actividad' : 'actividades'} · ${formatDistance(km)}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
IconData activityIcon(String activity) {
  switch (activity.toLowerCase()) {
    case 'caminar':
      return Icons.directions_walk;
    case 'bici':
      return Icons.directions_bike;
    case 'correr':
    case 'trotar':
      return Icons.directions_run;
    default:
      return Icons.fitness_center;
  }
}

class _RunCard extends StatelessWidget {
  final RunActivity run;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _RunCard({
    super.key,
    required this.run,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat(
      'EEE d MMM · HH:mm',
      'es',
    ).format(run.performedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  activityIcon(run.activity),
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${run.activity} · $dateStr',
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDistance(run.distanceKm)} · '
                      '${formatRunDuration(run.durationSeconds)} · '
                      '${formatPace(run.paceSecondsPerKm)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Eliminar actividad',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _NotesTab extends StatelessWidget {
  final List<TrainingNote> notes;
  final VoidCallback onAdd;
  final ValueChanged<TrainingNote> onEdit;
  final ValueChanged<TrainingNote> onDelete;

  const _NotesTab({
    required this.notes,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) {
      return _EmptyState(
        icon: Icons.notes,
        title: 'Aún no hay notas',
        message: 'Escribe cómo te sentiste entrenando; tu bitácora vive aquí.',
        actionLabel: 'Agregar nota',
        onAdd: onAdd,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: notes.length,
      itemBuilder: (context, i) {
        final note = notes[i];
        return _NoteCard(
          key: ValueKey(note.id),
          note: note,
          onEdit: () => onEdit(note),
          onDelete: () => onDelete(note),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
class _NoteCard extends StatelessWidget {
  final TrainingNote note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('EEE d MMM y', 'es').format(note.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(dateStr, style: theme.textTheme.titleSmall),
                  ),
                  if (note.fatigue != null)
                    Chip(
                      label: Text('Fatiga ${note.fatigue}/5'),
                      visualDensity: VisualDensity.compact,
                      labelStyle: theme.textTheme.labelSmall,
                    ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    tooltip: 'Eliminar nota',
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(note.text, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAdd;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 56,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
