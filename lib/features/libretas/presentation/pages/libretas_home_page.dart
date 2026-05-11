import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:a_core/core/routes/app_router.dart';
import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/libretas/domain/entities/libreta.dart';
import 'package:a_core/features/libretas/presentation/provider/libretas_provider.dart';

const _emojis = [
  '📓',
  '📔',
  '📒',
  '📕',
  '📗',
  '📘',
  '📙',
  '📝',
  '🗒️',
  '✏️',
  '💡',
  '🎯',
  '🌟',
  '🔖',
];
const _colores = [
  ('1565C0', 'Azul'),
  ('00838F', 'Teal'),
  ('0F6E56', 'Verde'),
  ('854F0B', 'Naranja'),
  ('A32D2D', 'Rojo'),
  ('5E35B1', 'Morado'),
  ('37474F', 'Gris'),
  ('E65100', 'Naranja oscuro'),
];

class LibretasHomePage extends StatefulWidget {
  const LibretasHomePage({super.key});

  @override
  State<LibretasHomePage> createState() => _LibretasHomePageState();
}

class _LibretasHomePageState extends State<LibretasHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<LibretasProvider>().init(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<LibretasProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Text(
          'Libretas',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _showCreate(context, uid),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nueva'),
              style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
      body: prov.libretas.isEmpty
          ? _EmptyState(onAdd: () => _showCreate(context, uid))
          : _Grid(libretas: prov.libretas, uid: uid, prov: prov),
    );
  }

  Future<void> _showCreate(BuildContext context, String uid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<LibretasProvider>(),
        child: _CreateSheet(uid: uid),
      ),
    );
  }
}

// ── Grid responsivo ───────────────────────────
class _Grid extends StatelessWidget {
  final List<Libreta> libretas;
  final String uid;
  final LibretasProvider prov;
  const _Grid({required this.libretas, required this.uid, required this.prov});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final cols = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 600
            ? 3
            : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.82,
          ),
          itemCount: libretas.length,
          itemBuilder: (_, i) => _LibretaCard(libreta: libretas[i], uid: uid, prov: prov),
        );
      },
    );
  }
}

// ── Card ──────────────────────────────────────
class _LibretaCard extends StatelessWidget {
  final Libreta libreta;
  final String uid;
  final LibretasProvider prov;
  const _LibretaCard({required this.libreta, required this.uid, required this.prov});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Color(int.parse('FF${libreta.color}', radix: 16));
    final dateStr = DateFormat('d MMM', 'es').format(libreta.updatedAt);

    return GestureDetector(
      onTap: () => context.push(AppRoutes.libretaDetalle, extra: libreta),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con color
            Container(
              height: 88,
              color: accent.withOpacity(0.1),
              child: Stack(
                children: [
                  // Barra izquierda de acento
                  Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: accent)),
                  // Emoji
                  Center(child: Text(libreta.emoji, style: const TextStyle(fontSize: 34))),
                  // Menú
                  Positioned(
                    top: 4,
                    right: 0,
                    child: _CardMenu(libreta: libreta, uid: uid, prov: prov),
                  ),
                ],
              ),
            ),
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      libreta.titulo,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (libreta.descripcion != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        libreta.descripcion!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${libreta.paginasCount}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.25),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  final Libreta libreta;
  final String uid;
  final LibretasProvider prov;
  const _CardMenu({required this.libreta, required this.uid, required this.prov});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        size: 16,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
      padding: EdgeInsets.zero,
      onSelected: (v) async {
        if (v == 'delete') {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Eliminar libreta'),
              content: const Text('Se eliminarán todas las páginas. ¿Seguro?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          );
          if (ok == true) prov.deleteLibreta(uid, libreta.id);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline, size: 18),
            title: Text('Eliminar'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: const Center(child: Text('📓', style: TextStyle(fontSize: 36))),
          ),
          const SizedBox(height: 20),
          Text(
            'Aún no tienes libretas',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Crea una para empezar a escribir',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nueva libreta'),
          ),
        ],
      ),
    );
  }
}

// ── Create sheet ──────────────────────────────
class _CreateSheet extends StatefulWidget {
  final String uid;
  const _CreateSheet({required this.uid});

  @override
  State<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<_CreateSheet> {
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _emoji = '📓';
  String _color = '1565C0';

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_tituloCtrl.text.trim().isEmpty) return;
    final libreta = await context.read<LibretasProvider>().createLibreta(
      userId: widget.uid,
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      emoji: _emoji,
      color: _color,
    );
    if (mounted) {
      Navigator.pop(context);
      if (libreta != null) context.push(AppRoutes.libretaDetalle, extra: libreta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prov = context.watch<LibretasProvider>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final accent = Color(int.parse('FF$_color', radix: 16));

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Preview animado
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent.withOpacity(0.35), width: 2),
                ),
                child: Center(child: Text(_emoji, style: const TextStyle(fontSize: 32))),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Nueva libreta',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _tituloCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 22),

            // Emoji
            Text(
              'Ícono',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _emojis.map((e) {
                final sel = _emoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _emoji = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: sel ? accent.withOpacity(0.12) : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: sel ? Border.all(color: accent, width: 1.5) : null,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Color
            Text(
              'Color',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colores.map((c) {
                final sel = _color == c.$1;
                final col = Color(int.parse('FF${c.$1}', radix: 16));
                return GestureDetector(
                  onTap: () => setState(() => _color = c.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: sel ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: sel
                          ? [
                              BoxShadow(
                                color: col.withOpacity(0.45),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: sel ? const Icon(Icons.check, color: Colors.white, size: 17) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: prov.loading ? null : _save,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: prov.loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Crear libreta', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
