import 'package:a_core/features/finanzas/domain/entities/cuenta.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/finanzas/domain/entities/prestamo.dart';
import 'package:a_core/features/finanzas/domain/entities/uso_credito.dart';
import 'package:a_core/features/finanzas/presentation/provider/finanzas_provider.dart';
import 'package:a_core/features/finanzas/presentation/widgets/add_prestamo_sheet.dart';
import 'package:a_core/features/finanzas/presentation/widgets/add_uso_credito_sheet.dart';

import 'package:collection/collection.dart';

class CompromisosPage extends StatelessWidget {
  const CompromisosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fin = context.watch<FinanzasProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Compromisos'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Préstamos'),
              Tab(text: 'Uso de tarjeta'),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.add),
              onSelected: (v) {
                if (v == 'prestamo') _showAddPrestamo(context, uid);
                if (v == 'uso') _showAddUso(context, uid, fin);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'prestamo',
                  child: ListTile(
                    leading: Icon(Icons.handshake_outlined),
                    title: Text('Nuevo préstamo'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'uso',
                  child: ListTile(
                    leading: Icon(Icons.credit_card),
                    title: Text('Uso de tarjeta'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ── Tab 1: Préstamos ──────────────
            _PrestamosTab(fin: fin, uid: uid, theme: theme),
            // ── Tab 2: Uso de tarjeta ─────────
            _UsosCreditoTab(fin: fin, uid: uid, theme: theme),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddPrestamo(BuildContext context, String uid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<FinanzasProvider>(),
        child: AddPrestamoSheet(uid: uid),
      ),
    );
  }

  Future<void> _showAddUso(BuildContext context, String uid, FinanzasProvider fin) async {
    if (fin.cuentas.where((c) => c.tipo == TipoCuenta.credito).isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Primero agrega una tarjeta de crédito')));
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: fin,
        child: AddUsoCreditoSheet(uid: uid),
      ),
    );
  }
}

// ── Préstamos tab ─────────────────────────────
class _PrestamosTab extends StatelessWidget {
  final FinanzasProvider fin;
  final String uid;
  final ThemeData theme;
  const _PrestamosTab({required this.fin, required this.uid, required this.theme});

  @override
  Widget build(BuildContext context) {
    final activos = fin.prestamos.where((p) => p.estado == EstadoPrestamo.activo).toList();
    final liquidados = fin.prestamos.where((p) => p.estado != EstadoPrestamo.activo).toList();

    if (fin.prestamos.isEmpty) {
      return _Empty(label: 'Sin préstamos registrados', icon: Icons.handshake_outlined);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activos.isNotEmpty) ...[
          Text('Pendientes', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...activos.map(
            (p) => _PrestamoCard(
              prestamo: p,
              theme: theme,
              onPago: () => _showPago(context, uid, p),
              onDelete: () => fin.deletePrestamo(uid, p.id),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (liquidados.isNotEmpty) ...[
          Text(
            'Liquidados',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          ...liquidados.map(
            (p) => _PrestamoCard(
              prestamo: p,
              theme: theme,
              onPago: null,
              onDelete: () => fin.deletePrestamo(uid, p.id),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showPago(BuildContext context, String uid, Prestamo prestamo) async {
    final montoCtrl = TextEditingController();
    final notaCtrl = TextEditingController();
    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text('Registrar pago de ${prestamo.deudor}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pendiente: ${_fmt(prestamo.saldoPendiente)}'),
            const SizedBox(height: 12),
            TextField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto recibido'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notaCtrl,
              decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final monto = double.tryParse(montoCtrl.text);
              if (monto == null || monto <= 0) return;
              Navigator.of(ctx).pop();
              await context.read<FinanzasProvider>().registrarPago(
                userId: uid,
                prestamo: prestamo,
                monto: monto,
                notas: notaCtrl.text.trim().isEmpty ? null : notaCtrl.text.trim(),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _PrestamoCard extends StatelessWidget {
  final Prestamo prestamo;
  final ThemeData theme;
  final VoidCallback? onPago;
  final VoidCallback onDelete;

  const _PrestamoCard({
    required this.prestamo,
    required this.theme,
    required this.onPago,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final liquidado = prestamo.estado == EstadoPrestamo.liquidado;
    final dateStr = DateFormat('d MMM yyyy', 'es').format(prestamo.fechaPrestamo);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(prestamo.deudor, style: theme.textTheme.titleSmall),
                      if (prestamo.concepto != null)
                        Text(
                          prestamo.concepto!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      Text(
                        dateStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (liquidado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✅ Liquidado',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      useRootNavigator: true,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Eliminar préstamo'),
                        content: const Text('¿Seguro?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) onDelete();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${_fmt(prestamo.montoOriginal)}', style: theme.textTheme.bodySmall),
                Text(
                  'Pagado: ${_fmt(prestamo.montoPagado)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                ),
                Text(
                  'Pendiente: ${_fmt(prestamo.saldoPendiente)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: liquidado
                        ? theme.colorScheme.onSurface.withOpacity(0.4)
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: prestamo.porcentajePagado,
                minHeight: 6,
                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(
                  liquidado ? theme.colorScheme.primary : theme.colorScheme.secondary,
                ),
              ),
            ),
            if (onPago != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPago,
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text('Registrar pago'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Usos de crédito tab ───────────────────────
class _UsosCreditoTab extends StatelessWidget {
  final FinanzasProvider fin;
  final String uid;
  final ThemeData theme;
  const _UsosCreditoTab({required this.fin, required this.uid, required this.theme});

  @override
  Widget build(BuildContext context) {
    final activos = fin.usosCredito.where((u) => u.estado != EstadoUsoCredito.liquidado).toList();
    final liquidados = fin.usosCredito
        .where((u) => u.estado == EstadoUsoCredito.liquidado)
        .toList();

    if (fin.usosCredito.isEmpty) {
      return _Empty(label: 'Sin usos de tarjeta registrados', icon: Icons.credit_card_outlined);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activos.isNotEmpty) ...[
          Text('Pendientes', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ...activos.map(
            (u) => _UsoCreditoCard(
              uso: u,
              theme: theme,
              cuentaNombre:
                  fin.cuentas.firstWhereOrNull((c) => c.id == u.cuentaId)?.nombre ?? 'Sin cuenta',
              onPago: () => _showPagoCredito(context, uid, u),
              onDelete: () => fin.deleteUsoCredito(uid, u.id),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (liquidados.isNotEmpty) ...[
          Text(
            'Liquidados',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          ...liquidados.map(
            (u) => _UsoCreditoCard(
              uso: u,
              theme: theme,
              cuentaNombre:
                  fin.cuentas.firstWhereOrNull((c) => c.id == u.cuentaId)?.nombre ?? 'Sin cuenta',
              onPago: null,
              onDelete: () => fin.deleteUsoCredito(uid, u.id),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showPagoCredito(BuildContext context, String uid, UsoCredito uso) async {
    final montoCtrl = TextEditingController(text: uso.pagoMensual?.toStringAsFixed(2) ?? '');
    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        title: Text('Pago de ${uso.persona}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pendiente: ${_fmt(uso.saldoPendiente)}'),
            if (uso.pagoMensual != null)
              Text('Mensualidad: ${_fmt(uso.pagoMensual!)}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: montoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto recibido'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final monto = double.tryParse(montoCtrl.text);
              if (monto == null || monto <= 0) return;
              Navigator.of(ctx).pop();
              await context.read<FinanzasProvider>().registrarPagoCredito(
                userId: uid,
                uso: uso,
                monto: monto,
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _UsoCreditoCard extends StatelessWidget {
  final UsoCredito uso;
  final ThemeData theme;
  final String cuentaNombre;
  final VoidCallback? onPago;
  final VoidCallback onDelete;

  const _UsoCreditoCard({
    required this.uso,
    required this.theme,
    required this.cuentaNombre,
    required this.onPago,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final liquidado = uso.estado == EstadoUsoCredito.liquidado;
    final dateStr = DateFormat('d MMM yyyy', 'es').format(uso.fecha);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(uso.persona, style: theme.textTheme.titleSmall),
                      Text(
                        uso.concepto,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        '$cuentaNombre · $dateStr',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (liquidado)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✅ Liquidado',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      useRootNavigator: true,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Eliminar'),
                        content: const Text('¿Seguro?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) onDelete();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${_fmt(uso.montoTotal)}', style: theme.textTheme.bodySmall),
                Text(
                  'Pagado: ${_fmt(uso.montoPagado)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                ),
                Text(
                  'Pendiente: ${_fmt(uso.saldoPendiente)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: liquidado
                        ? theme.colorScheme.onSurface.withOpacity(0.4)
                        : theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            if (uso.mesesPago != null) ...[
              const SizedBox(height: 4),
              Text(
                '${uso.mesesPago} mensualidades · ${_fmt(uso.pagoMensual ?? 0)} c/u',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: uso.porcentajePagado,
                minHeight: 6,
                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(
                  liquidado ? theme.colorScheme.primary : theme.colorScheme.secondary,
                ),
              ),
            ),
            if (onPago != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPago,
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text('Registrar pago'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Empty({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
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
