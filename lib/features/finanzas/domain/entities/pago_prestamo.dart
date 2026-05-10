class PagoPrestamo {
  final String id;
  final String prestamoId;
  final String userId;
  final double monto;
  final DateTime fecha;
  final String? notas;
  final DateTime createdAt;

  const PagoPrestamo({
    required this.id,
    required this.prestamoId,
    required this.userId,
    required this.monto,
    required this.fecha,
    this.notas,
    required this.createdAt,
  });
}
