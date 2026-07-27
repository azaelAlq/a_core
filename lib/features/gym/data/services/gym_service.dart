import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/gym_session.dart';
import '../../domain/entities/routine.dart';
import '../models/gym_routine_model.dart';
import '../models/gym_session_model.dart';

class GymService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference _routines(String uid) =>
      _db.collection('users').doc(uid).collection('gym_routines');

  CollectionReference _sessions(String uid) =>
      _db.collection('users').doc(uid).collection('gym_sessions');

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

  // ── Sesiones ──────────────────────────────

  Future<GymSession> startSession(String uid, Routine routine) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final session = GymSessionModel(
      id: id,
      userId: uid,
      routineId: routine.id,
      routineName: routine.name,
      routineEmoji: routine.emoji,
      startedAt: now,
      createdAt: now,
    );
    await _sessions(uid).doc(id).set(session.toFirestore());
    return session;
  }

  Future<void> finishSession(
    String uid,
    GymSession session,
    Routine routine,
  ) async {
    final now = DateTime.now();
    final updated = session.copyWith(
      finishedAt: now,
      durationSeconds: now.difference(session.startedAt).inSeconds,
      blocksSnapshot: routine.blocks,
    );
    await _sessions(
      uid,
    ).doc(session.id).set(GymSessionModel.fromEntity(updated).toFirestore());
  }

  Stream<List<GymSession>> watchSessions(String uid) {
    return _sessions(uid).snapshots().map((s) {
      final list = s.docs
          .map<GymSession>((d) => GymSessionModel.fromFirestore(d))
          .toList();
      list.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return list;
    });
  }

  Future<void> deleteSession(String uid, String sessionId) async {
    await _sessions(uid).doc(sessionId).delete();
  }
}
