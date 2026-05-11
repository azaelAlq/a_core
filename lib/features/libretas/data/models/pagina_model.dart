import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:a_core/features/libretas/domain/entities/pagina.dart';

class PaginaModel extends Pagina {
  const PaginaModel({
    required super.id,
    required super.libretaId,
    required super.userId,
    required super.titulo,
    super.contenido,
    super.parentId,
    super.orden,
    super.subPaginasIds,
    required super.createdAt,
    required super.updatedAt,
  });

  factory PaginaModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return PaginaModel(
      id: doc.id,
      libretaId: d['libretaId'] as String,
      userId: d['userId'] as String,
      titulo: d['titulo'] as String,
      contenido: d['contenido'] as String? ?? '',
      parentId: d['parentId'] as String?,
      orden: d['orden'] as int? ?? 0,
      subPaginasIds: List<String>.from(d['subPaginasIds'] ?? []),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory PaginaModel.fromEntity(Pagina p) => PaginaModel(
    id: p.id,
    libretaId: p.libretaId,
    userId: p.userId,
    titulo: p.titulo,
    contenido: p.contenido,
    parentId: p.parentId,
    orden: p.orden,
    subPaginasIds: p.subPaginasIds,
    createdAt: p.createdAt,
    updatedAt: p.updatedAt,
  );

  Map<String, dynamic> toFirestore() => {
    'libretaId': libretaId,
    'userId': userId,
    'titulo': titulo,
    'contenido': contenido,
    'parentId': parentId,
    'orden': orden,
    'subPaginasIds': subPaginasIds,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
