import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/system.dart';

class SystemModel extends System {
  const SystemModel({
    required super.id,
    required super.userId,
    required super.name,
    super.identity,
    super.cue,
    super.craving,
    required super.action,
    super.reward,
    required super.emoji,
    super.targetDays,
    super.currentStreak,
    super.longestStreak,
    required super.createdAt,
    super.isArchived,
  });

  factory SystemModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SystemModel(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String,
      identity: d['identity'] as String?,
      cue: d['cue'] as String?,
      craving: d['craving'] as String?,
      action: d['action'] as String? ?? '',
      reward: d['reward'] as String?,
      emoji: d['emoji'] as String? ?? '🎯',
      targetDays:
          (d['targetDays'] as List?)?.map((e) => e as int).toList() ?? const [1, 2, 3, 4, 5, 6, 7],
      currentStreak: d['currentStreak'] as int? ?? 0,
      longestStreak: d['longestStreak'] as int? ?? 0,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      isArchived: d['isArchived'] as bool? ?? false,
    );
  }

  factory SystemModel.fromEntity(System s) => SystemModel(
    id: s.id,
    userId: s.userId,
    name: s.name,
    identity: s.identity,
    cue: s.cue,
    craving: s.craving,
    action: s.action,
    reward: s.reward,
    emoji: s.emoji,
    targetDays: s.targetDays,
    currentStreak: s.currentStreak,
    longestStreak: s.longestStreak,
    createdAt: s.createdAt,
    isArchived: s.isArchived,
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'name': name,
    'identity': identity,
    'cue': cue,
    'craving': craving,
    'action': action,
    'reward': reward,
    'emoji': emoji,
    'targetDays': targetDays,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'createdAt': Timestamp.fromDate(createdAt),
    'isArchived': isArchived,
  };
}
