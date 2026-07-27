/// Helpers de formato compartidos por el apartado Carrera.
library;

/// Duración en segundos → "hh:mm:ss" (u "mm:ss" si no llega a la hora).
String formatRunDuration(int seconds) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

/// Ritmo en segundos por km → "m:ss min/km"; null → "—".
String formatPace(int? secondsPerKm) {
  if (secondsPerKm == null) return '—';
  final m = secondsPerKm ~/ 60;
  final s = secondsPerKm % 60;
  return '$m:${s.toString().padLeft(2, '0')} min/km';
}

/// Distancia → "5.2 km" (sin decimales innecesarios).
String formatDistance(double km) {
  final rounded = km == km.roundToDouble()
      ? km.toInt().toString()
      : km.toStringAsFixed(2);
  return '$rounded km';
}

/// Icono sugerido por tipo de actividad (nombre → codePoint se resuelve en UI).
const runActivityPresets = ['Correr', 'Caminar', 'Trotar', 'Bici', 'Otro'];
