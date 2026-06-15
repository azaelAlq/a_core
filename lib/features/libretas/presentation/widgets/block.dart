import 'dart:convert';
import 'package:flutter/services.dart';

enum BlockType { titulo, subtitulo, parrafo, bullet, checklist, cita, separador }

class Block {
  final String id;
  BlockType type;
  String text;
  bool checked;

  Block({required this.id, this.type = BlockType.parrafo, this.text = '', this.checked = false});

  static String uid() => DateTime.now().microsecondsSinceEpoch.toString();
  static Block blank() => Block(id: uid());

  Map<String, dynamic> toJson() => {'id': id, 'type': type.name, 'text': text, 'checked': checked};

  static Block fromJson(Map<String, dynamic> json) {
    return Block(
      id: json['id'] as String? ?? uid(),
      type: BlockType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => BlockType.parrafo,
      ),
      text: json['text'] as String? ?? '',
      checked: json['checked'] as bool? ?? false,
    );
  }

  Block copyWith({BlockType? type, String? text, bool? checked}) => Block(
    id: id,
    type: type ?? this.type,
    text: text ?? this.text,
    checked: checked ?? this.checked,
  );
}

List<Block> parseBlocks(String content) {
  if (content.trim().isEmpty) return [Block.blank()];

  try {
    final decoded = jsonDecode(content) as List;
    final blocks = decoded.map((item) => Block.fromJson(item as Map<String, dynamic>)).toList();
    return blocks.isNotEmpty ? blocks : [Block.blank()];
  } catch (_) {
    // Fallback a formato antiguo para compatibilidad
    return [Block(id: Block.uid(), text: content)];
  }
}

String serializeBlocks(List<Block> blocks) {
  final json = blocks.map((b) => b.toJson()).toList();
  return jsonEncode(json);
}

/// Intercepta \n antes de que se inserte en el controller.
/// En móvil: el teclado virtual manda un \n cuando el usuario toca Enter.
/// En desktop: CallbackShortcuts captura la tecla antes de que llegue aquí.
class NewlineInterceptor extends TextInputFormatter {
  final VoidCallback onEnter;
  NewlineInterceptor({required this.onEnter});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue next) {
    if (next.text.contains('\n')) {
      Future.microtask(onEnter);
      return old; // devuelve sin el \n
    }
    return next;
  }
}
