import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:a_core/features/finanzas/domain/entities/cuenta.dart';
import 'package:a_core/features/finanzas/presentation/provider/finanzas_provider.dart';

// ─────────────────────────────────────────────
//  ADD PRESTAMO SHEET
// ─────────────────────────────────────────────
class AddPrestamoSheet extends StatefulWidget {
  final String uid;
  const AddPrestamoSheet({super.key, required this.uid});

  @override
  State<AddPrestamoSheet> createState() => _AddPrestamoSheetState();
}

class _AddPrestamoSheetState extends State<AddPrestamoSheet> {
  final _deudorCtrl = TextEditingController();
  final _contactoCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _conceptoCtrl = TextEditingController();
  DateTime? _fechaVencimiento;

  @override
  void dispose() {
    _deudorCtrl.dispose();
    _contactoCtrl.dispose();
    _montoCtrl.dispose();
    _conceptoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _fechaVencimiento = picked);
  }

  Future<void> _save() async {
    if (_deudorCtrl.text.trim().isEmpty) return;
    final monto = double.tryParse(_montoCtrl.text);
    if (monto == null || monto <= 0) return;
    await context.read<FinanzasProvider>().createPrestamo(
      userId: widget.uid,
      deudor: _deudorCtrl.text.trim(),
      contacto: _contactoCtrl.text.trim().isEmpty ? null : _contactoCtrl.text.trim(),
      monto: monto,
      fechaVencimiento: _fechaVencimiento,
      concepto: _conceptoCtrl.text.trim().isEmpty ? null : _conceptoCtrl.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fin = context.watch<FinanzasProvider>();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
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
            Text('Nuevo préstamo', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: _deudorCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre del deudor *',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contactoCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contacto / Teléfono',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto prestado *',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _conceptoCtrl,
              decoration: const InputDecoration(
                labelText: 'Concepto / Para qué',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickFecha,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Fecha de vencimiento (opcional)',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _fechaVencimiento != null
                      ? '${_fechaVencimiento!.day}/${_fechaVencimiento!.month}/${_fechaVencimiento!.year}'
                      : 'Sin fecha límite',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: fin.loading ? null : _save,
              child: fin.loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Registrar préstamo'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  ADD USO CREDITO SHEET
// ─────────────────────────────────────────────
class AddUsoCreditoSheet extends StatefulWidget {
  final String uid;
  const AddUsoCreditoSheet({super.key, required this.uid});

  @override
  State<AddUsoCreditoSheet> createState() => _AddUsoCreditoSheetState();
}

class _AddUsoCreditoSheetState extends State<AddUsoCreditoSheet> {
  final _personaCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _conceptoCtrl = TextEditingController();
  final _mesesCtrl = TextEditingController();
  Cuenta? _cuentaSeleccionada;
  bool _esMensualidades = false;

  @override
  void dispose() {
    _personaCtrl.dispose();
    _montoCtrl.dispose();
    _conceptoCtrl.dispose();
    _mesesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_personaCtrl.text.trim().isEmpty || _cuentaSeleccionada == null) return;
    final monto = double.tryParse(_montoCtrl.text);
    if (monto == null || monto <= 0) return;
    await context.read<FinanzasProvider>().createUsoCredito(
      userId: widget.uid,
      cuentaId: _cuentaSeleccionada!.id,
      persona: _personaCtrl.text.trim(),
      montoTotal: monto,
      mesesPago: _esMensualidades ? int.tryParse(_mesesCtrl.text) : null,
      concepto: _conceptoCtrl.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fin = context.watch<FinanzasProvider>();
    final tarjetas = fin.cuentas.where((c) => c.tipo == TipoCuenta.credito).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.80,
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
            Text('Uso de tarjeta', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Registra cuando alguien usa tu tarjeta',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),

            // Tarjeta
            DropdownButtonFormField<Cuenta>(
              value: _cuentaSeleccionada,
              hint: const Text('Selecciona la tarjeta *'),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.credit_card_outlined)),
              items: tarjetas
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.nombre)))
                  .toList(),
              onChanged: (v) => setState(() => _cuentaSeleccionada = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _personaCtrl,
              decoration: const InputDecoration(
                labelText: '¿Quién usó la tarjeta? *',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _conceptoCtrl,
              decoration: const InputDecoration(
                labelText: '¿Para qué? *',
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto total *',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),

            // Mensualidades
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Pago en mensualidades', style: theme.textTheme.bodyMedium),
              value: _esMensualidades,
              onChanged: (v) => setState(() => _esMensualidades = v),
            ),
            if (_esMensualidades) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _mesesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '¿Cuántas mensualidades?',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: fin.loading ? null : _save,
              child: fin.loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Registrar uso'),
            ),
          ],
        ),
      ),
    );
  }
}
