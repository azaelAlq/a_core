import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/routine.dart';
import '../models/gym_routine_model.dart';

class GymService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference _routines(String uid) =>
      _db.collection('users').doc(uid).collection('gym_routines');

  Stream<List<Routine>> watchRoutines(String uid) {
    return _routines(uid).where('isArchived', isEqualTo: false).snapshots().map(
      (s) {
        final list = s.docs
            .map<Routine>((d) => GymRoutineModel.fromFirestore(d))
            .toList();
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return list;
      },
    );
  }

  Future<Routine> createRoutine(String uid, {required String name}) async {
    final id = _uuid.v4();
    final routine = GymRoutineModel(
      id: id,
      userId: uid,
      name: name,
      createdAt: DateTime.now(),
    );
    await _routines(uid).doc(id).set(routine.toFirestore());
    return routine;
  }

  Future<void> updateRoutine(String uid, Routine routine) async {
    await _routines(
      uid,
    ).doc(routine.id).set(GymRoutineModel.fromEntity(routine).toFirestore());
  }

  Future<void> deleteRoutine(String uid, String routineId) async {
    await _routines(uid).doc(routineId).delete();
  }
}
