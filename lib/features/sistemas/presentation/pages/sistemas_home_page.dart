import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:a_core/core/routes/app_router.dart';
import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';

import '../../domain/entities/system.dart';
import '../provider/sistemas_provider.dart';
import '../widgets/create_system_sheet.dart';
import '../widgets/system_week_card.dart';
import 'system_detail_page.dart';

class SistemasHomePage extends StatefulWidget {
  const SistemasHomePage({super.key});

  @override
  State<SistemasHomePage> createState() => _SistemasHomePageState();
}

class _SistemasHomePageState extends State<SistemasHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<SistemasProvider>().init(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sistemas = context.watch<SistemasProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final theme = Theme.of(context);

    final width = MediaQuery.of(context).size.width;
    final columns = width >= 1200 ? 3 : (width >= 700 ? 2 : 1);
    final isMobile = width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistemas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreateSheet(context, uid)),
        ],
      ),
      body: sistemas.systems.isEmpty
          ? _EmptyState(onAdd: () => _showCreateSheet(context, uid))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _WeekHeader(sistemas: sistemas, theme: theme),
                    ),
                    SliverToBoxAdapter(
                      child: _WeekSummary(progress: sistemas.overallWeekProgress, theme: theme),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 100),
                      sliver: columns == 1
                          ? SliverList.separated(
                              itemCount: sistemas.systems.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, i) => _card(context, uid, sistemas.systems[i]),
                            )
                          : SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                mainAxisExtent: 210,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => _card(context, uid, sistemas.systems[i]),
                                childCount: sistemas.systems.length,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: isMobile && sistemas.systems.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showCreateSheet(context, uid),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _card(BuildContext context, String uid, System system) {
    return SystemWeekCard(system: system, onOpen: () => _openDetail(context, system));
  }

  Future<void> _showCreateSheet(BuildContext context, String uid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SistemasProvider>(),
        child: CreateSystemSheet(uid: uid),
      ),
    );
  }

  void _openDetail(BuildContext context, System system) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<SistemasProvider>(),
          child: SystemDetailPage(system: system),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _WeekHeader extends StatelessWidget {
  final SistemasProvider sistemas;
  final ThemeData theme;
  const _WeekHeader({required this.sistemas, required this.theme});

  @override
  Widget build(BuildContext context) {
    final start = sistemas.selectedWeekStart;
    final end = start.add(const Duration(days: 6));
    final fmt = DateFormat('d MMM', 'es');
    final label = sistemas.isCurrentWeek
        ? 'Esta semana'
        : '${fmt.format(start)} – ${fmt.format(end)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: sistemas.previousWeek),
          Expanded(
            child: GestureDetector(
              onTap: sistemas.goToCurrentWeek,
              child: Column(
                children: [
                  Text(label, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                  Text(
                    '${fmt.format(start)} – ${fmt.format(end)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: sistemas.nextWeek),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _WeekSummary extends StatelessWidget {
  final double progress;
  final ThemeData theme;
  const _WeekSummary({required this.progress, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
          Text(
            'Consistencia de la semana',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}%',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
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
            progress >= 1.0 ? '¡Semana perfecta! 🎉' : 'Sigue apareciendo, no rompas la cadena.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
        ],
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
          Icon(Icons.hub_outlined, size: 56, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Aún no tienes sistemas',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No subes al nivel de tus metas, caes al nivel de tus sistemas.',
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
            label: const Text('Crear primer sistema'),
          ),
        ],
      ),
    );
  }
}
