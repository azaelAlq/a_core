import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:a_core/features/finanzas/domain/entities/uso_credito.dart';

class UsoCreditoModel extends UsoCredito {
  const UsoCreditoModel({
    required super.id,
    required super.userId,
    required super.cuentaId,
    required super.persona,
    required super.montoTotal,
    required super.montoPagado,
    super.mesesPago,
    super.pagoMensual,
    required super.concepto,
    required super.fecha,
    required super.estado,
    required super.createdAt,
  });

  factory UsoCreditoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UsoCreditoModel(
      id: doc.id,
      userId: d['userId'] as String,
      cuentaId: d['cuentaId'] as String,
      persona: d['persona'] as String,
      montoTotal: (d['montoTotal'] as num).toDouble(),
      montoPagado: (d['montoPagado'] as num? ?? 0).toDouble(),
      mesesPago: d['mesesPago'] as int?,
      pagoMensual: (d['pagoMensual'] as num?)?.toDouble(),
      concepto: d['concepto'] as String,
      fecha: (d['fecha'] as Timestamp).toDate(),
      estado: EstadoUsoCredito.values.firstWhere(
        (e) => e.name == d['estado'],
        orElse: () => EstadoUsoCredito.pendiente,
      ),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'cuentaId': cuentaId,
    'persona': persona,
    'montoTotal': montoTotal,
    'montoPagado': montoPagado,
    'mesesPago': mesesPago,
    'pagoMensual': pagoMensual,
    'concepto': concepto,
    'fecha': Timestamp.fromDate(fecha),
    'estado': estado.name,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
