import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:a_core/core/routes/app_router.dart';
import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/finanzas/domain/entities/cuenta.dart';
import 'package:a_core/features/finanzas/presentation/provider/finanzas_provider.dart';
import 'package:a_core/features/finanzas/presentation/widgets/add_cuenta_sheet.dart';

class CuentasPage extends StatefulWidget {
  const CuentasPage({super.key});

  @override
  State<CuentasPage> createState() => _CuentasPageState();
}

class _CuentasPageState extends State<CuentasPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<FinanzasProvider>().init(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fin = context.watch<FinanzasProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddCuenta(context, uid)),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Resumen ───────────────────────────
          SliverToBoxAdapter(
            child: _ResumenCard(fin: fin, theme: theme),
          ),

          // ── Lista de cuentas ──────────────────
          if (fin.cuentas.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 56,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sin cuentas registradas',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.separated(
                itemCount: fin.cuentas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final c = fin.cuentas[i];
                  return _CuentaCard(
                    cuenta: c,
                    onTap: () => context.push(AppRoutes.finanzasCuentaDetalle, extra: c),
                    onDelete: () => fin.deleteCuenta(uid, c.id),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddCuenta(BuildContext context, String uid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<FinanzasProvider>(),
        child: AddCuentaSheet(uid: uid),
      ),
    );
  }
}

// ── Resumen Card ──────────────────────────────
class _ResumenCard extends StatelessWidget {
  final FinanzasProvider fin;
  final ThemeData theme;
  const _ResumenCard({required this.fin, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Total activos
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total en activos',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatMonto(fin.totalActivos),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Deuda crédito',
                  value: _formatMonto(fin.totalDeudaCredito),
                  color: theme.colorScheme.error,
                  icon: Icons.credit_card,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Por cobrar',
                  value: _formatMonto(fin.totalPorCobrar),
                  color: theme.colorScheme.secondary,
                  icon: Icons.payments_outlined,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final ThemeData theme;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cuenta Card ───────────────────────────────
class _CuentaCard extends StatelessWidget {
  final Cuenta cuenta;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CuentaCard({required this.cuenta, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(int.parse('FF${cuenta.color.replaceAll('#', '')}', radix: 16));

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_iconForTipo(cuenta.tipo), color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cuenta.nombre, style: theme.textTheme.titleSmall),
                        if (cuenta.banco != null)
                          Text(
                            cuenta.banco!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _labelTipo(cuenta.tipo),
                    style: theme.textTheme.labelSmall?.copyWith(color: color),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        useRootNavigator: true,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Eliminar cuenta'),
                          content: const Text('¿Seguro? Se eliminará todo el historial.'),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cuenta.tipo == TipoCuenta.credito ? 'Deuda actual' : 'Saldo',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      Text(
                        _formatMonto(cuenta.saldo),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cuenta.tipo == TipoCuenta.credito
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (cuenta.tipo == TipoCuenta.credito && cuenta.limiteCredito != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Disponible',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          _formatMonto(cuenta.disponible),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (cuenta.tipo == TipoCuenta.credito && cuenta.limiteCredito != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: cuenta.porcentajeUso,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(
                      cuenta.porcentajeUso > 0.8 ? theme.colorScheme.error : color,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Límite: ${_formatMonto(cuenta.limiteCredito!)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForTipo(TipoCuenta tipo) {
    switch (tipo) {
      case TipoCuenta.credito:
        return Icons.credit_card;
      case TipoCuenta.debito:
        return Icons.account_balance_wallet;
      case TipoCuenta.rendimiento:
        return Icons.trending_up;
      case TipoCuenta.bolsa:
        return Icons.candlestick_chart_outlined;
      case TipoCuenta.otra:
        return Icons.attach_money;
    }
  }

  String _labelTipo(TipoCuenta tipo) {
    switch (tipo) {
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

String _formatMonto(double monto) {
  final neg = monto < 0;
  final abs = monto.abs();
  final str = abs
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
  return '${neg ? '-' : ''}\$$str';
}
