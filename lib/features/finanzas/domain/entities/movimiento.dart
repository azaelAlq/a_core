enum TipoMovimiento { ingreso, egreso }

class Movimiento {
  final String id;
  final String cuentaId;
  final String userId;
  final TipoMovimiento tipo;
  final double monto;
  final String concepto;
  final String? notas;
  final DateTime fecha;
  final DateTime createdAt;

  const Movimiento({
    required this.id,
    required this.cuentaId,
    required this.userId,
    required this.tipo,
    required this.monto,
    required this.concepto,
    this.notas,
    required this.fecha,
    required this.createdAt,
  });
}
