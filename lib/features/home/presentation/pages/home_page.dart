import 'package:a_core/features/diario/presentation/provider/diary_provider.dart';
import 'package:a_core/features/finanzas/presentation/provider/finanzas_provider.dart';
import 'package:a_core/features/logros/presentation/provider/logros_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:a_core/core/routes/app_router.dart';
import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/user/presentation/provider/user_provider.dart';

const _allModules = [
  _ModuleMeta(
    id: 'diario',
    label: 'Diario',
    icon: Icons.book_rounded,
    description: 'Registra pensamientos, emociones y reflexiones.',
    route: AppRoutes.diary,
  ),
  _ModuleMeta(
    id: 'logros',
    label: 'Logros',
    icon: Icons.workspace_premium_rounded,
    description: 'Hábitos, medallas, rachas y progreso.',
    route: AppRoutes.logros,
  ),
  _ModuleMeta(
    id: 'gym',
    label: 'Gym',
    icon: Icons.fitness_center_rounded,
    description: 'Rutinas, ejercicios y evolución física.',
    route: null,
  ),
  _ModuleMeta(
    id: 'finanzas',
    label: 'Finanzas',
    icon: Icons.account_balance_wallet_rounded,
    description: 'Controla gastos, ingresos y ahorros.',
    route: AppRoutes.finanzas,
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

    final width = MediaQuery.of(context).size.width;

    final isMobile = width < 700;
    final isTablet = width >= 700 && width < 1200;
    final isDesktop = width >= 1200;

    final inactiveModules = _allModules.where((m) => !activeModules.contains(m.id)).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 80,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${user?.displayName ?? 'Usuario'} 👋',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Bienvenido de nuevo',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(.6),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                context.read<DiaryProvider>().clear();
                context.read<LogrosProvider>().clear();
                context.read<FinanzasProvider>().clear();
                context.read<UserProvider>().stopWatching();

                await Future.microtask(() {});

                await context.read<AuthProvider>().signOut();
              },
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(.08)),
                ),
                child: const Icon(Icons.logout_rounded),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.colorScheme.background, theme.colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1450 : 1100),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // HEADER DASHBOARD
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: _DashboardHero(activeModules: activeModules.length),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 36)),

                  // ACTIVOS
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Tus módulos',
                        subtitle: 'Accede rápidamente a tus herramientas.',
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 18)),

                  if (activeModules.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(child: _EmptyModules(theme: theme)),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isMobile
                              ? 260
                              : isTablet
                              ? 320
                              : 340,
                          crossAxisSpacing: 18,
                          mainAxisSpacing: 18,
                          childAspectRatio: isMobile ? 1.08 : 1.18,
                        ),
                        itemCount: activeModules.length,
                        itemBuilder: (context, i) {
                          final meta = _allModules.firstWhere(
                            (m) => m.id == activeModules[i],
                            orElse: () => _ModuleMeta(
                              id: activeModules[i],
                              label: activeModules[i],
                              icon: Icons.widgets_rounded,
                              description: '',
                              route: null,
                            ),
                          );

                          return _ModuleCard(
                            meta: meta,
                            active: true,
                            onTap: meta.route != null ? () => context.go(meta.route!) : null,
                          );
                        },
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 44)),

                  // AGREGAR
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Agregar módulo',
                        subtitle: 'Expande tu espacio personal.',
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 18)),

                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: isMobile
                            ? 260
                            : isTablet
                            ? 320
                            : 340,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        childAspectRatio: isMobile ? 1.08 : 1.18,
                      ),
                      itemCount: inactiveModules.length,
                      itemBuilder: (context, i) {
                        return _ModuleCard(
                          meta: inactiveModules[i],
                          active: false,
                          onTap: () {
                            context.read<UserProvider>().addModule(inactiveModules[i].id);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final int activeModules;

  const _DashboardHero({required this.activeModules});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(.82)],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(.22),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu espacio personal',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Organiza tu vida, hábitos, finanzas y progreso en un solo lugar.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(.82),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _HeroBadge(
                      icon: Icons.dashboard_customize_rounded,
                      label: '$activeModules módulos',
                    ),
                    const _HeroBadge(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Racha activa',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.space_dashboard_rounded, size: 48, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.6),
          ),
        ),
      ],
    );
  }
}

class _EmptyModules extends StatelessWidget {
  final ThemeData theme;

  const _EmptyModules({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.dashboard_customize_rounded,
              size: 42,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aún no tienes módulos activos',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Empieza agregando uno abajo para personalizar tu espacio.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(.6),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final _ModuleMeta meta;
  final bool active;
  final VoidCallback? onTap;

  const _ModuleCard({required this.meta, required this.active, this.onTap});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: hovering ? 1.02 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: widget.active ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: widget.active
                    ? theme.colorScheme.primary.withOpacity(.15)
                    : theme.colorScheme.outline.withOpacity(.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(hovering ? .08 : .04),
                  blurRadius: hovering ? 30 : 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.active
                        ? theme.colorScheme.primary.withOpacity(.12)
                        : theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    widget.meta.icon,
                    size: 26,
                    color: widget.active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(.7),
                  ),
                ),

                const Spacer(),

                Text(
                  widget.meta.label,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 10),

                Text(
                  widget.meta.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(.65),
                    height: 1.45,
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 22),

                Row(
                  children: [
                    Text(
                      widget.active ? 'Abrir módulo' : 'Agregar módulo',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      widget.active ? Icons.arrow_forward_rounded : Icons.add_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleMeta {
  final String id;
  final String label;
  final IconData icon;
  final String description;
  final String? route;

  const _ModuleMeta({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
    required this.route,
  });
}
