import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/user/presentation/provider/user_provider.dart';

// Catálogo de módulos disponibles en la app
const _availableModules = [
  _ModuleMeta(
    id: 'diario',
    label: 'Diario',
    icon: Icons.book_outlined,
    description: 'Registra tus pensamientos y reflexiones.',
  ),
  _ModuleMeta(
    id: 'gym',
    label: 'Gym',
    icon: Icons.fitness_center_outlined,
    description: 'Seguimiento de tus rutinas de entrenamiento.',
  ),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userProv = context.watch<UserProvider>();
    final theme = Theme.of(context);
    final user = userProv.user ?? auth.user;
    final activeModules = user?.modules ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hola, ${user?.displayName ?? 'usuario'} 👋',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text('Tus módulos', style: theme.textTheme.titleMedium),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Módulos activos ───────────────────────────
            if (activeModules.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _EmptyModules(theme: theme),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: activeModules.length,
                  itemBuilder: (context, i) {
                    final meta = _availableModules.firstWhere(
                      (m) => m.id == activeModules[i],
                      orElse: () => _ModuleMeta(
                        id: activeModules[i],
                        label: activeModules[i],
                        icon: Icons.widgets_outlined,
                        description: '',
                      ),
                    );
                    return _ModuleCard(meta: meta, active: true);
                  },
                ),
              ),

            // ── Módulos disponibles para agregar ──────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Text('Agregar módulo', style: theme.textTheme.titleMedium),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _availableModules.where((m) => !activeModules.contains(m.id)).length,
                itemBuilder: (context, i) {
                  final inactive = _availableModules
                      .where((m) => !activeModules.contains(m.id))
                      .toList();
                  final meta = inactive[i];
                  return _ModuleCard(
                    meta: meta,
                    active: false,
                    onTap: () => context.read<UserProvider>().addModule(meta.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _EmptyModules extends StatelessWidget {
  final ThemeData theme;
  const _EmptyModules({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.widgets_outlined,
            size: 40,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Aún no tienes módulos activos',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _ModuleCard extends StatelessWidget {
  final _ModuleMeta meta;
  final bool active;
  final VoidCallback? onTap;

  const _ModuleCard({required this.meta, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: active ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              meta.icon,
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const Spacer(),
            Text(
              meta.label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: active ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              meta.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!active) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Agregar',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _ModuleMeta {
  final String id;
  final String label;
  final IconData icon;
  final String description;

  const _ModuleMeta({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });
}
