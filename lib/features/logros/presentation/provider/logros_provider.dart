import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/services/logros_service.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/habit.dart';
import '../../domain/entities/habit_log.dart';

class LogrosProvider extends ChangeNotifier {
  final LogrosService _service = LogrosService();

  List<Habit> _habits = [];
  List<HabitLog> _monthLogs = [];
  List<Achievement> _achievements = [];
  DateTime _selectedMonth = DateTime.now();
  bool _loading = false;
  String? _error;

  // Logro recién desbloqueado para mostrar banner
  Achievement? _newAchievement;

  List<Habit> get habits => _habits;
  List<HabitLog> get monthLogs => _monthLogs;
  List<Achievement> get achievements => _achievements;
  DateTime get selectedMonth => _selectedMonth;
  bool get loading => _loading;
  String? get error => _error;
  Achievement? get newAchievement => _newAchievement;

  StreamSubscription<List<Habit>>? _habitsSub;
  StreamSubscription<List<HabitLog>>? _logsSub;
  StreamSubscription<List<Achievement>>? _achievementsSub;

  // Logs del día actual
  List<HabitLog> get todayLogs {
    final today = DateTime.now();
    return _monthLogs
        .where(
          (l) =>
              l.date.year == today.year && l.date.month == today.month && l.date.day == today.day,
        )
        .toList();
  }

  // ¿Está completado hoy?
  bool isCompletedToday(String habitId) =>
      todayLogs.any((l) => l.habitId == habitId && l.completed);

  // Log del día para un hábito
  HabitLog? logForDay(String habitId, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    try {
      return _monthLogs.firstWhere(
        (l) =>
            l.habitId == habitId &&
            l.date.year == d.year &&
            l.date.month == d.month &&
            l.date.day == d.day,
      );
    } catch (_) {
      return null;
    }
  }

  // Días completados en el mes para un hábito
  Set<DateTime> completedDaysFor(String habitId) {
    return _monthLogs
        .where((l) => l.habitId == habitId && l.completed)
        .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
        .toSet();
  }

  void init(String userId) {
    _listenHabits(userId);
    _listenLogs(userId);
    _listenAchievements(userId);
  }

  void _listenHabits(String userId) {
    _habitsSub?.cancel();
    _habitsSub = _service.watchHabits(userId).listen((list) {
      _habits = list;
      notifyListeners();
    });
  }

  void _listenLogs(String userId) {
    _logsSub?.cancel();
    _logsSub = _service.watchMonthLogs(userId, _selectedMonth).listen((list) {
      _monthLogs = list;
      notifyListeners();
    });
  }

  void _listenAchievements(String userId) {
    final prevCount = _achievements.length;
    _achievementsSub?.cancel();
    _achievementsSub = _service.watchAchievements(userId).listen((list) {
      if (list.length > prevCount && _achievements.isNotEmpty) {
        _newAchievement = list.first;
      }
      _achievements = list;
      notifyListeners();
    });
  }

  void changeMonth(String userId, DateTime month) {
    _selectedMonth = month;
    _listenLogs(userId);
    notifyListeners();
  }

  Future<void> createHabit({
    required String userId,
    required String name,
    String? description,
    required String emoji,
    required HabitFrequency frequency,
    required HabitType type,
    double? targetValue,
    String? unit,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      await _service.createHabit(
        userId: userId,
        name: name,
        description: description,
        emoji: emoji,
        frequency: frequency,
        type: type,
        targetValue: targetValue,
        unit: unit,
      );
    } catch (_) {
      _error = 'No se pudo crear el hábito.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logHabit({
    required String userId,
    required Habit habit,
    required bool completed,
    double? value,
    String? note,
    DateTime? date,
  }) async {
    try {
      await _service.logHabit(
        userId: userId,
        habit: habit,
        completed: completed,
        value: value,
        note: note,
        date: date,
      );
    } catch (_) {
      _error = 'No se pudo registrar el hábito.';
      notifyListeners();
    }
  }

  Future<void> deleteHabit(String userId, String habitId) async {
    try {
      await _service.deleteHabit(userId, habitId);
    } catch (_) {
      _error = 'No se pudo eliminar el hábito.';
      notifyListeners();
    }
  }

  void clearNewAchievement() {
    _newAchievement = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _habitsSub?.cancel();
    _habitsSub = null;
    _logsSub?.cancel();
    _logsSub = null;
    _achievementsSub?.cancel();
    _achievementsSub = null;
    _habits = [];
    _monthLogs = [];
    _achievements = [];
    _selectedMonth = DateTime.now();
    _loading = false;
    _error = null;
    _newAchievement = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _habitsSub?.cancel();
    _logsSub?.cancel();
    _achievementsSub?.cancel();
    super.dispose();
  }
}
