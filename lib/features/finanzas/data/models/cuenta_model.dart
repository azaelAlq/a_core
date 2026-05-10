import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:a_core/features/finanzas/domain/entities/cuenta.dart';

class CuentaModel extends Cuenta {
  const CuentaModel({
    required super.id,
    required super.userId,
    required super.nombre,
    super.banco,
    required super.tipo,
    required super.saldo,
    super.limiteCredito,
    super.notas,
    required super.color,
    required super.createdAt,
  });

  factory CuentaModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CuentaModel(
      id: doc.id,
      userId: d['userId'] as String,
      nombre: d['nombre'] as String,
      banco: d['banco'] as String?,
      tipo: TipoCuenta.values.firstWhere((t) => t.name == d['tipo'], orElse: () => TipoCuenta.otra),
      saldo: (d['saldo'] as num).toDouble(),
      limiteCredito: (d['limiteCredito'] as num?)?.toDouble(),
      notas: d['notas'] as String?,
      color: d['color'] as String? ?? 'FF1565C0',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  factory CuentaModel.fromEntity(Cuenta c) => CuentaModel(
    id: c.id,
    userId: c.userId,
    nombre: c.nombre,
    banco: c.banco,
    tipo: c.tipo,
    saldo: c.saldo,
    limiteCredito: c.limiteCredito,
    notas: c.notas,
    color: c.color,
    createdAt: c.createdAt,
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'nombre': nombre,
    'banco': banco,
    'tipo': tipo.name,
    'saldo': saldo,
    'limiteCredito': limiteCredito,
    'notas': notas,
    'color': color,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
