import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/services/gym_service.dart';
import '../../domain/entities/gym_session.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/run_activity.dart';
import '../../domain/entities/training_note.dart';

class GymProvider extends ChangeNotifier {
  final GymService _service = GymService();

  List<Routine> _routines = [];
  List<GymSession> _sessions = [];
  List<RunActivity> _runs = [];
  List<TrainingNote> _notes = [];
  bool _loading = false;
  String? _error;

  StreamSubscription<List<Routine>>? _routinesSub;
  StreamSubscription<List<GymSession>>? _sessionsSub;
  StreamSubscription<List<RunActivity>>? _runsSub;
  StreamSubscription<List<TrainingNote>>? _notesSub;
  Timer? _saveTimer;

  List<Routine> get routines => _routines;
  List<GymSession> get sessions => _sessions;
  List<RunActivity> get runs => _runs;
  List<TrainingNote> get notes => _notes;
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
    _runsSub?.cancel();
    _runsSub = _service.watchRuns(userId).listen((list) {
      _runs = list;
      notifyListeners();
    });
    _notesSub?.cancel();
    _notesSub = _service.watchNotes(userId).listen((list) {
      _notes = list;
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

  /// Guarda con debounce para no escribir a Firestore en cada tecla.
  void scheduleSave(String userId, Routine routine) {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
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

  // ── Carrera: actividades ──────────────────

  Future<RunActivity?> createRun(String userId, RunActivity run) async {
    try {
      return await _service.createRun(userId, run);
    } catch (_) {
      _error = 'No se pudo guardar la actividad.';
      notifyListeners();
      return null;
    }
  }

  Future<void> updateRun(String userId, RunActivity run) async {
    try {
      await _service.updateRun(userId, run);
    } catch (_) {
      _error = 'No se pudo guardar la actividad.';
      notifyListeners();
    }
  }

  Future<void> deleteRun(String userId, String runId) async {
    try {
      await _service.deleteRun(userId, runId);
    } catch (_) {
      _error = 'No se pudo eliminar la actividad.';
      notifyListeners();
    }
  }

  // ── Carrera: notas ────────────────────────

  Future<TrainingNote?> createNote(String userId, TrainingNote note) async {
    try {
      return await _service.createNote(userId, note);
    } catch (_) {
      _error = 'No se pudo guardar la nota.';
      notifyListeners();
      return null;
    }
  }

  Future<void> updateNote(String userId, TrainingNote note) async {
    try {
      await _service.updateNote(userId, note);
    } catch (_) {
      _error = 'No se pudo guardar la nota.';
      notifyListeners();
    }
  }

  Future<void> deleteNote(String userId, String noteId) async {
    try {
      await _service.deleteNote(userId, noteId);
    } catch (_) {
      _error = 'No se pudo eliminar la nota.';
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
    _runsSub?.cancel();
    _runsSub = null;
    _notesSub?.cancel();
    _notesSub = null;
    _saveTimer?.cancel();
    _saveTimer = null;
    _routines = [];
    _sessions = [];
    _runs = [];
    _notes = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _routinesSub?.cancel();
    _sessionsSub?.cancel();
    _runsSub?.cancel();
    _notesSub?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}
