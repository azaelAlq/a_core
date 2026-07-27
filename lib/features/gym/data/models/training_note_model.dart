import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/training_note.dart';

class TrainingNoteModel extends TrainingNote {
  const TrainingNoteModel({
    required super.id,
    required super.userId,
    required super.date,
    super.fatigue,
    required super.text,
    required super.createdAt,
  });

  factory TrainingNoteModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return TrainingNoteModel(
      id: doc.id,
      userId: d['userId'] as String,
      date: (d['date'] as Timestamp).toDate(),
      fatigue: (d['fatigue'] as num?)?.toInt(),
      text: d['text'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  factory TrainingNoteModel.fromEntity(TrainingNote n) => TrainingNoteModel(
    id: n.id,
    userId: n.userId,
    date: n.date,
    fatigue: n.fatigue,
    text: n.text,
    createdAt: n.createdAt,
  );

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'date': Timestamp.fromDate(date),
    'fatigue': fatigue,
    'text': text,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
