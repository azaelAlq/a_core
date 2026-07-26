import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/system_log.dart';

class SystemLogModel extends SystemLog {
  const SystemLogModel({
    required super.id,
    required super.systemId,
    required super.userId,
    required super.date,
    required super.done,
    super.note,
    required super.createdAt,
  });

  factory SystemLogModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SystemLogModel(
      id: doc.id,
      systemId: d['systemId'] as String,
      userId: d['userId'] as String,
      date: (d['date'] as Timestamp).toDate(),
      done: d['done'] as bool? ?? false,
      note: d['note'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'systemId': systemId,
    'userId': userId,
    'date': Timestamp.fromDate(date),
    'done': done,
    'note': note,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
