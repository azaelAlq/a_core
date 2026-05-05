import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/achievement.dart';

class AchievementModel extends Achievement {
  const AchievementModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.habitId,
    required super.habitName,
    required super.unlockedAt,
  });

  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AchievementModel(
      id: doc.id,
      userId: d['userId'] as String,
      type: AchievementType.values.firstWhere(
        (t) => t.name == d['type'],
        orElse: () => AchievementType.first,
      ),
      habitId: d['habitId'] as String? ?? '',
      habitName: d['habitName'] as String? ?? '',
      unlockedAt: (d['unlockedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'type': type.name,
    'habitId': habitId,
    'habitName': habitName,
    'unlockedAt': Timestamp.fromDate(unlockedAt),
  };
}
