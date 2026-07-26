class System {
  final String id;
  final String userId;
  final String name;

  // Identidad: "Quiero convertirme en el tipo de persona que..."
  final String? identity;

  // Ley 1 · Hazlo obvio → señal (cuándo y dónde)
  final String? cue;

  // Ley 2 · Hazlo atractivo → por qué / motivación
  final String? craving;

  // Ley 3 · Hazlo fácil → la acción (versión de 2 minutos)
  final String action;

  // Ley 4 · Hazlo satisfactorio → recompensa
  final String? reward;

  final String emoji;

  /// Días objetivo de la semana (1 = lunes ... 7 = domingo)
  final List<int> targetDays;

  final int currentStreak;
  final int longestStreak;
  final DateTime createdAt;
  final bool isArchived;

  const System({
    required this.id,
    required this.userId,
    required this.name,
    this.identity,
    this.cue,
    this.craving,
    required this.action,
    this.reward,
    required this.emoji,
    this.targetDays = const [1, 2, 3, 4, 5, 6, 7],
    this.currentStreak = 0,
    this.longestStreak = 0,
    required this.createdAt,
    this.isArchived = false,
  });

  static const weekdayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static String dayLabel(int weekday) => weekdayLabels[weekday - 1];

  System copyWith({
    String? name,
    String? identity,
    String? cue,
    String? craving,
    String? action,
    String? reward,
    String? emoji,
    List<int>? targetDays,
    int? currentStreak,
    int? longestStreak,
    bool? isArchived,
  }) {
    return System(
      id: id,
      userId: userId,
      name: name ?? this.name,
      identity: identity ?? this.identity,
      cue: cue ?? this.cue,
      craving: craving ?? this.craving,
      action: action ?? this.action,
      reward: reward ?? this.reward,
      emoji: emoji ?? this.emoji,
      targetDays: targetDays ?? this.targetDays,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
