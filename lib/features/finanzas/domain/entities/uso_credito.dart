enum EstadoUsoCredito { pendiente, pagandose, liquidado }

class UsoCredito {
  final String id;
  final String userId;
  final String cuentaId; // la tarjeta que usaron
  final String persona; // quién usó la tarjeta
  final double montoTotal; // total del cargo
  final double montoPagado; // cuánto te han regresado
  final int? mesesPago; // si pagan a mensualidades, cuántas
  final double? pagoMensual; // monto de cada mensualidad
  final String concepto; // para qué usaron la tarjeta
  final DateTime fecha;
  final EstadoUsoCredito estado;
  final DateTime createdAt;

  const UsoCredito({
    required this.id,
    required this.userId,
    required this.cuentaId,
    required this.persona,
    required this.montoTotal,
    required this.montoPagado,
    this.mesesPago,
    this.pagoMensual,
    required this.concepto,
    required this.fecha,
    required this.estado,
    required this.createdAt,
  });

  double get saldoPendiente => montoTotal - montoPagado;
  double get porcentajePagado => montoTotal > 0 ? (montoPagado / montoTotal).clamp(0.0, 1.0) : 0.0;
  bool get estaPagado => montoPagado >= montoTotal;

  UsoCredito copyWith({double? montoPagado, EstadoUsoCredito? estado}) {
    return UsoCredito(
      id: id,
      userId: userId,
      cuentaId: cuentaId,
      persona: persona,
      montoTotal: montoTotal,
      montoPagado: montoPagado ?? this.montoPagado,
      mesesPago: mesesPago,
      pagoMensual: pagoMensual,
      concepto: concepto,
      fecha: fecha,
      estado: estado ?? this.estado,
      createdAt: createdAt,
    );
  }
}
