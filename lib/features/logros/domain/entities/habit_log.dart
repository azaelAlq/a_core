class HabitLog {
  final String id;
  final String habitId;
  final String userId;
  final DateTime date; // solo año/mes/día importa
  final bool completed;
  final double? value; // cantidad o minutos registrados
  final String? note;
  final DateTime createdAt;

  const HabitLog({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    required this.completed,
    this.value,
    this.note,
    required this.createdAt,
  });

  /// Clave única por hábito+día para evitar duplicados
  static String keyFor(String habitId, DateTime date) =>
      '${habitId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
