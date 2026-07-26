/// Una fila de la tabla de un ejercicio (reps y peso de una serie).
class SetEntry {
  final int? reps;
  final double? weight;

  const SetEntry({this.reps, this.weight});
}

class Exercise {
  final String id;
  final String name;

  /// Marcado como completado dentro de la rutina
  final bool done;

  /// true = "peso por lado", false = "peso completo"
  final bool perSide;

  final String? notes;

  /// Una fila por serie del bloque (sets.length == block.series)
  final List<SetEntry> sets;

  const Exercise({
    required this.id,
    required this.name,
    this.done = false,
    this.perSide = false,
    this.notes,
    this.sets = const [],
  });

  Exercise copyWith({
    String? name,
    bool? done,
    bool? perSide,
    String? notes,
    List<SetEntry>? sets,
  }) {
    return Exercise(
      id: id,
      name: name ?? this.name,
      done: done ?? this.done,
      perSide: perSide ?? this.perSide,
      notes: notes ?? this.notes,
      sets: sets ?? this.sets,
    );
  }
}

/// Superset/circuito: completar todos sus ejercicios una vez = 1 serie.
class Block {
  final String id;
  final String? label;

  /// Número de vueltas del bloque
  final int series;

  final List<Exercise> exercises;

  const Block({
    required this.id,
    this.label,
    this.series = 3,
    this.exercises = const [],
  });

  Block copyWith({String? label, int? series, List<Exercise>? exercises}) {
    return Block(
      id: id,
      label: label ?? this.label,
      series: series ?? this.series,
      exercises: exercises ?? this.exercises,
    );
  }

  /// Cambia el número de series ajustando la tabla `sets` de cada ejercicio
  /// (agrega o quita filas conservando lo ya capturado).
  Block withSeries(int newSeries) {
    return Block(
      id: id,
      label: label,
      series: newSeries,
      exercises: exercises
          .map((e) => e.copyWith(sets: resizeSets(e.sets, newSeries)))
          .toList(),
    );
  }

  static List<SetEntry> resizeSets(List<SetEntry> sets, int n) {
    if (sets.length >= n) return sets.sublist(0, n);
    return [
      ...sets,
      ...List.generate(n - sets.length, (_) => const SetEntry()),
    ];
  }
}

class Routine {
  final String id;
  final String userId;
  final String name;
  final String? notes;
  final String emoji;
  final List<Block> blocks;
  final DateTime createdAt;
  final bool isArchived;

  const Routine({
    required this.id,
    required this.userId,
    required this.name,
    this.notes,
    this.emoji = '🏋️',
    this.blocks = const [],
    required this.createdAt,
    this.isArchived = false,
  });

  int get totalExercises =>
      blocks.fold(0, (sum, b) => sum + b.exercises.length);

  Routine copyWith({
    String? name,
    String? notes,
    String? emoji,
    List<Block>? blocks,
    bool? isArchived,
  }) {
    return Routine(
      id: id,
      userId: userId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      emoji: emoji ?? this.emoji,
      blocks: blocks ?? this.blocks,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
