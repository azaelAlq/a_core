import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/diario/domain/entities/diary_entry.dart';
import 'package:a_core/features/diario/domain/entities/diary_template.dart';
import 'package:a_core/features/diario/presentation/provider/diary_provider.dart';

const _moods = [
  ('great', '😄', 'Genial'),
  ('good', '🙂', 'Bien'),
  ('neutral', '😐', 'Neutral'),
  ('bad', '😕', 'Mal'),
  ('awful', '😞', 'Pésimo'),
];

class DiaryEntryPage extends StatefulWidget {
  final DiaryEntry? entry;
  const DiaryEntryPage({super.key, this.entry});

  @override
  State<DiaryEntryPage> createState() => _DiaryEntryPageState();
}

class _DiaryEntryPageState extends State<DiaryEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late String _mood;
  late List<String> _tags;
  late DateTime _date;
  final _tagCtrl = TextEditingController();
  DiaryTemplate? _selectedTemplate;
  final Map<String, TextEditingController> _customControllers = {};

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    _mood = e?.mood ?? 'neutral';
    _tags = List.from(e?.tags ?? []);
    _date = e?.date ?? DateTime.now();
    _titleCtrl.addListener(() => setState(() {}));
    _contentCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagCtrl.dispose();
    for (final c in _customControllers.values) c.dispose();
    super.dispose();
  }

  void _onTemplateSelected(DiaryTemplate? t) {
    setState(() {
      _selectedTemplate = t;
      _customControllers.clear();
      if (t != null) {
        for (final f in t.fields) {
          _customControllers[f.id] = TextEditingController();
        }
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = context.read<AuthProvider>().user?.uid;
    if (uid == null) return;

    final customFields = {for (final e in _customControllers.entries) e.key: e.value.text};

    if (_isEditing) {
      await context.read<DiaryProvider>().updateEntry(
        uid,
        widget.entry!.copyWith(
          title: _titleCtrl.text.trim(),
          content: _contentCtrl.text.trim(),
          mood: _mood,
          tags: _tags,
          templateId: _selectedTemplate?.id,
          customFields: customFields,
          date: _date,
        ),
      );
    } else {
      await context.read<DiaryProvider>().createEntry(
        userId: uid,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        mood: _mood,
        tags: _tags,
        templateId: _selectedTemplate?.id,
        customFields: customFields,
        date: _date,
      );
    }

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diary = context.watch<DiaryProvider>();

    final formContent = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          // Fecha
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEEE d \'de\' MMMM, yyyy', 'es').format(_date),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Mood
          Text(
            '¿Cómo te sientes?',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _moods.map((m) {
              final selected = _mood == m.$1;
              return GestureDetector(
                onTap: () => setState(() => _mood = m.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? theme.colorScheme.primary : theme.dividerColor,
                      width: selected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(m.$2, style: TextStyle(fontSize: selected ? 28 : 22)),
                      const SizedBox(height: 4),
                      Text(m.$3, style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Título
          TextFormField(
            controller: _titleCtrl,
            style: theme.textTheme.headlineSmall,
            decoration: InputDecoration(
              hintText: 'Título de tu entrada...',
              hintStyle: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              border: InputBorder.none,
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Agrega un título' : null,
          ),
          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 16),

          // Contenido
          TextFormField(
            controller: _contentCtrl,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
            maxLines: null,
            minLines: 6,
            decoration: InputDecoration(
              hintText: '¿Qué pasó hoy? ¿Cómo te sentiste?',
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              border: InputBorder.none,
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Escribe algo' : null,
          ),
          const SizedBox(height: 28),

          // Tags
          Text(
            'Etiquetas',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Agregar etiqueta y presiona Enter...',
                    isDense: true,
                  ),
                  onSubmitted: (v) {
                    if (v.trim().isNotEmpty) {
                      setState(() {
                        _tags.add(v.trim());
                        _tagCtrl.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () {
                  if (_tagCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      _tags.add(_tagCtrl.text.trim());
                      _tagCtrl.clear();
                    });
                  }
                },
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tags
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      labelStyle: theme.textTheme.labelSmall,
                      onDeleted: () => setState(() => _tags.remove(t)),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Plantilla
          if (diary.templates.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(
              'Plantilla',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<DiaryTemplate?>(
              value: _selectedTemplate,
              hint: const Text('Sin plantilla'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin plantilla')),
                ...diary.templates.map((t) => DropdownMenuItem(value: t, child: Text(t.name))),
              ],
              onChanged: _onTemplateSelected,
            ),
            if (_selectedTemplate != null) ...[
              const SizedBox(height: 16),
              ..._selectedTemplate!.fields.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _customControllers[f.id],
                    decoration: InputDecoration(labelText: f.label + (f.required ? ' *' : '')),
                    maxLines: f.type == FieldType.longText ? 4 : 1,
                    keyboardType: f.type == FieldType.number
                        ? TextInputType.number
                        : TextInputType.text,
                    validator: f.required
                        ? (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );

    final preview = Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.dividerColor, width: 0.5)),
        color: theme.colorScheme.surface,
      ),
      padding: const EdgeInsets.all(24),
      child: _EntryPreview(
        title: _titleCtrl.text,
        content: _contentCtrl.text,
        mood: _mood,
        tags: _tags,
        date: _date,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar entrada' : 'Nueva entrada'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: diary.loading ? null : _save,
              icon: diary.loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Guardar'),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 700) {
            // ── Web: formulario + preview ────────────────
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: formContent),
                SizedBox(width: 320, child: preview),
              ],
            );
          }
          // ── Móvil: solo formulario ───────────────────
          return formContent;
        },
      ),
    );
  }
}

// ── Preview en vivo ───────────────────────────────────
class _EntryPreview extends StatelessWidget {
  final String title;
  final String content;
  final String mood;
  final List<String> tags;
  final DateTime date;

  const _EntryPreview({
    required this.title,
    required this.content,
    required this.mood,
    required this.tags,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodData = _moods.firstWhere((m) => m.$1 == mood, orElse: () => _moods[2]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vista previa',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 20),

        // Card preview
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(moodData.$2, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          moodData.$3,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          DateFormat('d MMM yyyy', 'es').format(date),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title.isEmpty ? 'Sin título...' : title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: title.isEmpty ? theme.colorScheme.onSurface.withOpacity(0.3) : null,
                ),
              ),
              if (content.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    height: 1.5,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tags
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(t, style: theme.textTheme.labelSmall),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
