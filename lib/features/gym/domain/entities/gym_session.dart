import 'routine.dart';

class GymSession {
  final String id;
  final String userId;
  final String routineId;

  /// Denormalizados para mostrar la sesión aunque la rutina se edite o borre
  final String routineName;
  final String routineEmoji;

  final DateTime startedAt;

  /// null mientras la sesión está en curso
  final DateTime? finishedAt;

  /// Se calcula al finalizar
  final int? durationSeconds;

  /// Copia congelada de routine.blocks al finalizar
  final List<Block> blocksSnapshot;

  final DateTime createdAt;

  const GymSession({
    required this.id,
    required this.userId,
    required this.routineId,
    required this.routineName,
    required this.routineEmoji,
    required this.startedAt,
    this.finishedAt,
    this.durationSeconds,
    this.blocksSnapshot = const [],
    required this.createdAt,
  });

  bool get isInProgress => finishedAt == null;

  GymSession copyWith({
    DateTime? finishedAt,
    int? durationSeconds,
    List<Block>? blocksSnapshot,
  }) {
    return GymSession(
      id: id,
      userId: userId,
      routineId: routineId,
      routineName: routineName,
      routineEmoji: routineEmoji,
      startedAt: startedAt,
      finishedAt: finishedAt ?? this.finishedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      blocksSnapshot: blocksSnapshot ?? this.blocksSnapshot,
      createdAt: createdAt,
    );
  }
}
