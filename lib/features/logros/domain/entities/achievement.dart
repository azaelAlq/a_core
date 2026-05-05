enum AchievementType {
  streak7, // 7 días seguidos
  streak21, // 21 días seguidos
  streak66, // 66 días seguidos
  streak100, // 100 días seguidos
  first, // primera vez completado
  perfect7, // semana perfecta (todos los hábitos)
  habits5, // 5 hábitos creados
}

class Achievement {
  final String id;
  final String userId;
  final AchievementType type;
  final String habitId; // a qué hábito corresponde (vacío si es global)
  final String habitName;
  final DateTime unlockedAt;

  const Achievement({
    required this.id,
    required this.userId,
    required this.type,
    required this.habitId,
    required this.habitName,
    required this.unlockedAt,
  });

  static String labelFor(AchievementType type) {
    switch (type) {
      case AchievementType.streak7:
        return '7 días seguidos 🔥';
      case AchievementType.streak21:
        return '21 días seguidos ⚡';
      case AchievementType.streak66:
        return '66 días seguidos 💎';
      case AchievementType.streak100:
        return '100 días seguidos 👑';
      case AchievementType.first:
        return 'Primera vez ⭐';
      case AchievementType.perfect7:
        return 'Semana perfecta 🏆';
      case AchievementType.habits5:
        return '5 hábitos activos 🌟';
    }
  }

  static String descriptionFor(AchievementType type) {
    switch (type) {
      case AchievementType.streak7:
        return 'Completaste un hábito 7 días consecutivos';
      case AchievementType.streak21:
        return 'Completaste un hábito 21 días consecutivos';
      case AchievementType.streak66:
        return '¡Ya es un hábito real! 66 días';
      case AchievementType.streak100:
        return 'Leyenda. 100 días sin fallar';
      case AchievementType.first:
        return 'Completaste un hábito por primera vez';
      case AchievementType.perfect7:
        return 'Todos tus hábitos cumplidos en 7 días';
      case AchievementType.habits5:
        return 'Tienes 5 hábitos activos';
    }
  }

  static String emojiFor(AchievementType type) {
    switch (type) {
      case AchievementType.streak7:
        return '🔥';
      case AchievementType.streak21:
        return '⚡';
      case AchievementType.streak66:
        return '💎';
      case AchievementType.streak100:
        return '👑';
      case AchievementType.first:
        return '⭐';
      case AchievementType.perfect7:
        return '🏆';
      case AchievementType.habits5:
        return '🌟';
    }
  }
}
