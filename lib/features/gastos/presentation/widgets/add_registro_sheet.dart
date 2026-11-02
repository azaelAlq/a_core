import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/gastos/domain/entities/registro.dart';
import 'package:a_core/features/gastos/presentation/provider/gastos_provider.dart';

class AddRegistroSheet extends StatefulWidget {
  final String uid;
  const AddRegistroSheet({super.key, required this.uid});

  @override
  State<AddRegistroSheet> createState() => _AddRegistroSheetState();
}

class _AddRegistroSheetState extends State<AddRegistroSheet> {
  final _nombreCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  TipoRegistro _tipo = TipoRegistro.gasto;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cantidad = double.tryParse(_cantidadCtrl.text);
    if (cantidad == null || cantidad <= 0 || _nombreCtrl.text.trim().isEmpty) {
      return;
    }
    await context.read<GastosProvider>().addRegistro(
      userId: widget.uid,
      nombre: _nombreCtrl.text.trim(),
      cantidad: cantidad,
      tipo: _tipo,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gastos = context.watch<GastosProvider>();
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
          Text('Nuevo registro', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<TipoRegistro>(
            segments: const [
              ButtonSegment(
                value: TipoRegistro.gasto,
                label: Text('↑ Gasto'),
              ),
              ButtonSegment(
                value: TipoRegistro.ingreso,
                label: Text('↓ Ingreso'),
              ),
            ],
            selected: {_tipo},
            onSelectionChanged: (s) => setState(() => _tipo = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nombreCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Nombre *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cantidadCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Cantidad *'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: gastos.loading ? null : _save,
              child: gastos.loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ),
        ],
      ),
    );
  }
}
