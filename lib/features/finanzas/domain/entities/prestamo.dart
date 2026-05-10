enum EstadoPrestamo { activo, liquidado, vencido }

class Prestamo {
  final String id;
  final String userId;
  final String deudor; // nombre de quien te debe
  final String? contacto; // teléfono o referencia
  final double montoOriginal;
  final double montoPagado;
  final DateTime fechaPrestamo;
  final DateTime? fechaVencimiento;
  final String? concepto;
  final EstadoPrestamo estado;
  final DateTime createdAt;

  const Prestamo({
    required this.id,
    required this.userId,
    required this.deudor,
    this.contacto,
    required this.montoOriginal,
    required this.montoPagado,
    required this.fechaPrestamo,
    this.fechaVencimiento,
    this.concepto,
    required this.estado,
    required this.createdAt,
  });

  double get saldoPendiente => montoOriginal - montoPagado;
  double get porcentajePagado =>
      montoOriginal > 0 ? (montoPagado / montoOriginal).clamp(0.0, 1.0) : 0.0;
  bool get estaPagado => montoPagado >= montoOriginal;

  Prestamo copyWith({double? montoPagado, EstadoPrestamo? estado, DateTime? fechaVencimiento}) {
    return Prestamo(
      id: id,
      userId: userId,
      deudor: deudor,
      contacto: contacto,
      montoOriginal: montoOriginal,
      montoPagado: montoPagado ?? this.montoPagado,
      fechaPrestamo: fechaPrestamo,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      concepto: concepto,
      estado: estado ?? this.estado,
      createdAt: createdAt,
    );
  }
}
