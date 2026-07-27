import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/routine.dart';

class GymRoutineModel extends Routine {
  const GymRoutineModel({
    required super.id,
    required super.userId,
    required super.name,
    super.notes,
    super.emoji,
    super.blocks,
    required super.createdAt,
    super.isArchived,
  });

  factory GymRoutineModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GymRoutineModel(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String? ?? '',
      notes: d['notes'] as String?,
      emoji: d['emoji'] as String? ?? '🏋️',
      blocks:
          (d['blocks'] as List?)
              ?.map((b) => blockFromMap(Map<String, dynamic>.from(b as Map)))
              .toList() ??
          const [],
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      isArchived: d['isArchived'] as bool? ?? false,
    );
  }

  factory GymRoutineModel.fromEntity(Routine r) => GymRoutineModel(
    id: r.id,
    userId: r.userId,
    name: r.name,
    notes: r.notes,
    emoji: r.emoji,
    blocks: r.blocks,
    createdAt: r.createdAt,
    isArchived: r.isArchived,
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'name': name,
    'notes': notes,
    'emoji': emoji,
    'blocks': blocks.map(blockToMap).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'isArchived': isArchived,
  };

  // ── Bloques ───────────────────────────────

  static Block blockFromMap(Map<String, dynamic> m) => Block(
    id: m['id'] as String,
    label: m['label'] as String?,
    series: (m['series'] as num?)?.toInt() ?? 1,
    exercises:
        (m['exercises'] as List?)
            ?.map((e) => exerciseFromMap(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        const [],
  );

  static Map<String, dynamic> blockToMap(Block b) => {
    'id': b.id,
    'label': b.label,
    'series': b.series,
    'exercises': b.exercises.map(exerciseToMap).toList(),
  };

  // ── Ejercicios ────────────────────────────

  static Exercise exerciseFromMap(Map<String, dynamic> m) => Exercise(
    id: m['id'] as String,
    name: m['name'] as String? ?? '',
    done: m['done'] as bool? ?? false,
    perSide: m['perSide'] as bool? ?? false,
    notes: m['notes'] as String?,
    sets:
        (m['sets'] as List?)
            ?.map((s) => setFromMap(Map<String, dynamic>.from(s as Map)))
            .toList() ??
        const [],
  );

  static Map<String, dynamic> exerciseToMap(Exercise e) => {
    'id': e.id,
    'name': e.name,
    'done': e.done,
    'perSide': e.perSide,
    'notes': e.notes,
    'sets': e.sets.map(setToMap).toList(),
  };

  // ── Series ────────────────────────────────

  static SetEntry setFromMap(Map<String, dynamic> m) => SetEntry(
    reps: (m['reps'] as num?)?.toInt(),
    weight: (m['weight'] as num?)?.toDouble(),
  );

  static Map<String, dynamic> setToMap(SetEntry s) => {
    'reps': s.reps,
    'weight': s.weight,
  };
}
