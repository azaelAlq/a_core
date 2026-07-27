import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/gym_session.dart';
import '../../domain/entities/routine.dart';
import '../../domain/entities/run_activity.dart';
import '../../domain/entities/training_note.dart';
import '../models/gym_routine_model.dart';
import '../models/gym_session_model.dart';
import '../models/run_activity_model.dart';
import '../models/training_note_model.dart';

class GymService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference _routines(String uid) =>
      _db.collection('users').doc(uid).collection('gym_routines');

  CollectionReference _sessions(String uid) =>
      _db.collection('users').doc(uid).collection('gym_sessions');

  CollectionReference _runs(String uid) =>
      _db.collection('users').doc(uid).collection('gym_runs');

  CollectionReference _notes(String uid) =>
      _db.collection('users').doc(uid).collection('gym_notes');

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

  // ── Carrera: actividades ──────────────────

  Stream<List<RunActivity>> watchRuns(String uid) {
    return _runs(uid).snapshots().map((s) {
      final list = s.docs
          .map<RunActivity>((d) => RunActivityModel.fromFirestore(d))
          .toList();
      list.sort((a, b) => b.performedAt.compareTo(a.performedAt));
      return list;
    });
  }

  Future<RunActivity> createRun(String uid, RunActivity run) async {
    final id = run.id.isEmpty ? _uuid.v4() : run.id;
    final model = RunActivityModel(
      id: id,
      userId: uid,
      performedAt: run.performedAt,
      activity: run.activity,
      distanceKm: run.distanceKm,
      durationSeconds: run.durationSeconds,
      steps: run.steps,
      activeCalories: run.activeCalories,
      totalCalories: run.totalCalories,
      avgHr: run.avgHr,
      maxHr: run.maxHr,
      perceivedFatigue: run.perceivedFatigue,
      notes: run.notes,
      createdAt: run.createdAt,
    );
    await _runs(uid).doc(id).set(model.toFirestore());
    return model;
  }

  Future<void> updateRun(String uid, RunActivity run) async {
    await _runs(
      uid,
    ).doc(run.id).set(RunActivityModel.fromEntity(run).toFirestore());
  }

  Future<void> deleteRun(String uid, String runId) async {
    await _runs(uid).doc(runId).delete();
  }

  // ── Carrera: notas ────────────────────────

  Stream<List<TrainingNote>> watchNotes(String uid) {
    return _notes(uid).snapshots().map((s) {
      final list = s.docs
          .map<TrainingNote>((d) => TrainingNoteModel.fromFirestore(d))
          .toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<TrainingNote> createNote(String uid, TrainingNote note) async {
    final id = note.id.isEmpty ? _uuid.v4() : note.id;
    final model = TrainingNoteModel(
      id: id,
      userId: uid,
      date: note.date,
      fatigue: note.fatigue,
      text: note.text,
      createdAt: note.createdAt,
    );
    await _notes(uid).doc(id).set(model.toFirestore());
    return model;
  }

  Future<void> updateNote(String uid, TrainingNote note) async {
    await _notes(
      uid,
    ).doc(note.id).set(TrainingNoteModel.fromEntity(note).toFirestore());
  }

  Future<void> deleteNote(String uid, String noteId) async {
    await _notes(uid).doc(noteId).delete();
  }
}
