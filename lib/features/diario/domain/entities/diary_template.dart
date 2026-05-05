// Tipos de campo que puede tener una plantilla
enum FieldType { text, longText, number, yesNo, rating, time }

class TemplateField {
  final String id;
  final String label;
  final FieldType type;
  final bool required;

  const TemplateField({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
  });
}

class DiaryTemplate {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final List<TemplateField> fields;
  final DateTime createdAt;

  const DiaryTemplate({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.fields,
    required this.createdAt,
  });
}
