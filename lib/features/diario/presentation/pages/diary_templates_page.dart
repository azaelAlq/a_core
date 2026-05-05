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
      appBar: AppBar(title: const Text('Plantillas')),
      body: diary.templates.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dashboard_customize_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sin plantillas',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: diary.templates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final t = diary.templates[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(t.name, style: theme.textTheme.titleSmall),
                    subtitle: Text(
                      '${t.fields.length} campo${t.fields.length != 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
                      onPressed: () => diary.deleteTemplate(uid, t.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, uid),
        icon: const Icon(Icons.add),
        label: const Text('Nueva plantilla'),
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context, String uid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<DiaryProvider>(),
        child: _CreateTemplateSheet(uid: uid),
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
    if (field != null) setState(() => _fields.add(field));
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    await context.read<DiaryProvider>().createTemplate(
      userId: widget.uid,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      fields: _fields,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diary = context.watch<DiaryProvider>();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (_, ctrl) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: ListView(
          controller: ctrl,
          children: [
            Text('Nueva plantilla', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Campos', style: theme.textTheme.titleSmall),
                TextButton.icon(
                  onPressed: _addField,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._fields.map(
              (f) => ListTile(
                dense: true,
                leading: const Icon(Icons.drag_handle, size: 18),
                title: Text(f.label, style: theme.textTheme.bodyMedium),
                subtitle: Text(_fieldTypeLabels[f.type] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _fields.remove(f)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
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
    return AlertDialog(
      title: const Text('Nuevo campo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelCtrl,
            decoration: const InputDecoration(labelText: 'Nombre del campo'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<FieldType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Tipo'),
            items: FieldType.values
                .map((t) => DropdownMenuItem(value: t, child: Text(_fieldTypeLabels[t] ?? t.name)))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Requerido'),
            value: _required,
            onChanged: (v) => setState(() => _required = v ?? false),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            if (_labelCtrl.text.trim().isEmpty) return;
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
      ],
    );
  }
}
