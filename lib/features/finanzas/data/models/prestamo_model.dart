import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:a_core/features/finanzas/domain/entities/prestamo.dart';

class PrestamoModel extends Prestamo {
  const PrestamoModel({
    required super.id,
    required super.userId,
    required super.deudor,
    super.contacto,
    required super.montoOriginal,
    required super.montoPagado,
    required super.fechaPrestamo,
    super.fechaVencimiento,
    super.concepto,
    required super.estado,
    required super.createdAt,
  });

  factory PrestamoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PrestamoModel(
      id: doc.id,
      userId: d['userId'] as String,
      deudor: d['deudor'] as String,
      contacto: d['contacto'] as String?,
      montoOriginal: (d['montoOriginal'] as num).toDouble(),
      montoPagado: (d['montoPagado'] as num? ?? 0).toDouble(),
      fechaPrestamo: (d['fechaPrestamo'] as Timestamp).toDate(),
      fechaVencimiento: d['fechaVencimiento'] != null
          ? (d['fechaVencimiento'] as Timestamp).toDate()
          : null,
      concepto: d['concepto'] as String?,
      estado: EstadoPrestamo.values.firstWhere(
        (e) => e.name == d['estado'],
        orElse: () => EstadoPrestamo.activo,
      ),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'deudor': deudor,
    'contacto': contacto,
    'montoOriginal': montoOriginal,
    'montoPagado': montoPagado,
    'fechaPrestamo': Timestamp.fromDate(fechaPrestamo),
    'fechaVencimiento': fechaVencimiento != null ? Timestamp.fromDate(fechaVencimiento!) : null,
    'concepto': concepto,
    'estado': estado.name,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
