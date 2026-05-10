import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:a_core/features/finanzas/domain/entities/pago_prestamo.dart';

class PagoPrestamoModel extends PagoPrestamo {
  const PagoPrestamoModel({
    required super.id,
    required super.prestamoId,
    required super.userId,
    required super.monto,
    required super.fecha,
    super.notas,
    required super.createdAt,
  });

  factory PagoPrestamoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PagoPrestamoModel(
      id: doc.id,
      prestamoId: d['prestamoId'] as String,
      userId: d['userId'] as String,
      monto: (d['monto'] as num).toDouble(),
      fecha: (d['fecha'] as Timestamp).toDate(),
      notas: d['notas'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'prestamoId': prestamoId,
    'userId': userId,
    'monto': monto,
    'fecha': Timestamp.fromDate(fecha),
    'notas': notas,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
