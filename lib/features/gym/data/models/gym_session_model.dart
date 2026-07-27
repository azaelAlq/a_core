import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/gym_session.dart';
import 'gym_routine_model.dart';

class GymSessionModel extends GymSession {
  const GymSessionModel({
    required super.id,
    required super.userId,
    required super.routineId,
    required super.routineName,
    required super.routineEmoji,
    required super.startedAt,
    super.finishedAt,
    super.durationSeconds,
    super.blocksSnapshot,
    required super.createdAt,
  });

  factory GymSessionModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GymSessionModel(
      id: doc.id,
      userId: d['userId'] as String,
      routineId: d['routineId'] as String,
      routineName: d['routineName'] as String? ?? '',
      routineEmoji: d['routineEmoji'] as String? ?? '🏋️',
      startedAt: (d['startedAt'] as Timestamp).toDate(),
      finishedAt: (d['finishedAt'] as Timestamp?)?.toDate(),
      durationSeconds: (d['durationSeconds'] as num?)?.toInt(),
      blocksSnapshot:
          (d['blocksSnapshot'] as List?)
              ?.map(
                (b) => GymRoutineModel.blockFromMap(
                  Map<String, dynamic>.from(b as Map),
                ),
              )
              .toList() ??
          const [],
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  factory GymSessionModel.fromEntity(GymSession s) => GymSessionModel(
    id: s.id,
    userId: s.userId,
    routineId: s.routineId,
    routineName: s.routineName,
    routineEmoji: s.routineEmoji,
    startedAt: s.startedAt,
    finishedAt: s.finishedAt,
    durationSeconds: s.durationSeconds,
    blocksSnapshot: s.blocksSnapshot,
    createdAt: s.createdAt,
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'routineId': routineId,
    'routineName': routineName,
    'routineEmoji': routineEmoji,
    'startedAt': Timestamp.fromDate(startedAt),
    'finishedAt': finishedAt == null ? null : Timestamp.fromDate(finishedAt!),
    'durationSeconds': durationSeconds,
    'blocksSnapshot': blocksSnapshot.map(GymRoutineModel.blockToMap).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
