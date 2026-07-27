import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/run_activity.dart';

class RunActivityModel extends RunActivity {
  const RunActivityModel({
    required super.id,
    required super.userId,
    required super.performedAt,
    super.activity,
    required super.distanceKm,
    required super.durationSeconds,
    super.steps,
    super.activeCalories,
    super.totalCalories,
    super.avgHr,
    super.maxHr,
    super.perceivedFatigue,
    super.notes,
    required super.createdAt,
  });

  factory RunActivityModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RunActivityModel(
      id: doc.id,
      userId: d['userId'] as String,
      performedAt: (d['performedAt'] as Timestamp).toDate(),
      activity: d['activity'] as String? ?? 'Correr',
      distanceKm: (d['distanceKm'] as num?)?.toDouble() ?? 0,
      durationSeconds: (d['durationSeconds'] as num?)?.toInt() ?? 0,
      steps: (d['steps'] as num?)?.toInt(),
      activeCalories: (d['activeCalories'] as num?)?.toInt(),
      totalCalories: (d['totalCalories'] as num?)?.toInt(),
      avgHr: (d['avgHr'] as num?)?.toInt(),
      maxHr: (d['maxHr'] as num?)?.toInt(),
      perceivedFatigue: (d['perceivedFatigue'] as num?)?.toInt(),
      notes: d['notes'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  factory RunActivityModel.fromEntity(RunActivity r) => RunActivityModel(
    id: r.id,
    userId: r.userId,
    performedAt: r.performedAt,
    activity: r.activity,
    distanceKm: r.distanceKm,
    durationSeconds: r.durationSeconds,
    steps: r.steps,
    activeCalories: r.activeCalories,
    totalCalories: r.totalCalories,
    avgHr: r.avgHr,
    maxHr: r.maxHr,
    perceivedFatigue: r.perceivedFatigue,
    notes: r.notes,
    createdAt: r.createdAt,
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'performedAt': Timestamp.fromDate(performedAt),
    'activity': activity,
    'distanceKm': distanceKm,
    'durationSeconds': durationSeconds,
    'steps': steps,
    'activeCalories': activeCalories,
    'totalCalories': totalCalories,
    'avgHr': avgHr,
    'maxHr': maxHr,
    'perceivedFatigue': perceivedFatigue,
    'notes': notes,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
