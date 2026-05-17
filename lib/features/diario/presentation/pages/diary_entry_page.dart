import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _tagCtrl = TextEditingController();

  late String _mood;
  late List<String> _tags;
  late DateTime _date;

  DiaryTemplate? _selectedTemplate;

  final Map<String, TextEditingController> _customControllers = {};
  final Map<String, dynamic> _customValues = {};

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTemplateData());
  }

  void _loadTemplateData() {
    final entry = widget.entry;
    if (entry == null || entry.templateId == null) return;

    final diary = context.read<DiaryProvider>();

    try {
      final template = diary.templates.firstWhere((t) => t.id == entry.templateId);
      _selectedTemplate = template;

      for (final f in template.fields) {
        final existing = entry.customFields[f.id];
        switch (f.type) {
          case FieldType.text:
          case FieldType.longText:
          case FieldType.number:
          case FieldType.time:
            _customControllers[f.id] = TextEditingController(text: existing?.toString() ?? '');
            break;
          case FieldType.yesNo:
            _customValues[f.id] = existing ?? false;
            break;
          case FieldType.rating:
            _customValues[f.id] = (existing is int)
                ? existing
                : int.tryParse(existing?.toString() ?? '') ?? 3;
            break;
        }
      }

      setState(() {});
    } catch (_) {}
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
      for (final c in _customControllers.values) c.dispose();
      _customControllers.clear();
      _customValues.clear();

      if (t != null) {
        for (final f in t.fields) {
          switch (f.type) {
            case FieldType.text:
            case FieldType.longText:
            case FieldType.number:
            case FieldType.time:
              _customControllers[f.id] = TextEditingController();
              break;
            case FieldType.yesNo:
              _customValues[f.id] = false;
              break;
            case FieldType.rating:
              _customValues[f.id] = 3;
              break;
          }
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

    final customFields = <String, dynamic>{};
    for (final e in _customControllers.entries) customFields[e.key] = e.value.text;
    for (final e in _customValues.entries) customFields[e.key] = e.value;

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

  // ── Campos dinámicos de plantilla ─────────────────────

  Widget _buildDynamicField(ThemeData theme, TemplateField f) {
    switch (f.type) {
      case FieldType.text:
        return _wrapField(
          theme,
          TextFormField(
            controller: _customControllers[f.id],
            decoration: _fieldDecoration('${f.label}${f.required ? ' *' : ''}'),
            validator: f.required
                ? (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null
                : null,
          ),
        );

      case FieldType.longText:
        return _wrapField(
          theme,
          TextFormField(
            controller: _customControllers[f.id],
            maxLines: 4,
            decoration: _fieldDecoration('${f.label}${f.required ? ' *' : ''}'),
            validator: f.required
                ? (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null
                : null,
          ),
        );

      case FieldType.number:
        return _wrapField(
          theme,
          TextFormField(
            controller: _customControllers[f.id],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: _fieldDecoration('${f.label}${f.required ? ' *' : ''}'),
            validator: f.required
                ? (v) => (v == null || v.isEmpty) ? 'Campo requerido' : null
                : null,
          ),
        );

      case FieldType.yesNo:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(f.label, style: theme.textTheme.bodyMedium),
            value: _customValues[f.id] ?? false,
            onChanged: (v) => setState(() => _customValues[f.id] = v),
          ),
        );

      case FieldType.rating:
        final val = (_customValues[f.id] ?? 3) as int;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(f.label, style: theme.textTheme.labelLarge),
                  // Puntos clicables: mucho más cómodos que slider
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final active = i < val;
                      return GestureDetector(
                        onTap: () => setState(() => _customValues[f.id] = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Icon(
                            active ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 26,
                            color: active
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        );

      case FieldType.time:
        return _wrapField(
          theme,
          TextFormField(
            controller: _customControllers[f.id],
            readOnly: true,
            decoration: _fieldDecoration(
              f.label,
            ).copyWith(suffixIcon: const Icon(Icons.schedule_rounded)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
              if (picked != null && mounted) {
                _customControllers[f.id]!.text = picked.format(context);
                setState(() {});
              }
            },
          ),
        );
    }
  }

  Widget _wrapField(ThemeData theme, Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 12), child: child);

  InputDecoration _fieldDecoration(String label) => InputDecoration(labelText: label);

  // ── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diary = context.watch<DiaryProvider>();

    final formContent = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          // ── Fecha ────────────────────────────────────
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined, size: 15, color: theme.colorScheme.primary),
                const SizedBox(width: 7),
                Text(
                  DateFormat("EEEE d 'de' MMMM, yyyy", 'es').format(_date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── Mood ──────────────────────────────────────
          Text(
            '¿Cómo te sientes?',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: _moods.map((m) {
              final selected = _mood == m.$1;
              return GestureDetector(
                onTap: () => setState(() => _mood = m.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? theme.colorScheme.primary : theme.dividerColor,
                      width: selected ? 1.5 : 0.7,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(m.$2, style: TextStyle(fontSize: selected ? 24 : 18)),
                      const SizedBox(height: 3),
                      Text(
                        m.$3,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 22),

          // ── Título ────────────────────────────────────
          TextFormField(
            controller: _titleCtrl,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Título de tu entrada...',
              hintStyle: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.25),
                fontWeight: FontWeight.w700,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Agrega un título' : null,
          ),

          Divider(color: theme.dividerColor, height: 1),
          const SizedBox(height: 14),

          // ── Contenido ─────────────────────────────────
          TextFormField(
            controller: _contentCtrl,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.7),
            maxLines: null,
            minLines: 5,
            decoration: InputDecoration(
              hintText: '¿Qué pasó hoy? ¿Cómo te sentiste?',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.28),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Escribe algo' : null,
          ),

          const SizedBox(height: 22),

          // ── Tags ──────────────────────────────────────
          Text(
            'Etiquetas',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagCtrl,
                  style: theme.textTheme.bodySmall,
                  decoration: const InputDecoration(
                    hintText: 'Nueva etiqueta y presiona Enter…',
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
                iconSize: 16,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.add),
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
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tags
                  .map(
                    (t) => Chip(
                      label: Text(t),
                      labelStyle: theme.textTheme.labelSmall,
                      visualDensity: VisualDensity.compact,
                      onDeleted: () => setState(() => _tags.remove(t)),
                    ),
                  )
                  .toList(),
            ),
          ],

          // ── Plantilla ─────────────────────────────────
          if (diary.templates.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'Plantilla',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<DiaryTemplate?>(
              value: _selectedTemplate,
              isDense: true,
              hint: const Text('Sin plantilla'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin plantilla')),
                ...diary.templates.map((t) => DropdownMenuItem(value: t, child: Text(t.name))),
              ],
              onChanged: _onTemplateSelected,
            ),
            if (_selectedTemplate != null) ...[
              const SizedBox(height: 14),
              ..._selectedTemplate!.fields.map((f) => _buildDynamicField(theme, f)),
            ],
          ],

          const SizedBox(height: 16),
        ],
      ),
    );

    // Preview lateral (solo web/tablet)
    final preview = Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.dividerColor, width: 0.5)),
        color: theme.colorScheme.surface,
      ),
      padding: const EdgeInsets.all(20),
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
        titleTextStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: diary.loading ? null : _save,
              icon: diary.loading
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, size: 16),
              label: const Text('Guardar'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Web / tablet: formulario acotado + preview
          if (constraints.maxWidth > 700) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: ConstrainedBox(
                      // Limita el ancho del formulario en pantallas grandes
                      constraints: const BoxConstraints(maxWidth: 580),
                      child: formContent,
                    ),
                  ),
                ),
                SizedBox(width: 300, child: preview),
              ],
            );
          }
          // Móvil
          return formContent;
        },
      ),
    );
  }
}

// ── Preview en vivo ───────────────────────────────────────

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
          'VISTA PREVIA',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.35),
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 16),

        // Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(moodData.$2, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
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
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                title.isEmpty ? 'Sin título…' : title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: title.isEmpty ? theme.colorScheme.onSurface.withOpacity(0.25) : null,
                ),
              ),

              if (content.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  content,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    height: 1.5,
                  ),
                  maxLines: 6,
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
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(t, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
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
