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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTemplateData();
    });
  }

  void _loadTemplateData() {
    final entry = widget.entry;

    if (entry == null) return;

    final diary = context.read<DiaryProvider>();

    if (entry.templateId == null) return;

    try {
      final template = diary.templates.firstWhere((t) => t.id == entry.templateId);

      _selectedTemplate = template;

      for (final f in template.fields) {
        final existingValue = entry.customFields[f.id];

        switch (f.type) {
          case FieldType.text:
          case FieldType.longText:
          case FieldType.number:
          case FieldType.time:
            _customControllers[f.id] = TextEditingController(text: existingValue?.toString() ?? '');
            break;

          case FieldType.yesNo:
            _customValues[f.id] = existingValue ?? false;
            break;

          case FieldType.rating:
            _customValues[f.id] = existingValue ?? 3;
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

    for (final c in _customControllers.values) {
      c.dispose();
    }

    super.dispose();
  }

  void _onTemplateSelected(DiaryTemplate? t) {
    setState(() {
      _selectedTemplate = t;

      for (final c in _customControllers.values) {
        c.dispose();
      }

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

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = context.read<AuthProvider>().user?.uid;

    if (uid == null) return;

    final customFields = <String, dynamic>{};

    for (final e in _customControllers.entries) {
      customFields[e.key] = e.value.text;
    }

    for (final e in _customValues.entries) {
      customFields[e.key] = e.value;
    }

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

    if (mounted) {
      context.pop();
    }
  }

  Widget _buildDynamicField(BuildContext context, ThemeData theme, TemplateField f) {
    switch (f.type) {
      case FieldType.text:
        return _inputField(
          theme,
          child: TextFormField(
            controller: _customControllers[f.id],
            decoration: InputDecoration(
              labelText: '${f.label}${f.required ? ' *' : ''}',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        );

      case FieldType.longText:
        return _inputField(
          theme,
          child: TextFormField(
            controller: _customControllers[f.id],
            maxLines: 5,
            decoration: InputDecoration(
              labelText: '${f.label}${f.required ? ' *' : ''}',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        );

      case FieldType.number:
        return _inputField(
          theme,
          child: TextFormField(
            controller: _customControllers[f.id],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '${f.label}${f.required ? ' *' : ''}',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
        );

      case FieldType.yesNo:
        return SwitchListTile.adaptive(
          title: Text(f.label),
          value: _customValues[f.id] ?? false,
          onChanged: (v) {
            setState(() {
              _customValues[f.id] = v;
            });
          },
        );

      case FieldType.rating:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.label),
            Slider(
              value: (_customValues[f.id] ?? 3).toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '${_customValues[f.id]}',
              onChanged: (v) {
                setState(() {
                  _customValues[f.id] = v.round();
                });
              },
            ),
          ],
        );

      case FieldType.time:
        return _inputField(
          theme,
          child: TextFormField(
            controller: _customControllers[f.id],
            readOnly: true,
            decoration: InputDecoration(
              labelText: f.label,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
              suffixIcon: const Icon(Icons.schedule_rounded),
            ),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());

              if (picked != null) {
                _customControllers[f.id]!.text = picked.format(context);
              }
            },
          ),
        );
    }
  }

  Widget _inputField(ThemeData theme, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(.35),
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diary = context.watch<DiaryProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar entrada' : 'Nueva entrada')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(hintText: 'Título'),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _contentCtrl,
              maxLines: 10,
              decoration: const InputDecoration(hintText: 'Contenido'),
            ),

            const SizedBox(height: 24),

            DropdownButtonFormField<DiaryTemplate?>(
              value: _selectedTemplate,
              decoration: const InputDecoration(hintText: 'Plantilla'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Sin plantilla')),
                ...diary.templates.map((t) => DropdownMenuItem(value: t, child: Text(t.name))),
              ],
              onChanged: _onTemplateSelected,
            ),

            const SizedBox(height: 24),

            if (_selectedTemplate != null)
              ..._selectedTemplate!.fields.map((f) => _buildDynamicField(context, theme, f)),

            const SizedBox(height: 32),

            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return const SizedBox();
  }
}
