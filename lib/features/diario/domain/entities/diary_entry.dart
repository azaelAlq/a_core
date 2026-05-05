class DiaryEntry {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String mood; // emoji o label: 'great','good','neutral','bad','awful'
  final List<String> tags;
  final String? templateId; // null si no usó plantilla
  final Map<String, dynamic> customFields; // campos de la plantilla
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiaryEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.mood,
    this.tags = const [],
    this.templateId,
    this.customFields = const {},
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  DiaryEntry copyWith({
    String? title,
    String? content,
    String? mood,
    List<String>? tags,
    String? templateId,
    Map<String, dynamic>? customFields,
    DateTime? date,
  }) {
    return DiaryEntry(
      id: id,
      userId: userId,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      templateId: templateId ?? this.templateId,
      customFields: customFields ?? this.customFields,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
