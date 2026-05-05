import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:a_core/features/diario/domain/entities/diary_template.dart';

class DiaryTemplateModel extends DiaryTemplate {
  const DiaryTemplateModel({
    required super.id,
    required super.userId,
    required super.name,
    super.description,
    required super.fields,
    required super.createdAt,
  });

  factory DiaryTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawFields = List<Map<String, dynamic>>.from(d['fields'] ?? []);
    return DiaryTemplateModel(
      id: doc.id,
      userId: d['userId'] as String,
      name: d['name'] as String,
      description: d['description'] as String?,
      fields: rawFields
          .map(
            (f) => TemplateField(
              id: f['id'] as String,
              label: f['label'] as String,
              type: FieldType.values.firstWhere(
                (t) => t.name == f['type'],
                orElse: () => FieldType.text,
              ),
              required: f['required'] as bool? ?? false,
            ),
          )
          .toList(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  factory DiaryTemplateModel.fromEntity(DiaryTemplate t) => DiaryTemplateModel(
    id: t.id,
    userId: t.userId,
    name: t.name,
    description: t.description,
    fields: t.fields,
    createdAt: t.createdAt,
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'name': name,
    'description': description,
    'fields': fields
        .map((f) => {'id': f.id, 'label': f.label, 'type': f.type.name, 'required': f.required})
        .toList(),
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
