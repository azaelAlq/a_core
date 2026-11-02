import 'package:intl/intl.dart';

enum TipoPeriodo { semana, quincena, mes }

class Periodo {
  final TipoPeriodo tipo;
  final DateTime inicio;
  final DateTime fin;
  final String etiqueta;

  const Periodo._({
    required this.tipo,
    required this.inicio,
    required this.fin,
    required this.etiqueta,
  });

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  bool contiene(DateTime fecha) {
    final d = _dia(fecha);
    return !d.isBefore(_dia(inicio)) && !d.isAfter(_dia(fin));
  }

  Periodo siguiente() => calcular(tipo, fin.add(const Duration(days: 1)));

  Periodo anterior() => calcular(tipo, inicio.subtract(const Duration(days: 1)));

  static Periodo calcular(TipoPeriodo tipo, [DateTime? ancla]) {
    final a = ancla ?? DateTime.now();
    final base = DateTime(a.year, a.month, a.day);

    late final DateTime inicio;
    late final DateTime fin;
    switch (tipo) {
      case TipoPeriodo.semana:
        inicio = base.subtract(Duration(days: base.weekday - DateTime.monday));
        fin = inicio.add(const Duration(days: 6));
      case TipoPeriodo.quincena:
        if (base.day <= 15) {
          inicio = DateTime(base.year, base.month, 1);
          fin = DateTime(base.year, base.month, 15);
        } else {
          inicio = DateTime(base.year, base.month, 16);
          fin = DateTime(base.year, base.month + 1, 0);
        }
      case TipoPeriodo.mes:
        inicio = DateTime(base.year, base.month, 1);
        fin = DateTime(base.year, base.month + 1, 0);
    }

    return Periodo._(
      tipo: tipo,
      inicio: inicio,
      fin: fin,
      etiqueta: _etiqueta(tipo, inicio, fin),
    );
  }

  static String _etiqueta(TipoPeriodo tipo, DateTime inicio, DateTime fin) {
    switch (tipo) {
      case TipoPeriodo.semana:
        final corto = DateFormat('d MMM', 'es');
        if (inicio.month == fin.month) {
          return '${inicio.day} – ${corto.format(fin)}';
        }
        return '${corto.format(inicio)} – ${corto.format(fin)}';
      case TipoPeriodo.quincena:
        return '${inicio.day} – ${DateFormat('d MMM', 'es').format(fin)}';
      case TipoPeriodo.mes:
        return DateFormat('MMMM yyyy', 'es').format(inicio);
    }
  }
}
