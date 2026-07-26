import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/system.dart';
import '../../domain/entities/system_log.dart';
import '../models/system_log_model.dart';
import '../models/system_model.dart';

class SistemasService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference _systems(String uid) =>
      _db.collection('users').doc(uid).collection('systems');

  CollectionReference _logs(String uid) =>
      _db.collection('users').doc(uid).collection('system_logs');

  static DateTime mondayOf(DateTime d) {
    final x = DateTime(d.year, d.month, d.day);
    return x.subtract(Duration(days: x.weekday - 1));
  }

  // ── Systems CRUD ──────────────────────────────

  Future<System> createSystem({
    required String userId,
    required String name,
    String? identity,
    String? cue,
    String? craving,
    required String action,
    String? reward,
    required String emoji,
    required List<int> targetDays,
  }) async {
    final id = _uuid.v4();
    final system = SystemModel(
      id: id,
      userId: userId,
      name: name,
      identity: identity,
      cue: cue,
      craving: craving,
      action: action,
      reward: reward,
      emoji: emoji,
      targetDays: targetDays,
      createdAt: DateTime.now(),
    );
    await _systems(userId).doc(id).set(system.toFirestore());
    return system;
  }

  Future<void> updateSystem(String userId, System s) async {
    await _systems(userId).doc(s.id).set(SystemModel.fromEntity(s).toFirestore());
  }

  Future<void> deleteSystem(String userId, String systemId) async {
    // Borra el sistema y todos sus registros
    final logsSnap = await _logs(userId).where('systemId', isEqualTo: systemId).get();
    final batch = _db.batch();
    for (final doc in logsSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_systems(userId).doc(systemId));
    await batch.commit();
  }

  Stream<List<System>> watchSystems(String userId) {
    return _systems(userId).where('isArchived', isEqualTo: false).snapshots().map((s) {
      final list = s.docs.map<System>((d) => SystemModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  // ── Logs ──────────────────────────────────────

  /// Marca o desmarca un día (toggle) y recalcula la racha
  Future<void> toggleDay({
    required String userId,
    required System system,
    required DateTime date,
  }) async {
    final d = DateTime(date.year, date.month, date.day);
    final id = SystemLog.keyFor(system.id, d);
    final ref = _logs(userId).doc(id);

    final snap = await ref.get();
    final currentlyDone = snap.exists
        ? ((snap.data() as Map<String, dynamic>)['done'] as bool? ?? false)
        : false;

    final log = SystemLogModel(
      id: id,
      systemId: system.id,
      userId: userId,
      date: d,
      done: !currentlyDone,
      createdAt: DateTime.now(),
    );
    await ref.set(log.toFirestore());

    await _recomputeStreak(userId, system);
  }

  /// Registros de la semana (para el seguimiento semanal)
  Stream<List<SystemLog>> watchWeekLogs(String userId, DateTime weekStart) {
    final start = mondayOf(weekStart);
    final end = start.add(const Duration(days: 7));
    return _logs(userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((s) => s.docs.map<SystemLog>((d) => SystemLogModel.fromFirestore(d)).toList());
  }

  /// Historial completo de un sistema (para el detalle)
  Stream<List<SystemLog>> watchSystemLogs(String userId, String systemId) {
    return _logs(userId).where('systemId', isEqualTo: systemId).snapshots().map((s) {
      final list = s.docs.map<SystemLog>((d) => SystemLogModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  // ── Racha ─────────────────────────────────────

  Future<void> _recomputeStreak(String userId, System system) async {
    final snap = await _logs(userId).where('systemId', isEqualTo: system.id).get();

    final done = <DateTime>{};
    for (final doc in snap.docs) {
      final m = doc.data() as Map<String, dynamic>;
      if (m['done'] == true) {
        final dt = (m['date'] as Timestamp).toDate();
        done.add(DateTime(dt.year, dt.month, dt.day));
      }
    }

    final target = system.targetDays;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(days: 400));

    // Racha actual: hacia atrás desde hoy sobre días objetivo (hoy tiene gracia)
    int current = 0;
    var cursor = today;
    while (cursor.isAfter(windowStart)) {
      if (target.contains(cursor.weekday)) {
        if (done.contains(cursor)) {
          current++;
        } else if (cursor == today) {
          // hoy aún no marcado: no rompe la racha
        } else {
          break;
        }
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // Racha más larga en la ventana
    int longest = 0;
    int run = 0;
    var c = windowStart;
    while (!c.isAfter(today)) {
      if (target.contains(c.weekday)) {
        if (done.contains(c)) {
          run++;
          if (run > longest) longest = run;
        } else if (c == today) {
          // gracia
        } else {
          run = 0;
        }
      }
      c = c.add(const Duration(days: 1));
    }
    if (current > longest) longest = current;

    await _systems(
      userId,
    ).doc(system.id).update({'currentStreak': current, 'longestStreak': longest});
  }
}
