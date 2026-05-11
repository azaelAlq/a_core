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
    icon: Icons.book_outlined,
    description: 'Registra tus pensamientos.',
    route: AppRoutes.diary,
  ),
  _ModuleMeta(
    id: 'logros',
    label: 'Logros',
    icon: Icons.track_changes_outlined,
    description: 'Hábitos, rachas y medallas.',
    route: AppRoutes.logros,
  ),
  _ModuleMeta(
    id: 'finanzas',
    label: 'Finanzas',
    icon: Icons.account_balance_wallet_outlined,
    description: 'Cuentas, deudas y compromisos.',
    route: AppRoutes.finanzas,
  ),
  _ModuleMeta(
    id: 'libretas',
    label: 'Libretas',
    icon: Icons.menu_book_outlined,
    description: 'Notas y páginas en markdown.',
    route: AppRoutes.libretas,
  ),
  _ModuleMeta(
    id: 'gym',
    label: 'Gym',
    icon: Icons.fitness_center_outlined,
    description: 'Rutinas de entrenamiento.',
    route: null,
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

    // Grid: en móvil 2 columnas fijas, en tablet/desktop maxExtent
    final gridDelegate = isMobile
        ? const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
          )
        : SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isTablet ? 320 : 340,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: 1.18,
          );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
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
                  // ── AppBar manual dentro del scroll ──
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 16 : 24,
                      isMobile ? 16 : 20,
                      isMobile ? 16 : 24,
                      0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hola, ${user?.displayName ?? 'Usuario'} 👋',
                                  style:
                                      (isMobile
                                              ? theme.textTheme.titleLarge
                                              : theme.textTheme.headlineSmall)
                                          ?.copyWith(fontWeight: FontWeight.w800),
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
                          ),
                          IconButton(
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
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(.08),
                                ),
                              ),
                              child: const Icon(Icons.logout_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 20 : 28)),

                  // ── Hero ──
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                    sliver: SliverToBoxAdapter(
                      child: _DashboardHero(
                        activeModules: activeModules.length,
                        isMobile: isMobile,
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 28 : 36)),

                  // ── Módulos activos ──
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Tus módulos',
                        subtitle: 'Accede rápidamente a tus herramientas.',
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 14 : 18)),

                  if (activeModules.isEmpty)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                      sliver: SliverToBoxAdapter(child: _EmptyModules(theme: theme)),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                      sliver: SliverGrid.builder(
                        gridDelegate: gridDelegate,
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
                            isMobile: isMobile,
                            onTap: meta.route != null ? () => context.go(meta.route!) : null,
                          );
                        },
                      ),
                    ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 32 : 44)),

                  // ── Agregar módulo ──
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
                    sliver: SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: 'Agregar módulo',
                        subtitle: 'Expande tu espacio personal.',
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: SizedBox(height: isMobile ? 14 : 18)),

                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 0, isMobile ? 16 : 24, 40),
                    sliver: SliverGrid.builder(
                      gridDelegate: gridDelegate,
                      itemCount: inactiveModules.length,
                      itemBuilder: (context, i) {
                        return _ModuleCard(
                          meta: inactiveModules[i],
                          active: false,
                          isMobile: isMobile,
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

// ─── Hero ────────────────────────────────────────────────────────────────
class _DashboardHero extends StatelessWidget {
  final int activeModules;
  final bool isMobile;

  const _DashboardHero({required this.activeModules, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
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
                  style: (isMobile ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)
                      ?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                Text(
                  'Organiza tu vida, hábitos, finanzas y progreso en un solo lugar.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withOpacity(.82),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroBadge(
                      icon: Icons.dashboard_customize_rounded,
                      label: '$activeModules módulos',
                      isMobile: isMobile,
                    ),
                    _HeroBadge(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Racha activa',
                      isMobile: isMobile,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
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
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isMobile;

  const _HeroBadge({required this.icon, required this.label, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: isMobile ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 15 : 18, color: Colors.white),
          SizedBox(width: isMobile ? 6 : 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ──────────────────────────────────────────────────────
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

// ─── Empty ───────────────────────────────────────────────────────────────
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

// ─── Module card ─────────────────────────────────────────────────────────
class _ModuleCard extends StatefulWidget {
  final _ModuleMeta meta;
  final bool active;
  final bool isMobile;
  final VoidCallback? onTap;

  const _ModuleCard({required this.meta, required this.active, required this.isMobile, this.onTap});

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = widget.isMobile ? 14.0 : 22.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: hovering ? 1.02 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.isMobile ? 20 : 28),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.all(p),
            decoration: BoxDecoration(
              color: widget.active ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(widget.isMobile ? 20 : 28),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícono
                Container(
                  padding: EdgeInsets.all(widget.isMobile ? 10 : 14),
                  decoration: BoxDecoration(
                    color: widget.active
                        ? theme.colorScheme.primary.withOpacity(.12)
                        : theme.colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(widget.isMobile ? 14 : 18),
                  ),
                  child: Icon(
                    widget.meta.icon,
                    size: widget.isMobile ? 22 : 26,
                    color: widget.active
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(.7),
                  ),
                ),

                SizedBox(height: widget.isMobile ? 12 : 16),

                // Nombre
                Text(
                  widget.meta.label,
                  style:
                      (widget.isMobile ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: widget.active
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                ),

                SizedBox(height: widget.isMobile ? 4 : 8),

                // Descripción
                if (!widget.isMobile)
                  Text(
                    widget.meta.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: widget.active
                          ? theme.colorScheme.onPrimaryContainer.withOpacity(.7)
                          : theme.colorScheme.onSurface.withOpacity(.65),
                      height: 1.45,
                    ),
                    maxLines: 2,
                  ),

                SizedBox(height: widget.isMobile ? 10 : 18),

                // CTA
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.active ? 'Abrir' : 'Agregar',
                        style:
                            (widget.isMobile
                                    ? theme.textTheme.labelMedium
                                    : theme.textTheme.labelLarge)
                                ?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      widget.active ? Icons.arrow_forward_rounded : Icons.add_rounded,
                      size: widget.isMobile ? 15 : 18,
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

// ─── Meta ────────────────────────────────────────────────────────────────
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
