import 'dart:async';
import 'package:flutter/material.dart';

import '../../data/services/gym_service.dart';
import '../../domain/entities/routine.dart';

class GymProvider extends ChangeNotifier {
  final GymService _service = GymService();

  List<Routine> _routines = [];
  bool _loading = false;
  String? _error;

  StreamSubscription<List<Routine>>? _routinesSub;
  Timer? _saveTimer;

  List<Routine> get routines => _routines;
  bool get loading => _loading;
  String? get error => _error;

  // ── Init / streams ────────────────────────────

  void init(String userId) {
    _routinesSub?.cancel();
    _routinesSub = _service.watchRoutines(userId).listen((list) {
      _routines = list;
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

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _routinesSub?.cancel();
    _routinesSub = null;
    _saveTimer?.cancel();
    _saveTimer = null;
    _routines = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _routinesSub?.cancel();
    _saveTimer?.cancel();
    super.dispose();
  }
}
