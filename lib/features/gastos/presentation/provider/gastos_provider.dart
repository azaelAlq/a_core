import 'dart:async';
import 'package:flutter/material.dart';

import 'package:a_core/features/gastos/data/services/gastos_service.dart';
import 'package:a_core/features/gastos/data/services/gastos_widget_bridge.dart';
import 'package:a_core/features/gastos/domain/entities/registro.dart';
import 'package:a_core/features/gastos/domain/periodo.dart';

class GastosProvider extends ChangeNotifier {
  final GastosService _service = GastosService();

  List<Registro> _registros = [];
  bool _loading = false;
  String? _error;
  String? _uidInicializado;

  StreamSubscription? _registrosSub;
  bool _sincronizando = false;

  List<Registro> get registros => _registros;
  bool get loading => _loading;
  String? get error => _error;

  /// Registros dentro de un periodo (semana, quincena o mes).
  List<Registro> registrosDe(Periodo periodo) =>
      _registros.where((r) => periodo.contiene(r.fecha)).toList();

  double totalIngresos(List<Registro> lista) => lista
      .where((r) => r.tipo == TipoRegistro.ingreso)
      .fold(0.0, (s, r) => s + r.cantidad);

  double totalGastos(List<Registro> lista) => lista
      .where((r) => r.tipo == TipoRegistro.gasto)
      .fold(0.0, (s, r) => s + r.cantidad);

  void init(String userId) {
    if (_uidInicializado == userId && _registrosSub != null) {
      sincronizarPendientesDelWidget(userId);
      return;
    }
    _uidInicializado = userId;
    _registrosSub?.cancel();
    _registrosSub = _service.watchRegistros(userId).listen((list) {
      _registros = list;
      notifyListeners();
      _actualizarWidget();
    });
    sincronizarPendientesDelWidget(userId);
  }

  Future<void> addRegistro({
    required String userId,
    required String nombre,
    required double cantidad,
    required TipoRegistro tipo,
    DateTime? fecha,
  }) async {
    _setLoading();
    try {
      await _service.addRegistro(
        userId: userId,
        nombre: nombre,
        cantidad: cantidad,
        tipo: tipo,
        fecha: fecha,
      );
    } catch (_) {
      _error = 'No se pudo registrar.';
    } finally {
      _doneLoading();
    }
  }

  Future<void> deleteRegistro(String userId, String registroId) async {
    try {
      await _service.deleteRegistro(userId, registroId);
    } catch (_) {
      _error = 'No se pudo eliminar.';
      notifyListeners();
    }
  }

  /// Sube a Firestore los registros capturados desde el widget del inicio.
  /// El widget los guarda localmente (sin red) y esta app los sincroniza
  /// al abrirse, conservando la fecha y hora en que se capturaron.
  Future<void> sincronizarPendientesDelWidget(String userId) async {
    if (_sincronizando) return;
    _sincronizando = true;
    try {
      final pendientes = await GastosWidgetBridge.leerPendientes();
      if (pendientes.isEmpty) return;
      for (final p in pendientes) {
        try {
          final cantidad = (p['cantidad'] as num?)?.toDouble() ?? 0;
          if (cantidad <= 0) continue;
          await _service.addRegistro(
            userId: userId,
            nombre: (p['nombre'] ?? '').toString(),
            cantidad: cantidad,
            tipo: p['tipo'] == TipoRegistro.ingreso.name
                ? TipoRegistro.ingreso
                : TipoRegistro.gasto,
            fecha: DateTime.fromMillisecondsSinceEpoch(
              (p['fecha'] as num?)?.toInt() ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
          );
        } catch (_) {}
      }
      await GastosWidgetBridge.limpiarPendientes();
    } finally {
      _sincronizando = false;
    }
  }

  /// Refresca el resumen semanal que muestra el widget de inicio.
  void _actualizarWidget() {
    final semana = Periodo.calcular(TipoPeriodo.semana);
    final deSemana = registrosDe(semana);
    GastosWidgetBridge.actualizarResumen(
      ingresos: totalIngresos(deSemana),
      gastos: totalGastos(deSemana),
    );
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
    _registrosSub?.cancel();
    _registrosSub = null;
    _uidInicializado = null;
    _registros = [];
    _loading = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _registrosSub?.cancel();
    super.dispose();
  }
}
