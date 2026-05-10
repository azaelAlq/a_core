import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'package:a_core/features/finanzas/data/models/cuenta_model.dart';
import 'package:a_core/features/finanzas/data/models/movimiento_model.dart';
import 'package:a_core/features/finanzas/data/models/pago_prestamo_model.dart';
import 'package:a_core/features/finanzas/data/models/prestamo_model.dart';
import 'package:a_core/features/finanzas/data/models/uso_credito_model.dart';
import 'package:a_core/features/finanzas/domain/entities/cuenta.dart';
import 'package:a_core/features/finanzas/domain/entities/movimiento.dart';
import 'package:a_core/features/finanzas/domain/entities/pago_prestamo.dart';
import 'package:a_core/features/finanzas/domain/entities/prestamo.dart';
import 'package:a_core/features/finanzas/domain/entities/uso_credito.dart';

class FinanzasService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ── Colecciones ───────────────────────────────
  CollectionReference _cuentas(String uid) =>
      _db.collection('users').doc(uid).collection('cuentas');
  CollectionReference _movimientos(String uid) =>
      _db.collection('users').doc(uid).collection('movimientos');
  CollectionReference _prestamos(String uid) =>
      _db.collection('users').doc(uid).collection('prestamos');
  CollectionReference _pagosPrestamo(String uid) =>
      _db.collection('users').doc(uid).collection('pagos_prestamo');
  CollectionReference _usosCredito(String uid) =>
      _db.collection('users').doc(uid).collection('usos_credito');

  // ── Cuentas ───────────────────────────────────

  Future<Cuenta> createCuenta({
    required String userId,
    required String nombre,
    String? banco,
    required TipoCuenta tipo,
    required double saldo,
    double? limiteCredito,
    String? notas,
    required String color,
  }) async {
    final id = _uuid.v4();
    final cuenta = CuentaModel(
      id: id,
      userId: userId,
      nombre: nombre,
      banco: banco,
      tipo: tipo,
      saldo: saldo,
      limiteCredito: limiteCredito,
      notas: notas,
      color: color,
      createdAt: DateTime.now(),
    );
    await _cuentas(userId).doc(id).set(cuenta.toFirestore());
    return cuenta;
  }

  Future<void> deleteCuenta(String userId, String cuentaId) =>
      _cuentas(userId).doc(cuentaId).delete();

  Stream<List<Cuenta>> watchCuentas(String userId) {
    return _cuentas(userId).snapshots().map((s) {
      final list = s.docs.map((d) => CuentaModel.fromFirestore(d)).toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  // ── Movimientos ───────────────────────────────

  Future<Movimiento> addMovimiento({
    required String userId,
    required String cuentaId,
    required TipoMovimiento tipo,
    required double monto,
    required String concepto,
    String? notas,
    DateTime? fecha,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final mov = MovimientoModel(
      id: id,
      cuentaId: cuentaId,
      userId: userId,
      tipo: tipo,
      monto: monto,
      concepto: concepto,
      notas: notas,
      fecha: fecha ?? now,
      createdAt: now,
    );
    final batch = _db.batch();
    batch.set(_movimientos(userId).doc(id), mov.toFirestore());
    // Actualiza saldo de la cuenta
    final delta = tipo == TipoMovimiento.ingreso ? monto : -monto;
    batch.update(_cuentas(userId).doc(cuentaId), {'saldo': FieldValue.increment(delta)});
    await batch.commit();
    return mov;
  }

  Stream<List<Movimiento>> watchMovimientos(String userId, String cuentaId) {
    return _movimientos(userId).where('cuentaId', isEqualTo: cuentaId).snapshots().map((s) {
      final list = s.docs.map((d) => MovimientoModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.fecha.compareTo(a.fecha));
      return list;
    });
  }

  // ── Préstamos ─────────────────────────────────

  Future<Prestamo> createPrestamo({
    required String userId,
    required String deudor,
    String? contacto,
    required double monto,
    DateTime? fechaVencimiento,
    String? concepto,
  }) async {
    final id = _uuid.v4();
    final prestamo = PrestamoModel(
      id: id,
      userId: userId,
      deudor: deudor,
      contacto: contacto,
      montoOriginal: monto,
      montoPagado: 0,
      fechaPrestamo: DateTime.now(),
      fechaVencimiento: fechaVencimiento,
      concepto: concepto,
      estado: EstadoPrestamo.activo,
      createdAt: DateTime.now(),
    );
    await _prestamos(userId).doc(id).set(prestamo.toFirestore());
    return prestamo;
  }

  Future<PagoPrestamo> registrarPago({
    required String userId,
    required Prestamo prestamo,
    required double monto,
    String? notas,
    DateTime? fecha,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final pago = PagoPrestamoModel(
      id: id,
      prestamoId: prestamo.id,
      userId: userId,
      monto: monto,
      fecha: fecha ?? now,
      notas: notas,
      createdAt: now,
    );
    final nuevoPagado = prestamo.montoPagado + monto;
    final liquidado = nuevoPagado >= prestamo.montoOriginal;

    final batch = _db.batch();
    batch.set(_pagosPrestamo(userId).doc(id), pago.toFirestore());
    batch.update(_prestamos(userId).doc(prestamo.id), {
      'montoPagado': nuevoPagado,
      'estado': liquidado ? EstadoPrestamo.liquidado.name : EstadoPrestamo.activo.name,
    });
    await batch.commit();
    return pago;
  }

  Future<void> deletePrestamo(String userId, String prestamoId) =>
      _prestamos(userId).doc(prestamoId).delete();

  Stream<List<Prestamo>> watchPrestamos(String userId) {
    return _prestamos(userId).snapshots().map((s) {
      final list = s.docs.map((d) => PrestamoModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.fechaPrestamo.compareTo(a.fechaPrestamo));
      return list;
    });
  }

  Stream<List<PagoPrestamo>> watchPagosPrestamo(String userId, String prestamoId) {
    return _pagosPrestamo(userId).where('prestamoId', isEqualTo: prestamoId).snapshots().map((s) {
      final list = s.docs.map((d) => PagoPrestamoModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.fecha.compareTo(a.fecha));
      return list;
    });
  }

  // ── Usos de crédito ───────────────────────────

  Future<UsoCredito> createUsoCredito({
    required String userId,
    required String cuentaId,
    required String persona,
    required double montoTotal,
    int? mesesPago,
    required String concepto,
    DateTime? fecha,
  }) async {
    final id = _uuid.v4();
    final pagoMensual = mesesPago != null && mesesPago > 0 ? montoTotal / mesesPago : null;
    final uso = UsoCreditoModel(
      id: id,
      userId: userId,
      cuentaId: cuentaId,
      persona: persona,
      montoTotal: montoTotal,
      montoPagado: 0,
      mesesPago: mesesPago,
      pagoMensual: pagoMensual,
      concepto: concepto,
      fecha: fecha ?? DateTime.now(),
      estado: EstadoUsoCredito.pendiente,
      createdAt: DateTime.now(),
    );
    await _usosCredito(userId).doc(id).set(uso.toFirestore());
    return uso;
  }

  Future<void> registrarPagoCredito({
    required String userId,
    required UsoCredito uso,
    required double monto,
  }) async {
    final nuevoPagado = uso.montoPagado + monto;
    final liquidado = nuevoPagado >= uso.montoTotal;
    await _usosCredito(userId).doc(uso.id).update({
      'montoPagado': nuevoPagado,
      'estado': liquidado ? EstadoUsoCredito.liquidado.name : EstadoUsoCredito.pagandose.name,
    });
  }

  Future<void> deleteUsoCredito(String userId, String usoId) =>
      _usosCredito(userId).doc(usoId).delete();

  Stream<List<UsoCredito>> watchUsosCredito(String userId) {
    return _usosCredito(userId).snapshots().map((s) {
      final list = s.docs.map((d) => UsoCreditoModel.fromFirestore(d)).toList();
      list.sort((a, b) => b.fecha.compareTo(a.fecha));
      return list;
    });
  }
}
