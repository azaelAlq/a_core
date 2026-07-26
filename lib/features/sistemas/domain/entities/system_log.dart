class SystemLog {
  final String id;
  final String systemId;
  final String userId;
  final DateTime date; // solo año/mes/día importa
  final bool done;
  final String? note;
  final DateTime createdAt;

  const SystemLog({
    required this.id,
    required this.systemId,
    required this.userId,
    required this.date,
    required this.done,
    this.note,
    required this.createdAt,
  });

  /// Clave única por sistema + día para evitar duplicados
  static String keyFor(String systemId, DateTime date) =>
      '${systemId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
