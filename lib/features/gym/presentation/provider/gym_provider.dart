import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/services/gym_service.dart';
import '../../domain/entities/gym_session.dart';
import '../../domain/entities/routine.dart';

class GymProvider extends ChangeNotifier {
  final GymService _service = GymService();

  List<Routine> _routines = [];
  List<GymSession> _sessions = [];
  bool _loading = false;
  String? _error;

  StreamSubscription<List<Routine>>? _routinesSub;
  StreamSubscription<List<GymSession>>? _sessionsSub;
  Timer? _saveTimer;

  List<Routine> get routines => _routines;
  List<GymSession> get sessions => _sessions;
  bool get loading => _loading;
  String? get error => _error;

  /// Sesión en curso de una rutina (finishedAt == null), si existe.
  GymSession? activeSessionFor(String routineId) {
    for (final s in _sessions) {
      if (s.routineId == routineId && s.isInProgress) return s;
    }
    return null;
  }

  // ── Init / streams ────────────────────────────

  void init(String userId) {
    _routinesSub?.cancel();
    _routinesSub = _service.watchRoutines(userId).listen((list) {
      _routines = list;
      notifyListeners();
    });
    _sessionsSub?.cancel();
    _sessionsSub = _service.watchSessions(userId).listen((list) {
      _sessions = list;
      notifyListeners();
    });
  }

  // ── Acciones ──────────────────────────────────

  Future<Routine?> createRoutine(String userId, {required String name}) async {
    _loading = true;
    notifyListeners();
    try {
      return await _service.createRoutine(userId, name: name);
    } catch (_) {
      _error = 'No se pudo crear la rutina.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateRoutine(String userId, Routine routine) async {
    try {
      await _service.updateRoutine(userId, routine);
    } catch (_) {
      _error = 'No se pudo guardar la rutina.';
      notifyListeners();
    }
  }

  /// Guarda con un pequeño debounce para no escribir en cada tecla.
  void scheduleSave(String userId, Routine routine) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), () {
      updateRoutine(userId, routine);
    });
  }

  Future<void> deleteRoutine(String userId, String routineId) async {
    try {
      await _service.deleteRoutine(userId, routineId);
    } catch (_) {
      _error = 'No se pudo eliminar la rutina.';
      notifyListeners();
    }
  }

  // ── Sesiones ──────────────────────────────────

  /// Inicia una sesión para la rutina. Si ya hay una activa, se continúa esa.
  Future<void> startRoutine(String userId, Routine routine) async {
    if (activeSessionFor(routine.id) != null) return;
    try {
      await _service.startSession(userId, routine);
    } catch (_) {
      _error = 'No se pudo iniciar la rutina.';
      notifyListeners();
    }
  }

  /// Finaliza la sesión activa de la rutina, congelando el estado actual.
  Future<void> finishRoutine(String userId, Routine routine) async {
    final active = activeSessionFor(routine.id);
    if (active == null) return;
    try {
      await _service.finishSession(userId, active, routine);
    } catch (_) {
      _error = 'No se pudo finalizar la rutina.';
      notifyListeners();
    }
  }

  /// Pone done=false en todos los ejercicios y persiste. Retorna la rutina actualizada.
  Future<Routine> uncheckAllCompleted(String userId, Routine routine) async {
    final updated = routine.copyWith(
      blocks: routine.blocks
          .map(
            (b) => b.copyWith(
              exercises: b.exercises
                  .map((e) => e.copyWith(done: false))
                  .toList(),
            ),
          )
          .toList(),
    );
    await updateRoutine(userId, updated);
    return updated;
  }

  Future<void> deleteSession(String userId, String sessionId) async {
    try {
      await _service.deleteSession(userId, sessionId);
    } catch (_) {
      _error = 'No se pudo eliminar la sesión.';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _routinesSub?.cancel();
    _routinesSub = null;
    _sessionsSub?.cancel();
    _sessionsSub = null;
    _saveTimer?.cancel();
    _saveTimer = null;
    _routines = [];
    _sessions = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _routinesSub?.cancel();
    _sessionsSub?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}
