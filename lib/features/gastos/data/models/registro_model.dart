import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:a_core/features/gastos/domain/entities/registro.dart';

class RegistroModel extends Registro {
  const RegistroModel({
    required super.id,
    required super.userId,
    required super.nombre,
    required super.cantidad,
    required super.tipo,
    required super.fecha,
    required super.createdAt,
  });

  factory RegistroModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RegistroModel(
      id: doc.id,
      userId: d['userId'] as String,
      nombre: d['nombre'] as String,
      cantidad: (d['cantidad'] as num).toDouble(),
      tipo: TipoRegistro.values.firstWhere((t) => t.name == d['tipo']),
      fecha: (d['fecha'] as Timestamp).toDate(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'nombre': nombre,
    'cantidad': cantidad,
    'tipo': tipo.name,
    'fecha': Timestamp.fromDate(fecha),
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
