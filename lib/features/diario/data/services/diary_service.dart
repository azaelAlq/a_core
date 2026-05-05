import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:a_core/features/diario/data/models/diary_entry_model.dart';
import 'package:a_core/features/diario/data/models/diary_template_model.dart';
import 'package:a_core/features/diario/domain/entities/diary_entry.dart';
import 'package:a_core/features/diario/domain/entities/diary_template.dart';

class DiaryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── Colecciones ──────────────────────────────
  CollectionReference _entries(String uid) =>
      _db.collection('users').doc(uid).collection('diary_entries');

  CollectionReference _templates(String uid) =>
      _db.collection('users').doc(uid).collection('diary_templates');

  // ── Entries ───────────────────────────────────

  Future<DiaryEntry> createEntry({
    required String userId,
    required String title,
    required String content,
    required String mood,
    List<String> tags = const [],
    String? templateId,
    Map<String, dynamic> customFields = const {},
    DateTime? date,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final entry = DiaryEntryModel(
      id: id,
      userId: userId,
      title: title,
      content: content,
      mood: mood,
      tags: tags,
      templateId: templateId,
      customFields: customFields,
      date: date ?? now,
      createdAt: now,
      updatedAt: now,
    );
    await _entries(userId).doc(id).set(entry.toFirestore());
    return entry;
  }

  Future<void> updateEntry(String userId, DiaryEntry entry) async {
    final model = DiaryEntryModel.fromEntity(entry);
    await _entries(userId).doc(entry.id).update(model.toFirestore());
  }

  Future<void> deleteEntry(String userId, String entryId) async {
    await _entries(userId).doc(entryId).delete();
  }

  /// Entradas de la semana actual
  Stream<List<DiaryEntry>> watchWeekEntries(String userId) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 7));
    return _queryEntries(userId, start, end);
  }

  /// Entradas del mes actual
  Stream<List<DiaryEntry>> watchMonthEntries(String userId) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    return _queryEntries(userId, start, end);
  }

  Stream<List<DiaryEntry>> _queryEntries(String userId, DateTime start, DateTime end) {
    return _entries(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => DiaryEntryModel.fromFirestore(d)).toList());
  }

  // ── Templates ─────────────────────────────────

  Future<DiaryTemplate> createTemplate({
    required String userId,
    required String name,
    String? description,
    required List<TemplateField> fields,
  }) async {
    final id = _uuid.v4();
    final template = DiaryTemplateModel(
      id: id,
      userId: userId,
      name: name,
      description: description,
      fields: fields,
      createdAt: DateTime.now(),
    );
    await _templates(userId).doc(id).set(template.toFirestore());
    return template;
  }

  Future<void> deleteTemplate(String userId, String templateId) async {
    await _templates(userId).doc(templateId).delete();
  }

  Stream<List<DiaryTemplate>> watchTemplates(String userId) {
    return _templates(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => DiaryTemplateModel.fromFirestore(d)).toList());
  }
}
