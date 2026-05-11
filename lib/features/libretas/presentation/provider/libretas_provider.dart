import 'dart:async';
import 'package:flutter/material.dart';

import 'package:a_core/features/libretas/data/services/libretas_service.dart';
import 'package:a_core/features/libretas/domain/entities/libreta.dart';
import 'package:a_core/features/libretas/domain/entities/pagina.dart';

class LibretasProvider extends ChangeNotifier {
  final LibretasService _service = LibretasService();

  List<Libreta> _libretas = [];
  // Páginas por libretaId
  final Map<String, List<Pagina>> _paginasPorLibreta = {};
  final Map<String, StreamSubscription> _paginasSubs = {};
  StreamSubscription? _libretasSub;

  bool _loading = false;
  String? _error;

  List<Libreta> get libretas => _libretas;
  bool get loading => _loading;
  String? get error => _error;

  List<Pagina> paginasDe(String libretaId) => _paginasPorLibreta[libretaId] ?? [];

  List<Pagina> rootsDe(String libretaId) => paginasDe(libretaId).where((p) => p.isRoot).toList();

  List<Pagina> subPaginasDe(String libretaId, String parentId) =>
      paginasDe(libretaId).where((p) => p.parentId == parentId).toList();

  void init(String userId) {
    _libretasSub?.cancel();
    _libretasSub = _service.watchLibretas(userId).listen((list) {
      _libretas = list;
      notifyListeners();
    });
  }

  void watchPaginas(String userId, String libretaId) {
    if (_paginasSubs.containsKey(libretaId)) return;
    _paginasSubs[libretaId] = _service.watchPaginas(userId, libretaId).listen((list) {
      _paginasPorLibreta[libretaId] = list;
      notifyListeners();
    });
  }

  // ── Libretas ──────────────────────────────────

  Future<Libreta?> createLibreta({
    required String userId,
    required String titulo,
    String? descripcion,
    required String emoji,
    required String color,
  }) async {
    _setLoading();
    try {
      final l = await _service.createLibreta(
        userId: userId,
        titulo: titulo,
        descripcion: descripcion,
        emoji: emoji,
        color: color,
      );
      return l;
    } catch (_) {
      _error = 'No se pudo crear la libreta.';
      return null;
    } finally {
      _doneLoading();
    }
  }

  Future<void> deleteLibreta(String userId, String libretaId) async {
    try {
      _paginasSubs[libretaId]?.cancel();
      _paginasSubs.remove(libretaId);
      _paginasPorLibreta.remove(libretaId);
      await _service.deleteLibreta(userId, libretaId);
    } catch (_) {
      _error = 'No se pudo eliminar la libreta.';
      notifyListeners();
    }
  }

  // ── Páginas ───────────────────────────────────

  Future<Pagina?> createPagina({
    required String userId,
    required String libretaId,
    required String titulo,
    String? parentId,
  }) async {
    _setLoading();
    try {
      return await _service.createPagina(
        userId: userId,
        libretaId: libretaId,
        titulo: titulo,
        parentId: parentId,
      );
    } catch (_) {
      _error = 'No se pudo crear la página.';
      return null;
    } finally {
      _doneLoading();
    }
  }

  Future<void> savePagina(String userId, Pagina pagina) async {
    try {
      await _service.savePagina(userId, pagina);
    } catch (_) {
      _error = 'No se pudo guardar la página.';
      notifyListeners();
    }
  }

  Future<void> deletePagina(String userId, Pagina pagina) async {
    try {
      await _service.deletePagina(userId, pagina);
    } catch (_) {
      _error = 'No se pudo eliminar la página.';
      notifyListeners();
    }
  }

  Future<void> renamePagina(String userId, String paginaId, String nuevoTitulo) async {
    try {
      await _service.renamePagina(userId, paginaId, nuevoTitulo);
    } catch (_) {
      _error = 'No se pudo renombrar la página.';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void _doneLoading() {
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _libretasSub?.cancel();
    for (final s in _paginasSubs.values) s.cancel();
    super.dispose();
  }
}
