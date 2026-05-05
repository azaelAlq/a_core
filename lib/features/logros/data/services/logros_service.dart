import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/achievement.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';
import '../models/achievement_model.dart';
import '../models/habit_log_model.dart';
import '../models/habit_model.dart';

class LogrosService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── Colecciones ───────────────────────────────
  CollectionReference _habits(String uid) => _db.collection('users').doc(uid).collection('habits');

  CollectionReference _logs(String uid) =>
      _db.collection('users').doc(uid).collection('habit_logs');

  CollectionReference _achievements(String uid) =>
      _db.collection('users').doc(uid).collection('achievements');

  // ── Habits CRUD ───────────────────────────────

  Future<Habit> createHabit({
    required String userId,
    required String name,
    String? description,
    required String emoji,
    required HabitFrequency frequency,
    required HabitType type,
    double? targetValue,
    String? unit,
  }) async {
    final id = _uuid.v4();
    final habit = HabitModel(
      id: id,
      userId: userId,
      name: name,
      description: description,
      emoji: emoji,
      frequency: frequency,
      type: type,
      targetValue: targetValue,
      unit: unit,
      createdAt: DateTime.now(),
    );
    await _habits(userId).doc(id).set(habit.toFirestore());
    return habit;
  }

  Future<void> deleteHabit(String userId, String habitId) async {
    await _habits(userId).doc(habitId).delete();
  }

  Stream<List<Habit>> watchHabits(String userId) {
    return _habits(userId).where('isArchived', isEqualTo: false).snapshots().map((s) {
      final list = s.docs.map((d) => HabitModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // orden en memoria
      return list;
    });
  }

  // ── Logs ──────────────────────────────────────

  /// Registra o actualiza el log del día para un hábito
  Future<HabitLog> logHabit({
    required String userId,
    required Habit habit,
    required bool completed,
    double? value,
    String? note,
    DateTime? date,
  }) async {
    final day = date ?? DateTime.now();
    final logDate = DateTime(day.year, day.month, day.day);
    final logId = HabitLog.keyFor(habit.id, logDate);

    final log = HabitLogModel(
      id: logId,
      habitId: habit.id,
      userId: userId,
      date: logDate,
      completed: completed,
      value: value,
      note: note,
      createdAt: DateTime.now(),
    );

    await _logs(userId).doc(logId).set(log.toFirestore());

    // Recalcula racha y desbloquea logros
    await _updateStreak(userId, habit, completed);

    return log;
  }

  /// Logs del mes para todos los hábitos (para el calendario)
  Stream<List<HabitLog>> watchMonthLogs(String userId, DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    return _logs(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((s) => s.docs.map((d) => HabitLogModel.fromFirestore(d)).toList());
  }

  /// Logs de un hábito específico (últimos 90 días, para heat map)
  Stream<List<HabitLog>> watchHabitLogs(String userId, String habitId) {
    final since = DateTime.now().subtract(const Duration(days: 90));
    return _logs(userId)
        .where('habitId', isEqualTo: habitId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => HabitLogModel.fromFirestore(d)).toList());
  }

  // ── Streak & Achievements ─────────────────────

  Future<void> _updateStreak(String userId, Habit habit, bool completed) async {
    final habitRef = _habits(userId).doc(habit.id);
    final doc = await habitRef.get();
    if (!doc.exists) return;

    final current = HabitModel.fromFirestore(doc);
    int newStreak = completed ? current.currentStreak + 1 : 0;
    int newLongest = newStreak > current.longestStreak ? newStreak : current.longestStreak;

    await habitRef.update({'currentStreak': newStreak, 'longestStreak': newLongest});

    if (completed) {
      await _checkAchievements(userId, habit, newStreak);
    }
  }

  Future<void> _checkAchievements(String userId, Habit habit, int streak) async {
    final milestones = {
      1: AchievementType.first,
      7: AchievementType.streak7,
      21: AchievementType.streak21,
      66: AchievementType.streak66,
      100: AchievementType.streak100,
    };

    final type = milestones[streak];
    if (type == null) return;

    // Verifica que no exista ya
    final existing = await _achievements(
      userId,
    ).where('type', isEqualTo: type.name).where('habitId', isEqualTo: habit.id).get();

    if (existing.docs.isNotEmpty) return;

    final id = _uuid.v4();
    final achievement = AchievementModel(
      id: id,
      userId: userId,
      type: type,
      habitId: habit.id,
      habitName: habit.name,
      unlockedAt: DateTime.now(),
    );
    await _achievements(userId).doc(id).set(achievement.toFirestore());
  }

  // ── Achievements ──────────────────────────────

  Stream<List<Achievement>> watchAchievements(String userId) {
    return _achievements(userId)
        .orderBy('unlockedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => AchievementModel.fromFirestore(d)).toList());
  }
}
