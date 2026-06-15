import 'package:flutter/material.dart';
import 'package:a_core/features/libretas/presentation/widgets/block.dart';

class BlockTypeSheet extends StatelessWidget {
  final BlockType current;
  final Function(BlockType) onSelect;
  final VoidCallback onDelete;

  const BlockTypeSheet({
    super.key,
    required this.current,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const items = [
      (BlockType.parrafo, Icons.notes_rounded, 'Texto normal'),
      (BlockType.titulo, Icons.title_rounded, 'Título'),
      (BlockType.subtitulo, Icons.text_fields_rounded, 'Subtítulo'),
      (BlockType.bullet, Icons.format_list_bulleted_rounded, 'Lista con puntos'),
      (BlockType.checklist, Icons.checklist_rounded, 'Lista de tareas'),
      (BlockType.cita, Icons.format_quote_rounded, 'Cita / nota'),
      (BlockType.separador, Icons.horizontal_rule_rounded, 'Separador'),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Tipo de bloque',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                letterSpacing: 0.8,
              ),
            ),
          ),
          ...items.map((item) {
            final (type, icon, label) = item;
            final active = current == type;
            return ListTile(
              leading: Icon(
                icon,
                size: 20,
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.55),
              ),
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? theme.colorScheme.primary : null,
                  fontSize: 14,
                ),
              ),
              trailing: active
                  ? Icon(Icons.check_rounded, size: 16, color: theme.colorScheme.primary)
                  : null,
              dense: true,
              onTap: () {
                Navigator.pop(context);
                onSelect(type);
              },
            );
          }),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          ListTile(
            leading: Icon(Icons.delete_outline_rounded, size: 20, color: theme.colorScheme.error),
            title: Text(
              'Eliminar bloque',
              style: TextStyle(color: theme.colorScheme.error, fontSize: 14),
            ),
            dense: true,
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
