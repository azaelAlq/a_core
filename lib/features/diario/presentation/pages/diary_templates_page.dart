import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/diario/domain/entities/diary_template.dart';
import 'package:a_core/features/diario/presentation/provider/diary_provider.dart';

const _fieldTypeLabels = {
  FieldType.text: 'Texto corto',
  FieldType.longText: 'Texto largo',
  FieldType.number: 'Número',
  FieldType.yesNo: 'Sí / No',
  FieldType.rating: 'Puntuación',
  FieldType.time: 'Hora',
};

class DiaryTemplatesPage extends StatelessWidget {
  const DiaryTemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final diary = context.watch<DiaryProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 82,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plantillas',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Organiza tus entradas personalizadas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(.55),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 0,
        onPressed: () => _showCreateSheet(context, uid),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva plantilla'),
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
              constraints: const BoxConstraints(maxWidth: 1200),
              child: diary.templates.isEmpty
                  ? _EmptyState(theme: theme)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                      itemCount: diary.templates.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 18),
                      itemBuilder: (context, i) {
                        final t = diary.templates[i];

                        return _TemplateCard(
                          template: t,
                          onDelete: () {
                            diary.deleteTemplate(uid, t.id);
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context, String uid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<DiaryProvider>(),
        child: _CreateTemplateSheet(uid: uid),
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _TemplateCard extends StatefulWidget {
  final DiaryTemplate template;
  final VoidCallback onDelete;

  const _TemplateCard({required this.template, required this.onDelete});

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(hovering ? .06 : .03),
              blurRadius: hovering ? 30 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(Icons.dashboard_customize_rounded, color: theme.colorScheme.primary),
                ),

                const SizedBox(width: 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.template.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${widget.template.fields.length} campo${widget.template.fields.length != 1 ? 's' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(.55),
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  tooltip: 'Eliminar',
                  onPressed: widget.onDelete,
                  icon: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
                ),
              ],
            ),

            if (widget.template.description != null &&
                widget.template.description!.trim().isNotEmpty) ...[
              const SizedBox(height: 20),

              Text(
                widget.template.description!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  color: theme.colorScheme.onSurface.withOpacity(.7),
                ),
              ),
            ],

            if (widget.template.fields.isNotEmpty) ...[
              const SizedBox(height: 24),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.template.fields.map((f) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(_fieldIcon(f.type), size: 16, color: theme.colorScheme.primary),

                        const SizedBox(width: 8),

                        Expanded(
                          child: Text(
                            f.label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Text(
                          _fieldTypeLabels[f.type] ?? '',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(.45),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _fieldIcon(FieldType type) {
    switch (type) {
      case FieldType.text:
        return Icons.short_text_rounded;

      case FieldType.longText:
        return Icons.notes_rounded;

      case FieldType.number:
        return Icons.pin_rounded;

      case FieldType.yesNo:
        return Icons.check_circle_outline_rounded;

      case FieldType.rating:
        return Icons.star_outline_rounded;

      case FieldType.time:
        return Icons.schedule_rounded;
    }
  }
}

// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ThemeData theme;

  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          width: 540,
          padding: const EdgeInsets.all(38),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.04),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.dashboard_customize_rounded,
                  size: 54,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Sin plantillas',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 12),

              Text(
                'Crea plantillas personalizadas para organizar mejor tus entradas y reflexiones.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.65),
                  height: 1.7,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _CreateTemplateSheet extends StatefulWidget {
  final String uid;

  const _CreateTemplateSheet({required this.uid});

  @override
  State<_CreateTemplateSheet> createState() => _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends State<_CreateTemplateSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final List<TemplateField> _fields = [];

  final _uuid = const Uuid();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _addField() async {
    final field = await showDialog<TemplateField>(
      context: context,
      builder: (_) => const _AddFieldDialog(),
    );

    if (field != null) {
      setState(() => _fields.add(field));
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      return;
    }

    await context.read<DiaryProvider>().createTemplate(
      userId: widget.uid,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      fields: _fields,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diary = context.watch<DiaryProvider>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .9,
      maxChildSize: .95,
      builder: (_, ctrl) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          ),
          child: ListView(
            controller: ctrl,
            padding: EdgeInsets.fromLTRB(28, 28, 28, MediaQuery.of(context).viewInsets.bottom + 28),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'Nueva plantilla',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 10),

              Text(
                'Diseña una estructura reutilizable para tus entradas.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(.6),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: _nameCtrl,
                decoration: _inputDecoration(context, 'Nombre de la plantilla *'),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: _inputDecoration(context, 'Descripción'),
              ),

              const SizedBox(height: 34),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Campos',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),

                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: _addField,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar'),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              if (_fields.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(.35),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Todavía no agregas campos.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(.55),
                    ),
                  ),
                ),

              ..._fields.map(
                (f) => Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(.35),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.drag_indicator_rounded, color: theme.colorScheme.primary),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              _fieldTypeLabels[f.type] ?? '',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(.55),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (f.required)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Requerido',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                      IconButton(
                        onPressed: () {
                          setState(() {
                            _fields.remove(f);
                          });
                        },
                        icon: Icon(Icons.close_rounded, color: theme.colorScheme.error),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              FilledButton(
                style: FilledButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                onPressed: diary.loading ? null : _save,
                child: diary.loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar plantilla'),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);

    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant.withOpacity(.35),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
    );
  }
}

// ─────────────────────────────────────────────

class _AddFieldDialog extends StatefulWidget {
  const _AddFieldDialog();

  @override
  State<_AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<_AddFieldDialog> {
  final _labelCtrl = TextEditingController();

  FieldType _type = FieldType.text;

  bool _required = false;

  final _uuid = const Uuid();

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(34)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nuevo campo',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                labelText: 'Nombre del campo',
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            DropdownButtonFormField<FieldType>(
              value: _type,
              decoration: InputDecoration(
                labelText: 'Tipo',
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
              items: FieldType.values
                  .map(
                    (t) => DropdownMenuItem(value: t, child: Text(_fieldTypeLabels[t] ?? t.name)),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _type = v!;
                });
              },
            ),

            const SizedBox(height: 10),

            CheckboxListTile(
              value: _required,
              contentPadding: EdgeInsets.zero,
              title: const Text('Requerido'),
              onChanged: (v) {
                setState(() {
                  _required = v ?? false;
                });
              },
            ),

            const SizedBox(height: 22),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancelar'),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: () {
                      if (_labelCtrl.text.trim().isEmpty) {
                        return;
                      }

                      Navigator.pop(
                        context,
                        TemplateField(
                          id: _uuid.v4(),
                          label: _labelCtrl.text.trim(),
                          type: _type,
                          required: _required,
                        ),
                      );
                    },
                    child: const Text('Agregar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
