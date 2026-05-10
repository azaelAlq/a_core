import 'package:a_core/features/finanzas/data/models/cuenta_model.dart';
import 'package:a_core/features/finanzas/domain/entities/cuenta.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/finanzas/domain/entities/movimiento.dart';
import 'package:a_core/features/finanzas/presentation/provider/finanzas_provider.dart';
import 'package:a_core/features/finanzas/presentation/widgets/add_movimiento_sheet.dart';

class CuentaDetallePage extends StatefulWidget {
  final Cuenta cuenta;
  const CuentaDetallePage({super.key, required this.cuenta});

  @override
  State<CuentaDetallePage> createState() => _CuentaDetallePageState();
}

class _CuentaDetallePageState extends State<CuentaDetallePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      context.read<FinanzasProvider>().watchMovimientos(uid, widget.cuenta.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fin = context.watch<FinanzasProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final theme = Theme.of(context);
    final movimientos = fin.movimientosDe(widget.cuenta.id);

    // Cuenta actualizada del provider (para saldo en tiempo real)
    final cuenta = fin.cuentas.firstWhere(
      (c) => c.id == widget.cuenta.id,
      orElse: () => CuentaModel.fromEntity(widget.cuenta),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(cuenta.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMovimiento(context, uid, cuenta),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Header cuenta ─────────────────────
          SliverToBoxAdapter(
            child: _CuentaHeader(cuenta: cuenta, theme: theme),
          ),

          // ── Movimientos ───────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text('Movimientos', style: theme.textTheme.titleMedium),
            ),
          ),

          if (movimientos.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'Sin movimientos registrados',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList.separated(
                itemCount: movimientos.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) => _MovimientoTile(mov: movimientos[i], theme: theme),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddMovimiento(BuildContext context, String uid, Cuenta cuenta) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<FinanzasProvider>(),
        child: AddMovimientoSheet(uid: uid, cuenta: cuenta),
      ),
    );
  }
}

class _CuentaHeader extends StatelessWidget {
  final Cuenta cuenta;
  final ThemeData theme;
  const _CuentaHeader({required this.cuenta, required this.theme});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF${cuenta.color.replaceAll('#', '')}', radix: 16));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cuenta.tipo == TipoCuenta.credito ? 'Deuda actual' : 'Saldo actual',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            _fmt(cuenta.saldo),
            style: theme.textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (cuenta.tipo == TipoCuenta.credito && cuenta.limiteCredito != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: cuenta.porcentajeUso,
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Disponible: ${_fmt(cuenta.disponible)}',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
                Text(
                  'Límite: ${_fmt(cuenta.limiteCredito!)}',
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MovimientoTile extends StatelessWidget {
  final Movimiento mov;
  final ThemeData theme;
  const _MovimientoTile({required this.mov, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isIngreso = mov.tipo == TipoMovimiento.ingreso;
    final dateStr = DateFormat('d MMM yyyy', 'es').format(mov.fecha);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isIngreso ? theme.colorScheme.primaryContainer : theme.colorScheme.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isIngreso ? Icons.arrow_downward : Icons.arrow_upward,
          size: 18,
          color: isIngreso ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
      ),
      title: Text(mov.concepto, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        dateStr,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
      trailing: Text(
        '${isIngreso ? '+' : '-'}${_fmt(mov.monto)}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: isIngreso ? theme.colorScheme.primary : theme.colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

String _fmt(double monto) {
  final str = monto
      .abs()
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
  return '\$$str';
}
