class Pagina {
  final String id;
  final String libretaId;
  final String userId;
  final String titulo;
  final String contenido; // markdown
  final String? parentId; // null = página raíz, string = sub-página
  final int orden;
  final List<String> subPaginasIds; // ids de sub-páginas directas
  final DateTime createdAt;
  final DateTime updatedAt;

  const Pagina({
    required this.id,
    required this.libretaId,
    required this.userId,
    required this.titulo,
    this.contenido = '',
    this.parentId,
    this.orden = 0,
    this.subPaginasIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRoot => parentId == null;

  Pagina copyWith({
    String? titulo,
    String? contenido,
    int? orden,
    List<String>? subPaginasIds,
    DateTime? updatedAt,
  }) {
    return Pagina(
      id: id,
      libretaId: libretaId,
      userId: userId,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      parentId: parentId,
      orden: orden ?? this.orden,
      subPaginasIds: subPaginasIds ?? this.subPaginasIds,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
