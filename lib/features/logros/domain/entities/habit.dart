enum HabitFrequency { daily, weekly }

enum HabitType { yesNo, quantity, time }

class Habit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String emoji;
  final HabitFrequency frequency;
  final HabitType type;
  final double? targetValue; // cantidad o minutos objetivo
  final String? unit; // 'vasos', 'minutos', 'km', etc.
  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final bool isArchived;

  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.emoji,
    required this.frequency,
    required this.type,
    this.targetValue,
    this.unit,
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.createdAt,
    this.isArchived = false,
  });

  Habit copyWith({
    String? name,
    String? description,
    String? emoji,
    HabitFrequency? frequency,
    HabitType? type,
    double? targetValue,
    String? unit,
    int? currentStreak,
    int? longestStreak,
    bool? isArchived,
  }) {
    return Habit(
      id: id,
      userId: userId,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      frequency: frequency ?? this.frequency,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
