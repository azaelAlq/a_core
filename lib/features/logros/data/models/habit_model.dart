import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/habit.dart';

class HabitModel extends Habit {
  const HabitModel({
    required super.id,
    required super.userId,
    required super.name,
    super.description,
    required super.emoji,
    required super.frequency,
    required super.type,
    super.targetValue,
    super.unit,
    super.currentStreak,
    super.longestStreak,
    required super.createdAt,
    super.isArchived,
  });

  factory HabitModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return HabitModel(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String,
      description: d['description'] as String?,
      emoji: d['emoji'] as String? ?? '✅',
      frequency: HabitFrequency.values.firstWhere(
        (f) => f.name == d['frequency'],
        orElse: () => HabitFrequency.daily,
      ),
      type: HabitType.values.firstWhere((t) => t.name == d['type'], orElse: () => HabitType.yesNo),
      targetValue: (d['targetValue'] as num?)?.toDouble(),
      unit: d['unit'] as String?,
      currentStreak: d['currentStreak'] as int? ?? 0,
      longestStreak: d['longestStreak'] as int? ?? 0,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      isArchived: d['isArchived'] as bool? ?? false,
    );
  }

  factory HabitModel.fromEntity(Habit h) => HabitModel(
    id: h.id,
    userId: h.userId,
    name: h.name,
    description: h.description,
    emoji: h.emoji,
    frequency: h.frequency,
    type: h.type,
    targetValue: h.targetValue,
    unit: h.unit,
    currentStreak: h.currentStreak,
    longestStreak: h.longestStreak,
    createdAt: h.createdAt,
    isArchived: h.isArchived,
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'name': name,
    'description': description,
    'emoji': emoji,
    'frequency': frequency.name,
    'type': type.name,
    'targetValue': targetValue,
    'unit': unit,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'createdAt': Timestamp.fromDate(createdAt),
    'isArchived': isArchived,
  };
}
