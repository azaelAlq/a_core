import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/services/sistemas_service.dart';
import '../../domain/entities/system.dart';
import '../../domain/entities/system_log.dart';

class SistemasProvider extends ChangeNotifier {
  final SistemasService _service = SistemasService();

  List<System> _systems = [];
  List<SystemLog> _weekLogs = [];
  DateTime _selectedWeekStart = SistemasService.mondayOf(DateTime.now());
  bool _loading = false;
  String? _error;

  List<System> get systems => _systems;
  List<SystemLog> get weekLogs => _weekLogs;
  DateTime get selectedWeekStart => _selectedWeekStart;
  bool get loading => _loading;
  String? get error => _error;

  String? _uid;

  StreamSubscription<List<System>>? _systemsSub;
  StreamSubscription<List<SystemLog>>? _logsSub;

  // ── Helpers de fecha / semana ─────────────────

  List<DateTime> get weekDates =>
      List.generate(7, (i) => _selectedWeekStart.add(Duration(days: i)));

  bool get isCurrentWeek => _selectedWeekStart == SistemasService.mondayOf(DateTime.now());

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool isFuture(DateTime day) => DateTime(day.year, day.month, day.day).isAfter(_today);

  /// Fechas objetivo del sistema dentro de la semana seleccionada
  List<DateTime> scheduledDatesFor(System system) =>
      weekDates.where((d) => system.targetDays.contains(d.weekday)).toList();

  bool isDone(String systemId, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _weekLogs.any(
      (l) =>
          l.systemId == systemId &&
          l.done &&
          l.date.year == d.year &&
          l.date.month == d.month &&
          l.date.day == d.day,
    );
  }

  /// Cumplidos / objetivo de la semana para un sistema
  (int done, int total) weekProgress(System system) {
    final scheduled = scheduledDatesFor(system);
    final done = scheduled.where((d) => isDone(system.id, d)).length;
    return (done, scheduled.length);
  }

  /// Progreso global de la semana (solo cuenta días objetivo hasta hoy)
  double get overallWeekProgress {
    int done = 0;
    int total = 0;
    for (final s in _systems) {
      for (final d in scheduledDatesFor(s)) {
        if (isFuture(d)) continue;
        total++;
        if (isDone(s.id, d)) done++;
      }
    }
    return total == 0 ? 0 : done / total;
  }

  // ── Init / streams ────────────────────────────

  void init(String userId) {
    _uid = userId;
    _listenSystems(userId);
    _listenWeekLogs(userId);
  }

  void _listenSystems(String userId) {
    _systemsSub?.cancel();
    _systemsSub = _service.watchSystems(userId).listen((list) {
      _systems = list;
      notifyListeners();
    });
  }

  void _listenWeekLogs(String userId) {
    _logsSub?.cancel();
    _logsSub = _service.watchWeekLogs(userId, _selectedWeekStart).listen((list) {
      _weekLogs = list;
      notifyListeners();
    });
  }

  void previousWeek() {
    _selectedWeekStart = _selectedWeekStart.subtract(const Duration(days: 7));
    if (_uid != null) _listenWeekLogs(_uid!);
    notifyListeners();
  }

  void nextWeek() {
    _selectedWeekStart = _selectedWeekStart.add(const Duration(days: 7));
    if (_uid != null) _listenWeekLogs(_uid!);
    notifyListeners();
  }

  void goToCurrentWeek() {
    _selectedWeekStart = SistemasService.mondayOf(DateTime.now());
    if (_uid != null) _listenWeekLogs(_uid!);
    notifyListeners();
  }

  Stream<List<SystemLog>> historyStream(String userId, String systemId) =>
      _service.watchSystemLogs(userId, systemId);

  // ── Acciones ──────────────────────────────────

  Future<void> toggleDay(String userId, System system, DateTime date) async {
    try {
      await _service.toggleDay(userId: userId, system: system, date: date);
    } catch (_) {
      _error = 'No se pudo registrar el día.';
      notifyListeners();
    }
  }

  Future<void> createSystem({
    required String userId,
    required String name,
    String? identity,
    String? cue,
    String? craving,
    required String action,
    String? reward,
    required String emoji,
    required List<int> targetDays,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      await _service.createSystem(
        userId: userId,
        name: name,
        identity: identity,
        cue: cue,
        craving: craving,
        action: action,
        reward: reward,
        emoji: emoji,
        targetDays: targetDays,
      );
    } catch (_) {
      _error = 'No se pudo crear el sistema.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateSystem(String userId, System system) async {
    _loading = true;
    notifyListeners();
    try {
      await _service.updateSystem(userId, system);
    } catch (_) {
      _error = 'No se pudo actualizar el sistema.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteSystem(String userId, String systemId) async {
    try {
      await _service.deleteSystem(userId, systemId);
    } catch (_) {
      _error = 'No se pudo eliminar el sistema.';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _systemsSub?.cancel();
    _systemsSub = null;
    _logsSub?.cancel();
    _logsSub = null;
    _systems = [];
    _weekLogs = [];
    _selectedWeekStart = SistemasService.mondayOf(DateTime.now());
    _uid = null;
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _systemsSub?.cancel();
    _logsSub?.cancel();
    super.dispose();
  }
}
