import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';

import '../../domain/entities/gym_session.dart';
import '../provider/gym_provider.dart';
import 'gym_session_detail_page.dart';

class GymHistoryPage extends StatefulWidget {
  const GymHistoryPage({super.key});

  @override
  State<GymHistoryPage> createState() => _GymHistoryPageState();
}

class _GymHistoryPageState extends State<GymHistoryPage> {
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
    final sessions = gym.sessions;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekCount = sessions
        .where((s) => !s.startedAt.isBefore(monday))
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de sesiones')),
      body: sessions.isEmpty
          ? const _EmptyState()
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Sesiones totales',
                            value: '${sessions.length}',
                            emoji: '📈',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            label: 'Esta semana',
                            value: '$weekCount',
                            emoji: '🗓️',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ...sessions.map(
                      (s) => _SessionTile(
                        session: s,
                        onOpen: () => _openDetail(s),
                        onDelete: () => _deleteSession(uid, s),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _openDetail(GymSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GymSessionDetailPage(session: session)),
    );
  }

  Future<void> _deleteSession(String uid, GymSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar sesión'),
        content: Text('¿Eliminar la sesión de "${session.routineName}"?'),
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
      await context.read<GymProvider>().deleteSession(uid, session.id);
    }
  }
}

// ─────────────────────────────────────────────
class _SessionTile extends StatelessWidget {
  final GymSession session;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.onOpen,
    required this.onDelete,
  });

  static String durationLabel(GymSession s) {
    if (s.isInProgress) return 'En curso';
    final secs =
        s.durationSeconds ?? s.finishedAt!.difference(s.startedAt).inSeconds;
    final d = Duration(seconds: secs);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat(
      'EEE d MMM · HH:mm',
      'es',
    ).format(session.startedAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(session.routineEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.routineName,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: session.isInProgress
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  durationLabel(session),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: session.isInProgress
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Eliminar sesión',
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
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _StatCard({
    required this.label,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 56,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no hay sesiones',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Inicia una rutina desde su detalle y aquí verás tu historial.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
