import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:a_core/features/finanzas/domain/entities/movimiento.dart';

class MovimientoModel extends Movimiento {
  const MovimientoModel({
    required super.id,
    required super.cuentaId,
    required super.userId,
    required super.tipo,
    required super.monto,
    required super.concepto,
    super.notas,
    required super.fecha,
    required super.createdAt,
  });

  factory MovimientoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return MovimientoModel(
      id: doc.id,
      cuentaId: d['cuentaId'] as String,
      userId: d['userId'] as String,
      tipo: TipoMovimiento.values.firstWhere((t) => t.name == d['tipo']),
      monto: (d['monto'] as num).toDouble(),
      concepto: d['concepto'] as String,
      notas: d['notas'] as String?,
      fecha: (d['fecha'] as Timestamp).toDate(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  factory MovimientoModel.fromEntity(Movimiento m) => MovimientoModel(
    id: m.id,
    cuentaId: m.cuentaId,
    userId: m.userId,
    tipo: m.tipo,
    monto: m.monto,
    concepto: m.concepto,
    notas: m.notas,
    fecha: m.fecha,
    createdAt: m.createdAt,
  );

  Map<String, dynamic> toFirestore() => {
    'cuentaId': cuentaId,
    'userId': userId,
    'tipo': tipo.name,
    'monto': monto,
    'concepto': concepto,
    'notas': notas,
    'fecha': Timestamp.fromDate(fecha),
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
