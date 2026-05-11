// ── libreta_detalle_page.dart (rediseñado) ─────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // agrega google_fonts al pubspec

import 'package:a_core/core/routes/app_router.dart';
import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/libretas/domain/entities/libreta.dart';
import 'package:a_core/features/libretas/domain/entities/pagina.dart';
import 'package:a_core/features/libretas/presentation/provider/libretas_provider.dart';

// ─── Página principal ───────────────────────────────────────────────────
class LibretaDetallePage extends StatefulWidget {
  final Libreta libreta;
  const LibretaDetallePage({super.key, required this.libreta});

  @override
  State<LibretaDetallePage> createState() => _LibretaDetallePageState();
}

class _LibretaDetallePageState extends State<LibretaDetallePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      context.read<LibretasProvider>().watchPaginas(uid, widget.libreta.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<LibretasProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final roots = prov.rootsDe(widget.libreta.id);
    final accent = Color(int.parse('FF${widget.libreta.color}', radix: 16));
    final isWide = MediaQuery.of(context).size.width > 640;

    if (isWide) {
      return _WideLayout(
        libreta: widget.libreta,
        roots: roots,
        uid: uid,
        prov: prov,
        accent: accent,
        onCreatePagina: (parent) => _createPagina(context, uid, parent),
      );
    }

    return _NarrowLayout(
      libreta: widget.libreta,
      roots: roots,
      uid: uid,
      prov: prov,
      accent: accent,
      onCreatePagina: (parent) => _createPagina(context, uid, parent),
    );
  }

  Future<void> _createPagina(BuildContext context, String uid, Pagina? parent) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(parent == null ? 'Nueva página' : 'Sub-página en "${parent.titulo}"'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Título'),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    final pagina = await context.read<LibretasProvider>().createPagina(
      userId: uid,
      libretaId: widget.libreta.id,
      titulo: ctrl.text.trim(),
      parentId: parent?.id,
    );
    if (pagina != null && mounted) {
      context.push(AppRoutes.paginaEditor, extra: {'pagina': pagina, 'libreta': widget.libreta});
    }
  }
}

// ─── Wide layout ────────────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final Libreta libreta;
  final List<Pagina> roots;
  final String uid;
  final LibretasProvider prov;
  final Color accent;
  final Function(Pagina?) onCreatePagina;

  const _WideLayout({
    required this.libreta,
    required this.roots,
    required this.uid,
    required this.prov,
    required this.accent,
    required this.onCreatePagina,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Row(
        children: [
          SizedBox(
            width: 252,
            child: _Sidebar(
              libreta: libreta,
              roots: roots,
              uid: uid,
              prov: prov,
              accent: accent,
              onCreatePagina: onCreatePagina,
            ),
          ),
          VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
          Expanded(
            child: _WelcomeArea(
              libreta: libreta,
              accent: accent,
              paginaCount: roots.fold(
                0,
                (acc, r) => acc + 1 + prov.subPaginasDe(libreta.id, r.id).length,
              ),
              rootCount: roots.length,
              onCreatePagina: () => onCreatePagina(null),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Narrow layout ──────────────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  final Libreta libreta;
  final List<Pagina> roots;
  final String uid;
  final LibretasProvider prov;
  final Color accent;
  final Function(Pagina?) onCreatePagina;

  const _NarrowLayout({
    required this.libreta,
    required this.roots,
    required this.uid,
    required this.prov,
    required this.accent,
    required this.onCreatePagina,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(child: Text(libreta.emoji, style: const TextStyle(fontSize: 13))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                libreta.titulo,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        actions: [
          _SidebarNewPageButton(onTap: () => onCreatePagina(null)),
          const SizedBox(width: 4),
        ],
      ),
      body: roots.isEmpty
          ? _EmptyPages(accent: accent, onAdd: () => onCreatePagina(null))
          : ListView(
              padding: const EdgeInsets.fromLTRB(0, 6, 0, 100),
              children: _buildRootItems(roots, context),
            ),
    );
  }

  List<Widget> _buildRootItems(List<Pagina> roots, BuildContext context) {
    final sorted = _sortedPaginas(roots, prov, libreta.id);
    final items = <Widget>[];
    for (int i = 0; i < sorted.length; i++) {
      final pagina = sorted[i];
      final firstCarpetaIndex = sorted.indexWhere(
        (p) => prov.subPaginasDe(libreta.id, p.id).isNotEmpty,
      );
      final isLastHoja = firstCarpetaIndex > 0 && i == firstCarpetaIndex - 1;

      items.add(
        _TreeItem(
          pagina: pagina,
          libreta: libreta,
          uid: uid,
          prov: prov,
          depth: 0,
          accent: accent,
          onCreateSub: (p) => onCreatePagina(p),
        ),
      );

      if (isLastHoja) {
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        );
      } else if (i < sorted.length - 1) {
        items.add(const Divider(height: 1, indent: 52, endIndent: 12, thickness: 0.5));
      }
    }
    return items;
  }
}

// ─── Sidebar ────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final Libreta libreta;
  final List<Pagina> roots;
  final String uid;
  final LibretasProvider prov;
  final Color accent;
  final Function(Pagina?) onCreatePagina;

  const _Sidebar({
    required this.libreta,
    required this.roots,
    required this.uid,
    required this.prov,
    required this.accent,
    required this.onCreatePagina,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 16,
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(child: Text(libreta.emoji, style: const TextStyle(fontSize: 14))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      libreta.titulo,
                      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _SidebarNewPageButton(onTap: () => onCreatePagina(null)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Divider(height: 1, indent: 10, endIndent: 10, color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 4),
          Expanded(
            child: roots.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Icon(
                          Icons.article_outlined,
                          size: 36,
                          color: theme.colorScheme.onSurface.withOpacity(0.15),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sin páginas todavía',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 20),
                    children: _buildTreeItems(roots, context),
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTreeItems(List<Pagina> roots, BuildContext context) {
    final sorted = _sortedPaginas(roots, prov, libreta.id); // ← agrega esto
    final items = <Widget>[];
    for (int i = 0; i < sorted.length; i++) {
      // ← usa sorted
      final pagina = sorted[i];
      final isLastHoja =
          i ==
          sorted.indexWhere(
                // separador entre sección hojas/carpetas
                (p) => prov.subPaginasDe(libreta.id, p.id).isNotEmpty,
              ) -
              1;

      items.add(
        _TreeItem(
          pagina: pagina,
          libreta: libreta,
          uid: uid,
          prov: prov,
          depth: 0,
          accent: accent,
          onCreateSub: (p) => onCreatePagina(p),
        ),
      );

      // Separador más notorio entre la sección de hojas y la de carpetas
      if (isLastHoja) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (i < sorted.length - 1) {
        items.add(
          Divider(
            height: 6,
            indent: 30,
            endIndent: 4,
            thickness: 0.5,
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
          ),
        );
      }
    }
    return items;
  }
}

// ─── Botón "nueva página" compacto ──────────────────────────────────────
class _SidebarNewPageButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SidebarNewPageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: 'Nueva página',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            Icons.add_rounded,
            size: 18,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }
}

// ─── Tree item rediseñado ───────────────────────────────────────────────
class _TreeItem extends StatefulWidget {
  final Pagina pagina;
  final Libreta libreta;
  final String uid;
  final LibretasProvider prov;
  final int depth;
  final Color accent;
  final Function(Pagina) onCreateSub;

  const _TreeItem({
    required this.pagina,
    required this.libreta,
    required this.uid,
    required this.prov,
    required this.depth,
    required this.accent,
    required this.onCreateSub,
  });

  @override
  State<_TreeItem> createState() => _TreeItemState();
}

class _TreeItemState extends State<_TreeItem> with SingleTickerProviderStateMixin {
  bool _expanded = true;
  bool _hovered = false;

  // La línea guía va en ese centro para que los hijos arranquen de ahí
  static const double _iconSize = 25;
  static const double _arrowWidth = 20;
  static const double _depthStep = 20.0; // paso de indentación por nivel

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subs = widget.prov.subPaginasDe(widget.libreta.id, widget.pagina.id);
    final hasSubs = subs.isNotEmpty;
    final indent = widget.depth * _depthStep;
    final onSurface = theme.colorScheme.onSurface;

    // Posición x de la línea: desde el borde izquierdo del contenedor padre
    // = indent (margen) + arrowWidth + iconSize/2 + padding horizontal (4)
    final double lineX = indent + 4 + _arrowWidth + _iconSize / 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => context.push(
              AppRoutes.paginaEditor,
              extra: {'pagina': widget.pagina, 'libreta': widget.libreta},
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              margin: EdgeInsets.only(left: indent),
              decoration: BoxDecoration(
                color: _hovered ? onSurface.withOpacity(0.05) : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  // Flecha de expansión
                  SizedBox(
                    width: _arrowWidth,
                    height: _iconSize,
                    child: hasSubs
                        ? GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _expanded = !_expanded),
                            child: Center(
                              child: AnimatedRotation(
                                turns: _expanded ? 0.25 : 0,
                                duration: const Duration(milliseconds: 150),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: _iconSize,
                                  color: onSurface.withOpacity(0.35),
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  // Ícono página/carpeta
                  Icon(
                    hasSubs
                        ? (_expanded ? Icons.menu_book_rounded : Icons.book_rounded)
                        : Icons.description_outlined,
                    size: _iconSize,
                    color: hasSubs ? onSurface.withOpacity(0.5) : onSurface.withOpacity(0.35),
                  ),
                  const SizedBox(width: 10),
                  // Título
                  Expanded(
                    child: Text(
                      widget.pagina.titulo,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: onSurface.withOpacity(hasSubs ? 0.88 : 0.72),
                        fontWeight: hasSubs ? FontWeight.w500 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Acciones
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_hovered)
                        _HoverAction(
                          icon: Icons.add_rounded,
                          tooltip: 'Sub-página',
                          onTap: () => widget.onCreateSub(widget.pagina),
                        ),
                      _HoverAction(
                        icon: Icons.more_horiz_rounded,
                        tooltip: 'Opciones',
                        onTap: () => _showMenu(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Hijos con línea guía alineada al centro del ícono padre
        if (hasSubs && _expanded)
          Stack(
            children: [
              Positioned(
                left: lineX,
                top: 0,
                bottom: 6,
                child: Container(
                  width: 1,
                  color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                ),
              ),
              Column(
                children: subs
                    .map(
                      (sub) => _TreeItem(
                        pagina: sub,
                        libreta: widget.libreta,
                        uid: widget.uid,
                        prov: widget.prov,
                        depth: widget.depth + 1,
                        accent: widget.accent,
                        onCreateSub: widget.onCreateSub,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
      ],
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _PageActionsSheet(
        pagina: widget.pagina,
        uid: widget.uid,
        prov: widget.prov,
        onCreateSub: widget.onCreateSub,
      ),
    );
  }
}

// ─── Helper para ordenar: hojas primero, carpetas después ───────────────
List<Pagina> _sortedPaginas(List<Pagina> paginas, LibretasProvider prov, String libretaId) {
  final hojas = paginas.where((p) => prov.subPaginasDe(libretaId, p.id).isEmpty).toList();
  final carpetas = paginas.where((p) => prov.subPaginasDe(libretaId, p.id).isNotEmpty).toList();
  return [...hojas, ...carpetas];
}

// ─── Botón de acción en hover ───────────────────────────────────────────
class _HoverAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _HoverAction({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(icon, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.45)),
        ),
      ),
    );
  }
}

// ─── Sheet de acciones (reemplaza el PopupMenu) ─────────────────────────
class _PageActionsSheet extends StatelessWidget {
  final Pagina pagina;
  final String uid;
  final LibretasProvider prov;
  final Function(Pagina) onCreateSub;

  const _PageActionsSheet({
    required this.pagina,
    required this.uid,
    required this.prov,
    required this.onCreateSub,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.add_rounded, size: 18),
            title: const Text('Sub-página'),
            onTap: () {
              Navigator.pop(context);
              onCreateSub(pagina);
            },
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_rename_outline_rounded, size: 18),
            title: const Text('Renombrar'),
            onTap: () async {
              Navigator.pop(context);
              final ctrl = TextEditingController(text: pagina.titulo);
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Renombrar'),
                  content: TextField(controller: ctrl, autofocus: true),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              );
              if (ok == true && ctrl.text.trim().isNotEmpty) {
                prov.renamePagina(uid, pagina.id, ctrl.text.trim());
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
            title: Text('Eliminar', style: TextStyle(color: Colors.red.shade400)),
            onTap: () async {
              Navigator.pop(context);
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar página'),
                  content: const Text('Se eliminarán también sus sub-páginas. ¿Seguro?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: Colors.red.shade400),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Eliminar'),
                    ),
                  ],
                ),
              );
              if (ok == true) prov.deletePagina(uid, pagina);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Welcome area rediseñada ────────────────────────────────────────────
class _WelcomeArea extends StatelessWidget {
  final Libreta libreta;
  final Color accent;
  final int paginaCount;
  final int rootCount;
  final VoidCallback onCreatePagina;

  const _WelcomeArea({
    required this.libreta,
    required this.accent,
    required this.paginaCount,
    required this.rootCount,
    required this.onCreatePagina,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(color: accent.withOpacity(0.1), shape: BoxShape.circle),
              child: Center(child: Text(libreta.emoji, style: const TextStyle(fontSize: 30))),
            ),
            const SizedBox(height: 18),
            // Título en serif
            Text(
              libreta.titulo,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.w600, color: onSurface),
            ),
            if (libreta.descripcion != null) ...[
              const SizedBox(height: 6),
              Text(
                libreta.descripcion!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: onSurface.withOpacity(0.45)),
              ),
            ],
            const SizedBox(height: 24),
            // Stats
            if (paginaCount > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatChip(value: '$paginaCount', label: 'páginas'),
                  const SizedBox(width: 8),
                  _StatChip(value: '$rootCount', label: 'secciones'),
                ],
              ),
            const SizedBox(height: 28),
            Text(
              'Selecciona una página o crea una nueva',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.amber),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onCreatePagina,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Nueva página'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: onSurface.withOpacity(0.18)),
                foregroundColor: onSurface.withOpacity(0.7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty pages ─────────────────────────────────────────────────────────
class _EmptyPages extends StatelessWidget {
  final Color accent;
  final VoidCallback onAdd;
  const _EmptyPages({required this.accent, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.insert_drive_file_outlined,
              size: 26,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sin páginas todavía',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.38),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Crea tu primera página para comenzar',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.25),
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Primera página'),
          ),
        ],
      ),
    );
  }
}
