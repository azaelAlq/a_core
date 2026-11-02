import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:a_core/core/routes/app_router.dart';
import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/gastos/domain/entities/registro.dart';
import 'package:a_core/features/gastos/domain/periodo.dart';
import 'package:a_core/features/gastos/presentation/provider/gastos_provider.dart';
import 'package:a_core/features/gastos/presentation/widgets/add_registro_sheet.dart';

class GastosPage extends StatefulWidget {
  const GastosPage({super.key});

  @override
  State<GastosPage> createState() => _GastosPageState();
}

class _GastosPageState extends State<GastosPage> {
  TipoPeriodo _tipo = TipoPeriodo.semana;
  late Periodo _periodo = Periodo.calcular(_tipo);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<GastosProvider>().init(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gastos = context.watch<GastosProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final theme = Theme.of(context);

    final delPeriodo = gastos.registrosDe(_periodo);
    final ingresos = gastos.totalIngresos(delPeriodo);
    final gasto = gastos.totalGastos(delPeriodo);
    final balance = ingresos - gasto;

    final dias = _agruparPorDia(delPeriodo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRegistro(context, uid),
        child: const Icon(Icons.add_rounded),
      ),
      body: CustomScrollView(
        slivers: [
          // ── Selector de periodo ──────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  SegmentedButton<TipoPeriodo>(
                    segments: const [
                      ButtonSegment(
                        value: TipoPeriodo.semana,
                        label: Text('Semana'),
                      ),
                      ButtonSegment(
                        value: TipoPeriodo.quincena,
                        label: Text('Quincena'),
                      ),
                      ButtonSegment(
                        value: TipoPeriodo.mes,
                        label: Text('Mes'),
                      ),
                    ],
                    selected: {_tipo},
                    onSelectionChanged: (s) => setState(() {
                      _tipo = s.first;
                      _periodo = Periodo.calcular(_tipo);
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () =>
                            setState(() => _periodo = _periodo.anterior()),
                      ),
                      Text(
                        _periodo.etiqueta,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () =>
                            setState(() => _periodo = _periodo.siguiente()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Resumen ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balance del periodo',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatMonto(balance),
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
                          label: 'Ingresos',
                          value: _formatMonto(ingresos),
                          color: theme.colorScheme.secondary,
                          icon: Icons.south_west_rounded,
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStat(
                          label: 'Gastos',
                          value: _formatMonto(gasto),
                          color: theme.colorScheme.error,
                          icon: Icons.north_east_rounded,
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Lista ────────────────────────────
          if (dias.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 56,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Sin registros en este periodo',
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
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final dia = dias[i];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (i > 0) const SizedBox(height: 20),
                        _DiaHeader(
                          fecha: dia.fecha,
                          balance: dia.balance,
                          tema: theme,
                        ),
                        const SizedBox(height: 6),
                        ...dia.registros.map(
                          (r) => _RegistroTile(
                            registro: r,
                            theme: theme,
                            onDelete: () => gastos.deleteRegistro(uid, r.id),
                          ),
                        ),
                      ],
                    );
                  },
                  childCount: dias.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddRegistro(BuildContext context, String uid) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<GastosProvider>(),
        child: AddRegistroSheet(uid: uid),
      ),
    );
  }

  List<_DiaRegistros> _agruparPorDia(List<Registro> registros) {
    final mapa = <String, List<Registro>>{};
    for (final r in registros) {
      final clave = DateFormat('yyyy-MM-dd').format(r.fecha);
      mapa.putIfAbsent(clave, () => []).add(r);
    }
    final dias = mapa.entries.map((e) {
      final lista = e.value;
      return _DiaRegistros(
        fecha: lista.first.fecha,
        registros: lista,
        balance: lista.fold<double>(
          0,
          (s, r) =>
              s +
              (r.tipo == TipoRegistro.ingreso ? r.cantidad : -r.cantidad),
        ),
      );
    }).toList();
    dias.sort((a, b) => b.fecha.compareTo(a.fecha));
    return dias;
  }
}

// ── Modelo de día ─────────────────────────────
class _DiaRegistros {
  final DateTime fecha;
  final List<Registro> registros;
  final double balance;

  _DiaRegistros({
    required this.fecha,
    required this.registros,
    required this.balance,
  });
}

// ── Header de día ─────────────────────────────
class _DiaHeader extends StatelessWidget {
  final DateTime fecha;
  final double balance;
  final ThemeData tema;

  const _DiaHeader({
    required this.fecha,
    required this.balance,
    required this.tema,
  });

  @override
  Widget build(BuildContext context) {
    final esPositivo = balance >= 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('EEEE d MMM', 'es').format(fecha),
          style: tema.textTheme.labelLarge?.copyWith(
            color: tema.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          _formatMonto(balance),
          style: tema.textTheme.labelLarge?.copyWith(
            color: esPositivo
                ? tema.colorScheme.secondary
                : tema.colorScheme.error,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Tile de registro ──────────────────────────
class _RegistroTile extends StatelessWidget {
  final Registro registro;
  final ThemeData theme;
  final VoidCallback onDelete;

  const _RegistroTile({
    required this.registro,
    required this.theme,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final esIngreso = registro.tipo == TipoRegistro.ingreso;
    final color = esIngreso ? theme.colorScheme.secondary : theme.colorScheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                esIngreso
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                registro.nombre,
                style: theme.textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${esIngreso ? '+' : '−'}${_formatMonto(registro.cantidad)}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: theme.colorScheme.error,
              ),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  useRootNavigator: true,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar registro'),
                    content: const Text('¿Seguro que quieres eliminarlo?'),
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
      ),
    );
  }
}

// ── Mini stat ─────────────────────────────────
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

String _formatMonto(double monto) {
  final neg = monto < 0;
  final abs = monto.abs();
  final str = abs
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
  return '${neg ? '-' : ''}\$$str';
}
