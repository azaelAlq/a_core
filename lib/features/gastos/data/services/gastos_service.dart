import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:a_core/features/gastos/data/models/registro_model.dart';
import 'package:a_core/features/gastos/domain/entities/registro.dart';

class GastosService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference _registros(String uid) =>
      _db.collection('users').doc(uid).collection('registros_gastos');

  Future<Registro> addRegistro({
    required String userId,
    required String nombre,
    required double cantidad,
    required TipoRegistro tipo,
    DateTime? fecha,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final registro = RegistroModel(
      id: id,
      userId: userId,
      nombre: nombre,
      cantidad: cantidad,
      tipo: tipo,
      fecha: fecha ?? now,
      createdAt: now,
    );
    await _registros(userId).doc(id).set(registro.toFirestore());
    return registro;
  }

  Future<void> deleteRegistro(String userId, String registroId) =>
      _registros(userId).doc(registroId).delete();

  Stream<List<Registro>> watchRegistros(String userId) {
    return _registros(userId).snapshots().map((s) {
      final list = s.docs.map((d) => RegistroModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.fecha.compareTo(a.fecha));
      return list;
    });
  }
}
