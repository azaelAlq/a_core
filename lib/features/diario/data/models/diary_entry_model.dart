import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:a_core/features/diario/domain/entities/diary_entry.dart';

class DiaryEntryModel extends DiaryEntry {
  const DiaryEntryModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.content,
    required super.mood,
    super.tags,
    super.templateId,
    super.customFields,
    required super.date,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DiaryEntryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DiaryEntryModel(
      id: doc.id,
      userId: d['userId'] as String,
      title: d['title'] as String,
      content: d['content'] as String,
      mood: d['mood'] as String? ?? 'neutral',
      tags: List<String>.from(d['tags'] ?? []),
      templateId: d['templateId'] as String?,
      customFields: Map<String, dynamic>.from(d['customFields'] ?? {}),
      date: (d['date'] as Timestamp).toDate(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory DiaryEntryModel.fromEntity(DiaryEntry e) => DiaryEntryModel(
    id: e.id,
    userId: e.userId,
    title: e.title,
    content: e.content,
    mood: e.mood,
    tags: e.tags,
    templateId: e.templateId,
    customFields: e.customFields,
    date: e.date,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'title': title,
    'content': content,
    'mood': mood,
    'tags': tags,
    'templateId': templateId,
    'customFields': customFields,
    'date': Timestamp.fromDate(date),
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}
