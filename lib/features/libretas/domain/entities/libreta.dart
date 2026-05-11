class Libreta {
  final String id;
  final String userId;
  final String titulo;
  final String? descripcion;
  final String emoji;
  final String color; // hex sin #
  final int paginasCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Libreta({
    required this.id,
    required this.userId,
    required this.titulo,
    this.descripcion,
    required this.emoji,
    required this.color,
    this.paginasCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Libreta copyWith({
    String? titulo,
    String? descripcion,
    String? emoji,
    String? color,
    int? paginasCount,
    DateTime? updatedAt,
  }) {
    return Libreta(
      id: id,
      userId: userId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      paginasCount: paginasCount ?? this.paginasCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
