import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:a_core/features/libretas/domain/entities/libreta.dart';

class LibretaModel extends Libreta {
  const LibretaModel({
    required super.id,
    required super.userId,
    required super.titulo,
    super.descripcion,
    required super.emoji,
    required super.color,
    super.paginasCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LibretaModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return LibretaModel(
      id: doc.id,
      userId: d['userId'] as String? ?? '', // <-- evita crash si es null
      titulo: d['titulo'] as String? ?? 'Sin título',
      descripcion: d['descripcion'] as String?,
      emoji: d['emoji'] as String? ?? '📓',
      color: d['color'] as String? ?? '1565C0',
      paginasCount: d['paginasCount'] as int? ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory LibretaModel.fromEntity(Libreta l) => LibretaModel(
    id: l.id,
    userId: l.userId,
    titulo: l.titulo,
    descripcion: l.descripcion,
    emoji: l.emoji,
    color: l.color,
    paginasCount: l.paginasCount,
    createdAt: l.createdAt,
    updatedAt: l.updatedAt,
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'titulo': titulo,
    'descripcion': descripcion,
    'emoji': emoji,
    'color': color,
    'paginasCount': paginasCount,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
