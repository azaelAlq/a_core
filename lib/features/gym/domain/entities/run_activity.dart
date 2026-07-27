/// Actividad de cardio registrada manualmente (correr, caminar, bici…).
class RunActivity {
  final String id;
  final String userId;

  /// Fecha y hora en que se realizó la actividad.
  final DateTime performedAt;

  /// Tipo de actividad (Correr, Caminar, Trotar, Bici, Otro…).
  final String activity;

  final double distanceKm;

  /// Duración total en segundos (se captura como hh:mm:ss).
  final int durationSeconds;

  final int? steps;
  final int? activeCalories;
  final int? totalCalories;
  final int? avgHr;
  final int? maxHr;

  /// Fatiga percibida 1..5.
  final int? perceivedFatigue;

  final String? notes;
  final DateTime createdAt;

  const RunActivity({
    required this.id,
    required this.userId,
    required this.performedAt,
    this.activity = 'Correr',
    required this.distanceKm,
    required this.durationSeconds,
    this.steps,
    this.activeCalories,
    this.totalCalories,
    this.avgHr,
    this.maxHr,
    this.perceivedFatigue,
    this.notes,
    required this.createdAt,
  });

  /// Ritmo calculado en segundos por km; null si no hay distancia.
  int? get paceSecondsPerKm =>
      distanceKm > 0 ? (durationSeconds / distanceKm).round() : null;

  RunActivity copyWith({
    DateTime? performedAt,
    String? activity,
    double? distanceKm,
    int? durationSeconds,
    int? steps,
    int? activeCalories,
    int? totalCalories,
    int? avgHr,
    int? maxHr,
    int? perceivedFatigue,
    String? notes,
  }) {
    return RunActivity(
      id: id,
      userId: userId,
      performedAt: performedAt ?? this.performedAt,
      activity: activity ?? this.activity,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      steps: steps ?? this.steps,
      activeCalories: activeCalories ?? this.activeCalories,
      totalCalories: totalCalories ?? this.totalCalories,
      avgHr: avgHr ?? this.avgHr,
      maxHr: maxHr ?? this.maxHr,
      perceivedFatigue: perceivedFatigue ?? this.perceivedFatigue,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
