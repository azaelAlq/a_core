import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/habit_log.dart';

class HabitLogModel extends HabitLog {
  const HabitLogModel({
    required super.id,
    required super.habitId,
    required super.userId,
    required super.date,
    required super.completed,
    super.value,
    super.note,
    required super.createdAt,
  });

  factory HabitLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return HabitLogModel(
      id: doc.id,
      habitId: d['habitId'] as String,
      userId: d['userId'] as String,
      date: (d['date'] as Timestamp).toDate(),
      completed: d['completed'] as bool? ?? false,
      value: (d['value'] as num?)?.toDouble(),
      note: d['note'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  factory HabitLogModel.fromEntity(HabitLog l) => HabitLogModel(
    id: l.id,
    habitId: l.habitId,
    userId: l.userId,
    date: l.date,
    completed: l.completed,
    value: l.value,
    note: l.note,
    createdAt: l.createdAt,
  );

  Map<String, dynamic> toFirestore() => {
    'habitId': habitId,
    'userId': userId,
    'date': Timestamp.fromDate(date),
    'completed': completed,
    'value': value,
    'note': note,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
