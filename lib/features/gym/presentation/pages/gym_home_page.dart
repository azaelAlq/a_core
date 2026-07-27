import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:a_core/core/routes/app_router.dart';
import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';

import '../../domain/entities/routine.dart';
import '../provider/gym_provider.dart';
import 'routine_editor_page.dart';

class GymHomePage extends StatefulWidget {
  const GymHomePage({super.key});

  @override
  State<GymHomePage> createState() => _GymHomePageState();
}

class _GymHomePageState extends State<GymHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<GymProvider>().init(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gym = context.watch<GymProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';

    final width = MediaQuery.of(context).size.width;
    final columns = width >= 1200 ? 3 : (width >= 700 ? 2 : 1);
    final isMobile = width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.directions_run),
            tooltip: 'Carrera',
            onPressed: () => context.push(AppRoutes.gymCarrera),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de sesiones',
            onPressed: () => context.push(AppRoutes.gymHistory),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createRoutine(uid),
          ),
        ],
      ),
      body: gym.routines.isEmpty
          ? _EmptyState(onAdd: () => _createRoutine(uid))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: columns == 1
                    ? ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: gym.routines.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) =>
                            _card(gym.routines[i], uid),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 120,
                        ),
                        itemCount: gym.routines.length,
                        itemBuilder: (context, i) =>
                            _card(gym.routines[i], uid),
                      ),
              ),
            ),
      floatingActionButton: isMobile && gym.routines.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _createRoutine(uid),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _card(Routine routine, String uid) {
    return _RoutineCard(
      routine: routine,
      onOpen: () => _openEditor(routine),
      onDelete: () => _deleteRoutine(uid, routine),
    );
  }

  Future<void> _createRoutine(String uid) async {
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva rutina'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej. Pierna · Lunes',
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(nameCtrl.text),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;

    final routine = await context.read<GymProvider>().createRoutine(
      uid,
      name: name.trim(),
    );
    if (routine != null && mounted) _openEditor(routine);
  }

  void _openEditor(Routine routine) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<GymProvider>(),
          child: RoutineEditorPage(routine: routine),
        ),
      ),
    );
  }

  Future<void> _deleteRoutine(String uid, Routine routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar rutina'),
        content: Text('¿Seguro que quieres eliminar "${routine.name}"?'),
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
      await context.read<GymProvider>().deleteRoutine(uid, routine.id);
    }
  }
}

// ─────────────────────────────────────────────
class _RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.routine,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = routine.blocks.length;
    final e = routine.totalExercises;
    final summary =
        '$b ${b == 1 ? 'bloque' : 'bloques'} · $e ${e == 1 ? 'ejercicio' : 'ejercicios'}';

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(routine.emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      summary,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
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
                tooltip: 'Eliminar rutina',
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
            Icons.fitness_center_outlined,
            size: 56,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes rutinas',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Crea tu primera rutina y edítala como una libreta de entrenamiento.',
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
            label: const Text('Crear primera rutina'),
          ),
        ],
      ),
    );
  }
}
