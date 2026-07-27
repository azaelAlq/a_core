/// Nota de bitácora general de entrenamiento (aparte de las carreras).
class TrainingNote {
  final String id;
  final String userId;
  final DateTime date;

  /// Fatiga 1..5, opcional.
  final int? fatigue;

  final String text;
  final DateTime createdAt;

  const TrainingNote({
    required this.id,
    required this.userId,
    required this.date,
    this.fatigue,
    required this.text,
    required this.createdAt,
  });

  TrainingNote copyWith({DateTime? date, int? fatigue, String? text}) {
    return TrainingNote(
      id: id,
      userId: userId,
      date: date ?? this.date,
      fatigue: fatigue ?? this.fatigue,
      text: text ?? this.text,
      createdAt: createdAt,
    );
  }
}
