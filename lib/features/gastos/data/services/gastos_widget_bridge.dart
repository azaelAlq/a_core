import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Puente entre la app y el widget nativo de Android.
///
/// El widget escribe los registros pendientes en las SharedPreferences que
/// usa el paquete `home_widget` (archivo `HomeWidgetPreferences`) y este
/// puente los lee para subirlos a Firestore. En sentido inverso, la app
/// guarda aquí el resumen de la semana para que el widget lo muestre.
abstract class GastosWidgetBridge {
  static const _pendingKey = 'gastos_pending';
  static const _resumenKey = 'gastos_resumen';
  static const _providerCalificado =
      'com.example.a_core.gastos.GastosWidgetProvider';

  static bool get _activo => defaultTargetPlatform == TargetPlatform.android;

  /// Registros capturados desde el widget que aún no se suben a Firestore.
  static Future<List<Map<String, dynamic>>> leerPendientes() async {
    if (!_activo) return [];
    try {
      final raw = await HomeWidget.getWidgetData<String>(_pendingKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> limpiarPendientes() async {
    if (!_activo) return;
    try {
      await HomeWidget.saveWidgetData<String>(_pendingKey, null);
    } catch (_) {}
  }

  /// Actualiza el resumen semanal que muestra el widget en el inicio.
  static Future<void> actualizarResumen({
    required double ingresos,
    required double gastos,
  }) async {
    if (!_activo) return;
    try {
      await HomeWidget.saveWidgetData<String>(
        _resumenKey,
        jsonEncode({
          'ingresos': ingresos,
          'gastos': gastos,
          'balance': ingresos - gastos,
        }),
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _providerCalificado,
      );
    } catch (_) {}
  }
}
