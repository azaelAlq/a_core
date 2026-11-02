import 'dart:async';
import 'package:flutter/material.dart';

import 'package:a_core/features/finanzas/data/services/finanzas_service.dart';
import 'package:a_core/features/finanzas/data/services/prestamos_widget_bridge.dart';
import 'package:a_core/features/finanzas/domain/entities/cuenta.dart';
import 'package:a_core/features/finanzas/domain/entities/movimiento.dart';
import 'package:a_core/features/finanzas/domain/entities/pago_prestamo.dart';
import 'package:a_core/features/finanzas/domain/entities/prestamo.dart';
import 'package:a_core/features/finanzas/domain/entities/uso_credito.dart';

class FinanzasProvider extends ChangeNotifier {
  final FinanzasService _service = FinanzasService();

  List<Cuenta> _cuentas = [];
  List<Prestamo> _prestamos = [];
  List<UsoCredito> _usosCredito = [];
  bool _loading = false;
  String? _error;

  // Movimientos y pagos se cargan bajo demanda por cuenta/prestamo
  final Map<String, List<Movimiento>> _movimientosPorCuenta = {};
  final Map<String, List<PagoPrestamo>> _pagosPorPrestamo = {};
  final Map<String, StreamSubscription> _movSubs = {};
  final Map<String, StreamSubscription> _pagoSubs = {};

  StreamSubscription? _cuentasSub;
  StreamSubscription? _prestamosSub;
  StreamSubscription? _usosSub;

  String? _uid;
  bool _sincronizandoWidget = false;

  List<Cuenta> get cuentas => _cuentas;
  List<Prestamo> get prestamos => _prestamos;
  List<UsoCredito> get usosCredito => _usosCredito;
  bool get loading => _loading;
  String? get error => _error;

  // Resumen financiero
  double get totalActivos =>
      _cuentas.where((c) => c.tipo != TipoCuenta.credito).fold(0, (s, c) => s + c.saldo);
  double get totalDeudaCredito =>
      _cuentas.where((c) => c.tipo == TipoCuenta.credito).fold(0, (s, c) => s + c.saldo);
  double get totalPorCobrar =>
      _prestamos
          .where((p) => p.estado == EstadoPrestamo.activo)
          .fold(0.0, (s, p) => s + p.saldoPendiente) +
      _usosCredito
          .where((u) => u.estado != EstadoUsoCredito.liquidado)
          .fold(0, (s, u) => s + u.saldoPendiente);

  List<Movimiento> movimientosDe(String cuentaId) => _movimientosPorCuenta[cuentaId] ?? [];
  List<PagoPrestamo> pagosDe(String prestamoId) => _pagosPorPrestamo[prestamoId] ?? [];

  // Préstamos activos (pendientes de cobro)
  List<Prestamo> get prestamosActivos =>
      _prestamos.where((p) => p.estado == EstadoPrestamo.activo).toList();
  List<UsoCredito> get usosActivos =>
      _usosCredito.where((u) => u.estado != EstadoUsoCredito.liquidado).toList();

  void init(String userId) {
    if (_uid == userId && _cuentasSub != null) {
      sincronizarPendientesDelWidget(userId);
      return;
    }
    _uid = userId;
    _cuentasSub?.cancel();
    _prestamosSub?.cancel();
    _usosSub?.cancel();

    _cuentasSub = _service.watchCuentas(userId).listen((list) {
      _cuentas = list;
      notifyListeners();
    });
    _prestamosSub = _service.watchPrestamos(userId).listen((list) {
      _prestamos = list;
      notifyListeners();
      _actualizarWidgetPrestamos();
    });
    _usosSub = _service.watchUsosCredito(userId).listen((list) {
      _usosCredito = list;
      notifyListeners();
    });
    sincronizarPendientesDelWidget(userId);
  }

  /// Refresca el resumen (por cobrar y activos) del widget de préstamos.
  void _actualizarWidgetPrestamos() {
    final activos = prestamosActivos;
    PrestamosWidgetBridge.actualizarResumen(
      porCobrar: activos.fold(0.0, (s, p) => s + p.saldoPendiente),
      activos: activos.length,
    );
  }

  /// Sube a Firestore los préstamos capturados desde el widget del inicio.
  Future<void> sincronizarPendientesDelWidget(String userId) async {
    if (_sincronizandoWidget) return;
    _sincronizandoWidget = true;
    try {
      final pendientes = await PrestamosWidgetBridge.leerPendientes();
      if (pendientes.isEmpty) return;
      for (final p in pendientes) {
        try {
          final monto = (p['monto'] as num?)?.toDouble() ?? 0;
          if (monto <= 0) continue;
          final contacto = (p['contacto'] as String?)?.trim();
          final concepto = (p['concepto'] as String?)?.trim();
          final vencMillis = (p['fechaVencimiento'] as num?)?.toInt();
          await _service.createPrestamo(
            userId: userId,
            deudor: (p['deudor'] ?? '').toString(),
            contacto: contacto == null || contacto.isEmpty ? null : contacto,
            monto: monto,
            fechaVencimiento: vencMillis != null
                ? DateTime.fromMillisecondsSinceEpoch(vencMillis)
                : null,
            concepto: concepto == null || concepto.isEmpty ? null : concepto,
          );
        } catch (_) {}
      }
      await PrestamosWidgetBridge.limpiarPendientes();
    } finally {
      _sincronizandoWidget = false;
    }
  }

  void watchMovimientos(String userId, String cuentaId) {
    if (_movSubs.containsKey(cuentaId)) return;
    _movSubs[cuentaId] = _service.watchMovimientos(userId, cuentaId).listen((list) {
      _movimientosPorCuenta[cuentaId] = list;
      notifyListeners();
    });
  }

  void watchPagosPrestamo(String userId, String prestamoId) {
    if (_pagoSubs.containsKey(prestamoId)) return;
    _pagoSubs[prestamoId] = _service.watchPagosPrestamo(userId, prestamoId).listen((list) {
      _pagosPorPrestamo[prestamoId] = list;
      notifyListeners();
    });
  }

  // ── Cuentas ───────────────────────────────────

  Future<void> createCuenta({
    required String userId,
    required String nombre,
    String? banco,
    required TipoCuenta tipo,
    required double saldo,
    double? limiteCredito,
    String? notas,
    required String color,
  }) async {
    _setLoading();
    try {
      await _service.createCuenta(
        userId: userId,
        nombre: nombre,
        banco: banco,
        tipo: tipo,
        saldo: saldo,
        limiteCredito: limiteCredito,
        notas: notas,
        color: color,
      );
    } catch (_) {
      _error = 'No se pudo crear la cuenta.';
    } finally {
      _doneLoading();
    }
  }

  Future<void> addMovimiento({
    required String userId,
    required String cuentaId,
    required TipoMovimiento tipo,
    required double monto,
    required String concepto,
    String? notas,
    DateTime? fecha,
  }) async {
    _setLoading();
    try {
      await _service.addMovimiento(
        userId: userId,
        cuentaId: cuentaId,
        tipo: tipo,
        monto: monto,
        concepto: concepto,
        notas: notas,
        fecha: fecha,
      );
    } catch (_) {
      _error = 'No se pudo registrar el movimiento.';
    } finally {
      _doneLoading();
    }
  }

  Future<void> deleteCuenta(String userId, String cuentaId) async {
    try {
      await _service.deleteCuenta(userId, cuentaId);
    } catch (_) {
      _error = 'No se pudo eliminar la cuenta.';
      notifyListeners();
    }
  }

  // ── Préstamos ─────────────────────────────────

  Future<void> createPrestamo({
    required String userId,
    required String deudor,
    String? contacto,
    required double monto,
    DateTime? fechaVencimiento,
    String? concepto,
  }) async {
    _setLoading();
    try {
      await _service.createPrestamo(
        userId: userId,
        deudor: deudor,
        contacto: contacto,
        monto: monto,
        fechaVencimiento: fechaVencimiento,
        concepto: concepto,
      );
    } catch (_) {
      _error = 'No se pudo crear el préstamo.';
    } finally {
      _doneLoading();
    }
  }

  Future<void> registrarPago({
    required String userId,
    required Prestamo prestamo,
    required double monto,
    String? notas,
  }) async {
    _setLoading();
    try {
      await _service.registrarPago(userId: userId, prestamo: prestamo, monto: monto, notas: notas);
    } catch (_) {
      _error = 'No se pudo registrar el pago.';
    } finally {
      _doneLoading();
    }
  }

  Future<void> deletePrestamo(String userId, String prestamoId) async {
    try {
      await _service.deletePrestamo(userId, prestamoId);
    } catch (_) {
      _error = 'No se pudo eliminar el préstamo.';
      notifyListeners();
    }
  }

  // ── Usos de crédito ───────────────────────────

  Future<void> createUsoCredito({
    required String userId,
    required String cuentaId,
    required String persona,
    required double montoTotal,
    int? mesesPago,
    required String concepto,
  }) async {
    _setLoading();
    try {
      await _service.createUsoCredito(
        userId: userId,
        cuentaId: cuentaId,
        persona: persona,
        montoTotal: montoTotal,
        mesesPago: mesesPago,
        concepto: concepto,
      );
    } catch (_) {
      _error = 'No se pudo registrar el uso.';
    } finally {
      _doneLoading();
    }
  }

  Future<void> registrarPagoCredito({
    required String userId,
    required UsoCredito uso,
    required double monto,
  }) async {
    _setLoading();
    try {
      await _service.registrarPagoCredito(userId: userId, uso: uso, monto: monto);
    } catch (_) {
      _error = 'No se pudo registrar el pago.';
    } finally {
      _doneLoading();
    }
  }

  Future<void> deleteUsoCredito(String userId, String usoId) async {
    try {
      await _service.deleteUsoCredito(userId, usoId);
    } catch (_) {
      _error = 'No se pudo eliminar.';
      notifyListeners();
    }
  }

  void _setLoading() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void _doneLoading() {
    _loading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _cuentasSub?.cancel();
    _cuentasSub = null;
    _prestamosSub?.cancel();
    _prestamosSub = null;
    _usosSub?.cancel();
    _usosSub = null;
    _uid = null;
    for (final s in _movSubs.values) s.cancel();
    _movSubs.clear();
    for (final s in _pagoSubs.values) s.cancel();
    _pagoSubs.clear();

    _cuentas = [];
    _prestamos = [];
    _usosCredito = [];
    _movimientosPorCuenta.clear();
    _pagosPorPrestamo.clear();
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cuentasSub?.cancel();
    _prestamosSub?.cancel();
    _usosSub?.cancel();
    for (final s in _movSubs.values) s.cancel();
    for (final s in _pagoSubs.values) s.cancel();
    super.dispose();
  }
}
