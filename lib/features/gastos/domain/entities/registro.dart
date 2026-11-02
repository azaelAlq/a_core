enum TipoRegistro { ingreso, gasto }

class Registro {
  final String id;
  final String userId;
  final String nombre;
  final double cantidad;
  final TipoRegistro tipo;
  final DateTime fecha;
  final DateTime createdAt;

  const Registro({
    required this.id,
    required this.userId,
    required this.nombre,
    required this.cantidad,
    required this.tipo,
    required this.fecha,
    required this.createdAt,
  });
}
