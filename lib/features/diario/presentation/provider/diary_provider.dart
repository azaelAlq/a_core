import 'dart:async';
import 'package:flutter/material.dart';
import 'package:a_core/features/diario/data/services/diary_service.dart';
import 'package:a_core/features/diario/domain/entities/diary_entry.dart';
import 'package:a_core/features/diario/domain/entities/diary_template.dart';

enum DiaryFilter { week, month }

class DiaryProvider extends ChangeNotifier {
  final DiaryService _service = DiaryService();

  List<DiaryEntry> _entries = [];
  List<DiaryTemplate> _templates = [];
  DiaryFilter _filter = DiaryFilter.week;
  bool _loading = false;
  String? _error;

  StreamSubscription<List<DiaryEntry>>? _entriesSub;
  StreamSubscription<List<DiaryTemplate>>? _templatesSub;

  List<DiaryEntry> get entries => _entries;
  List<DiaryTemplate> get templates => _templates;
  DiaryFilter get filter => _filter;
  bool get loading => _loading;
  String? get error => _error;

  void init(String userId) {
    _listenEntries(userId);
    _listenTemplates(userId);
  }

  void setFilter(DiaryFilter f, String userId) {
    _filter = f;
    _listenEntries(userId);
    notifyListeners();
  }

  void _listenEntries(String userId) {
    _entriesSub?.cancel();
    final stream = _filter == DiaryFilter.week
        ? _service.watchWeekEntries(userId)
        : _service.watchMonthEntries(userId);
    _entriesSub = stream.listen((list) {
      _entries = list;
      notifyListeners();
    });
  }

  void _listenTemplates(String userId) {
    _templatesSub?.cancel();
    _templatesSub = _service.watchTemplates(userId).listen((list) {
      _templates = list;
      notifyListeners();
    });
  }

  Future<DiaryEntry?> createEntry({
    required String userId,
    required String title,
    required String content,
    required String mood,
    List<String> tags = const [],
    String? templateId,
    Map<String, dynamic> customFields = const {},
    DateTime? date,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final entry = await _service.createEntry(
        userId: userId,
        title: title,
        content: content,
        mood: mood,
        tags: tags,
        templateId: templateId,
        customFields: customFields,
        date: date,
      );
      return entry;
    } catch (e) {
      _error = 'No se pudo guardar la entrada.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEntry(String userId, String entryId) async {
    try {
      await _service.deleteEntry(userId, entryId);
    } catch (_) {
      _error = 'No se pudo eliminar la entrada.';
      notifyListeners();
    }
  }

  Future<DiaryTemplate?> createTemplate({
    required String userId,
    required String name,
    String? description,
    required List<TemplateField> fields,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      return await _service.createTemplate(
        userId: userId,
        name: name,
        description: description,
        fields: fields,
      );
    } catch (_) {
      _error = 'No se pudo crear la plantilla.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateEntry(String userId, DiaryEntry entry) async {
    _loading = true;
    notifyListeners();
    try {
      await _service.updateEntry(userId, entry);
    } catch (_) {
      _error = 'No se pudo actualizar la entrada.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteTemplate(String userId, String templateId) async {
    try {
      await _service.deleteTemplate(userId, templateId);
    } catch (_) {
      _error = 'No se pudo eliminar la plantilla.';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _entriesSub?.cancel();
    _entriesSub = null;
    _templatesSub?.cancel();
    _templatesSub = null;
    _entries = [];
    _templates = [];
    _filter = DiaryFilter.week;
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _entriesSub?.cancel();
    _templatesSub?.cancel();
    super.dispose();
  }
}
