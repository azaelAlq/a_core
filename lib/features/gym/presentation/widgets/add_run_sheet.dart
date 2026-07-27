import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/run_activity.dart';
import 'run_formats.dart';

/// Bottom sheet para crear o editar una [RunActivity].
/// Devuelve la actividad lista para guardar, o null si se cancela.
class AddRunSheet extends StatefulWidget {
  final RunActivity? initial;
  const AddRunSheet({super.key, this.initial});

  static Future<RunActivity?> show(
    BuildContext context, {
    RunActivity? initial,
  }) {
    return showModalBottomSheet<RunActivity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (_) => AddRunSheet(initial: initial),
    );
  }

  @override
  State<AddRunSheet> createState() => _AddRunSheetState();
}

class _AddRunSheetState extends State<AddRunSheet> {
  late DateTime _performedAt;
  late String _activityPreset;
  late final TextEditingController _customActivityCtrl;
  late final TextEditingController _distanceCtrl;
  late final TextEditingController _hoursCtrl;
  late final TextEditingController _minutesCtrl;
  late final TextEditingController _secondsCtrl;
  late final TextEditingController _stepsCtrl;
  late final TextEditingController _activeCalCtrl;
  late final TextEditingController _totalCalCtrl;
  late final TextEditingController _avgHrCtrl;
  late final TextEditingController _maxHrCtrl;
  late final TextEditingController _notesCtrl;
  int? _fatigue;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    _performedAt = r?.performedAt ?? DateTime.now();
    _fatigue = r?.perceivedFatigue;

    final activity = r?.activity ?? 'Correr';
    final isPreset =
        runActivityPresets.contains(activity) && activity != 'Otro';
    _activityPreset = isPreset ? activity : (r == null ? 'Correr' : 'Otro');
    _customActivityCtrl = TextEditingController(text: isPreset ? '' : activity);

    _distanceCtrl = TextEditingController(
      text: r == null
          ? ''
          : (r.distanceKm == r.distanceKm.roundToDouble()
                ? r.distanceKm.toInt().toString()
                : r.distanceKm.toString()),
    );
    final dur = r?.durationSeconds ?? 0;
    _hoursCtrl = TextEditingController(
      text: dur >= 3600 ? '${dur ~/ 3600}' : '',
    );
    _minutesCtrl = TextEditingController(
      text: dur > 0 ? '${(dur % 3600) ~/ 60}' : '',
    );
    _secondsCtrl = TextEditingController(text: dur > 0 ? '${dur % 60}' : '');
    _stepsCtrl = TextEditingController(text: r?.steps?.toString() ?? '');
    _activeCalCtrl = TextEditingController(
      text: r?.activeCalories?.toString() ?? '',
    );
    _totalCalCtrl = TextEditingController(
      text: r?.totalCalories?.toString() ?? '',
    );
    _avgHrCtrl = TextEditingController(text: r?.avgHr?.toString() ?? '');
    _maxHrCtrl = TextEditingController(text: r?.maxHr?.toString() ?? '');
    _notesCtrl = TextEditingController(text: r?.notes ?? '');
  }

  @override
  void dispose() {
    _customActivityCtrl.dispose();
    _distanceCtrl.dispose();
    _hoursCtrl.dispose();
    _minutesCtrl.dispose();
    _secondsCtrl.dispose();
    _stepsCtrl.dispose();
    _activeCalCtrl.dispose();
    _totalCalCtrl.dispose();
    _avgHrCtrl.dispose();
    _maxHrCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _distanceKm =>
      double.tryParse(_distanceCtrl.text.replaceAll(',', '.')) ?? 0;

  int get _durationSeconds {
    final h = int.tryParse(_hoursCtrl.text) ?? 0;
    final m = int.tryParse(_minutesCtrl.text) ?? 0;
    final s = int.tryParse(_secondsCtrl.text) ?? 0;
    return h * 3600 + m * 60 + s;
  }

  bool get _isValid => _distanceKm > 0 && _durationSeconds > 0;

  String get _activityName {
    if (_activityPreset != 'Otro') return _activityPreset;
    final custom = _customActivityCtrl.text.trim();
    return custom.isEmpty ? 'Otro' : custom;
  }

  int? _optInt(TextEditingController c) => int.tryParse(c.text.trim());

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _performedAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    setState(() {
      _performedAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _performedAt.hour,
        _performedAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_performedAt),
    );
    if (picked == null) return;
    setState(() {
      _performedAt = DateTime(
        _performedAt.year,
        _performedAt.month,
        _performedAt.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _save() {
    if (!_isValid) return;
    final base = widget.initial;
    final run = RunActivity(
      id: base?.id ?? '',
      userId: base?.userId ?? '',
      performedAt: _performedAt,
      activity: _activityName,
      distanceKm: _distanceKm,
      durationSeconds: _durationSeconds,
      steps: _optInt(_stepsCtrl),
      activeCalories: _optInt(_activeCalCtrl),
      totalCalories: _optInt(_totalCalCtrl),
      avgHr: _optInt(_avgHrCtrl),
      maxHr: _optInt(_maxHrCtrl),
      perceivedFatigue: _fatigue,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      createdAt: base?.createdAt ?? DateTime.now(),
    );
    Navigator.of(context).pop(run);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pace = _distanceKm > 0 && _durationSeconds > 0
        ? (_durationSeconds / _distanceKm).round()
        : null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              _isEditing ? 'Editar actividad' : 'Nueva actividad',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // ── Fecha y hora ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      DateFormat('EEE d MMM y', 'es').format(_performedAt),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(DateFormat('HH:mm').format(_performedAt)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Actividad ──
            DropdownButtonFormField<String>(
              initialValue: _activityPreset,
              decoration: const InputDecoration(labelText: 'Actividad'),
              items: runActivityPresets
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _activityPreset = v ?? 'Correr'),
            ),
            if (_activityPreset == 'Otro') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customActivityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la actividad',
                  hintText: 'Ej. Natación',
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ── Distancia y duración ──
            TextField(
              controller: _distanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Distancia (km)',
                hintText: 'Ej. 5.2',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DurationField(
                    controller: _hoursCtrl,
                    label: 'Horas',
                    onChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DurationField(
                    controller: _minutesCtrl,
                    label: 'Min',
                    max: 59,
                    onChanged: () => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DurationField(
                    controller: _secondsCtrl,
                    label: 'Seg',
                    max: 59,
                    onChanged: () => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Ritmo calculado (preview) ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.speed,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ritmo: ${formatPace(pace)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Métricas opcionales ──
            Text('Métricas opcionales', style: theme.textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _IntField(controller: _stepsCtrl, label: 'Pasos'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _IntField(
                    controller: _activeCalCtrl,
                    label: 'Kcal activas',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _IntField(
                    controller: _totalCalCtrl,
                    label: 'Kcal totales',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _IntField(
                    controller: _avgHrCtrl,
                    label: 'LPM promedio',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _IntField(controller: _maxHrCtrl, label: 'LPM máximo'),
                ),
                const SizedBox(width: 8),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 16),

            // ── Fatiga percibida ──
            Text('Fatiga percibida', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(5, (i) {
                final v = i + 1;
                return ChoiceChip(
                  label: Text('$v'),
                  selected: _fatigue == v,
                  onSelected: (sel) =>
                      setState(() => _fatigue = sel ? v : null),
                );
              }),
            ),
            const SizedBox(height: 16),

            // ── Notas ──
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notas',
                hintText: 'Sensaciones, clima, ruta…',
              ),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            // ── Acciones ──
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isValid ? _save : null,
                  child: Text(_isEditing ? 'Guardar' : 'Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _DurationField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int? max;
  final VoidCallback onChanged;

  const _DurationField({
    required this.controller,
    required this.label,
    this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(max != null ? 2 : 3),
      ],
      decoration: InputDecoration(labelText: label, hintText: '0'),
      onChanged: (v) {
        final n = int.tryParse(v);
        if (max != null && n != null && n > max!) {
          controller.text = '$max';
          controller.selection = TextSelection.collapsed(
            offset: controller.text.length,
          );
        }
        onChanged();
      },
    );
  }
}

// ─────────────────────────────────────────────
class _IntField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _IntField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    );
  }
}
