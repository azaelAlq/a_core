import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:a_core/features/finanzas/domain/entities/cuenta.dart';
import 'package:a_core/features/finanzas/domain/entities/movimiento.dart';
import 'package:a_core/features/finanzas/presentation/provider/finanzas_provider.dart';

// ── Colores disponibles para cuentas ──────────
const _colores = [
  ('1565C0', 'Azul'),
  ('00838F', 'Teal'),
  ('0F6E56', 'Verde'),
  ('854F0B', 'Naranja'),
  ('A32D2D', 'Rojo'),
  ('5E35B1', 'Morado'),
  ('37474F', 'Gris'),
  ('F9A825', 'Amarillo'),
];

// ─────────────────────────────────────────────
//  ADD CUENTA SHEET
// ─────────────────────────────────────────────
class AddCuentaSheet extends StatefulWidget {
  final String uid;
  const AddCuentaSheet({super.key, required this.uid});

  @override
  State<AddCuentaSheet> createState() => _AddCuentaSheetState();
}

class _AddCuentaSheetState extends State<AddCuentaSheet> {
  final _nombreCtrl = TextEditingController();
  final _bancoCtrl = TextEditingController();
  final _saldoCtrl = TextEditingController();
  final _limiteCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  TipoCuenta _tipo = TipoCuenta.debito;
  String _color = '1565C0';

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _bancoCtrl.dispose();
    _saldoCtrl.dispose();
    _limiteCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nombreCtrl.text.trim().isEmpty) return;
    await context.read<FinanzasProvider>().createCuenta(
      userId: widget.uid,
      nombre: _nombreCtrl.text.trim(),
      banco: _bancoCtrl.text.trim().isEmpty ? null : _bancoCtrl.text.trim(),
      tipo: _tipo,
      saldo: double.tryParse(_saldoCtrl.text) ?? 0,
      limiteCredito: _tipo == TipoCuenta.credito ? double.tryParse(_limiteCtrl.text) : null,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      color: _color,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fin = context.watch<FinanzasProvider>();
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
            Text('Nueva cuenta', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),

            // Tipo
            Text('Tipo de cuenta', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TipoCuenta.values.map((t) {
                final sel = _tipo == t;
                return FilterChip(
                  label: Text(_labelTipo(t)),
                  selected: sel,
                  onSelected: (_) => setState(() => _tipo = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bancoCtrl,
              decoration: const InputDecoration(labelText: 'Banco / Institución'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _saldoCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _tipo == TipoCuenta.credito ? 'Deuda actual' : 'Saldo inicial',
              ),
            ),
            if (_tipo == TipoCuenta.credito) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _limiteCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Límite de crédito'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notasCtrl,
              decoration: const InputDecoration(labelText: 'Notas'),
            ),
            const SizedBox(height: 16),

            // Color
            Text('Color', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colores.map((c) {
                final sel = _color == c.$1;
                final col = Color(int.parse('FF${c.$1}', radix: 16));
                return GestureDetector(
                  onTap: () => setState(() => _color = c.$1),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: sel ? Border.all(color: Colors.white, width: 3) : null,
                      boxShadow: sel
                          ? [BoxShadow(color: col.withOpacity(0.5), blurRadius: 8)]
                          : null,
                    ),
                    child: sel ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                  ),
                );
              }).toList(),
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
                  : const Text('Guardar cuenta'),
            ),
          ],
        ),
      ),
    );
  }

  String _labelTipo(TipoCuenta t) {
    switch (t) {
      case TipoCuenta.credito:
        return 'Crédito';
      case TipoCuenta.debito:
        return 'Débito';
      case TipoCuenta.rendimiento:
        return 'Rendimiento';
      case TipoCuenta.bolsa:
        return 'Bolsa';
      case TipoCuenta.otra:
        return 'Otra';
    }
  }
}

// ─────────────────────────────────────────────
//  ADD MOVIMIENTO SHEET
// ─────────────────────────────────────────────
class AddMovimientoSheet extends StatefulWidget {
  final String uid;
  final Cuenta cuenta;
  const AddMovimientoSheet({super.key, required this.uid, required this.cuenta});

  @override
  State<AddMovimientoSheet> createState() => _AddMovimientoSheetState();
}

class _AddMovimientoSheetState extends State<AddMovimientoSheet> {
  final _montoCtrl = TextEditingController();
  final _conceptoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();
  TipoMovimiento _tipo = TipoMovimiento.ingreso;

  @override
  void dispose() {
    _montoCtrl.dispose();
    _conceptoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final monto = double.tryParse(_montoCtrl.text);
    if (monto == null || monto <= 0 || _conceptoCtrl.text.trim().isEmpty) return;
    await context.read<FinanzasProvider>().addMovimiento(
      userId: widget.uid,
      cuentaId: widget.cuenta.id,
      tipo: _tipo,
      monto: monto,
      concepto: _conceptoCtrl.text.trim(),
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fin = context.watch<FinanzasProvider>();
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nuevo movimiento', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<TipoMovimiento>(
            segments: const [
              ButtonSegment(value: TipoMovimiento.ingreso, label: Text('⬇ Ingreso')),
              ButtonSegment(value: TipoMovimiento.egreso, label: Text('⬆ Egreso')),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _montoCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Monto *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _conceptoCtrl,
            decoration: const InputDecoration(labelText: 'Concepto *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notasCtrl,
            decoration: const InputDecoration(labelText: 'Notas'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: fin.loading ? null : _save,
              child: fin.loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
