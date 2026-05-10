enum TipoCuenta { credito, debito, rendimiento, bolsa, otra }

class Cuenta {
  final String id;
  final String userId;
  final String nombre;
  final String? banco;
  final TipoCuenta tipo;
  final double saldo; // saldo actual
  final double? limiteCredito; // solo para crédito
  final String? notas;
  final String color; // hex string ej: 'FF1565C0'
  final DateTime createdAt;

  const Cuenta({
    required this.id,
    required this.userId,
    required this.nombre,
    this.banco,
    required this.tipo,
    required this.saldo,
    this.limiteCredito,
    this.notas,
    required this.color,
    required this.createdAt,
  });

  double get disponible =>
      tipo == TipoCuenta.credito && limiteCredito != null ? limiteCredito! - saldo : saldo;

  double get porcentajeUso =>
      tipo == TipoCuenta.credito && limiteCredito != null && limiteCredito! > 0
      ? (saldo / limiteCredito!).clamp(0.0, 1.0)
      : 0.0;

  Cuenta copyWith({
    String? nombre,
    String? banco,
    double? saldo,
    double? limiteCredito,
    String? notas,
    String? color,
  }) {
    return Cuenta(
      id: id,
      userId: userId,
      nombre: nombre ?? this.nombre,
      banco: banco ?? this.banco,
      tipo: tipo,
      saldo: saldo ?? this.saldo,
      limiteCredito: limiteCredito ?? this.limiteCredito,
      notas: notas ?? this.notas,
      color: color ?? this.color,
      createdAt: createdAt,
    );
  }
}
