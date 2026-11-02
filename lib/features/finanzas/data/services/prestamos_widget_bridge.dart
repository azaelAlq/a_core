import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Puente entre Finanzas y el widget nativo de préstamos de Android.
///
/// El widget encola los préstamos capturados en las SharedPreferences que usa
/// el paquete `home_widget` y este puente los lee para subirlos a Firestore.
/// En sentido inverso, la app guarda aquí el resumen (por cobrar y activos)
/// para que el widget lo muestre en el inicio.
abstract class PrestamosWidgetBridge {
  static const _resumenKey = 'prestamos_resumen';
  static const _pendingKey = 'prestamos_pending';
  static const _providerCalificado =
      'com.example.a_core.prestamos.PrestamosWidgetProvider';

  static bool get _activo => defaultTargetPlatform == TargetPlatform.android;

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

  static Future<void> actualizarResumen({
    required double porCobrar,
    required int activos,
  }) async {
    if (!_activo) return;
    try {
      await HomeWidget.saveWidgetData<String>(
        _resumenKey,
        jsonEncode({'porCobrar': porCobrar, 'activos': activos}),
      );
      await HomeWidget.updateWidget(
        qualifiedAndroidName: _providerCalificado,
      );
    } catch (_) {}
  }
}
