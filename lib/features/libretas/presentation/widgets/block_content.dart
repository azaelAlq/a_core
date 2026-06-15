import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:a_core/features/libretas/presentation/widgets/block.dart';

class BlockContent extends StatelessWidget {
  final Block block;
  final TextEditingController ctrl;
  final FocusNode focus;
  final VoidCallback onEnter;
  final VoidCallback onBackspaceEmpty;
  final VoidCallback onMergeWithPrevious;
  final VoidCallback onToggleCheck;

  const BlockContent({
    super.key,
    required this.block,
    required this.ctrl,
    required this.focus,
    required this.onEnter,
    required this.onBackspaceEmpty,
    required this.onMergeWithPrevious,
    required this.onToggleCheck,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    final style = switch (block.type) {
      BlockType.titulo => GoogleFonts.lora(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: onSurface,
        letterSpacing: -0.5,
      ),
      BlockType.subtitulo => GoogleFonts.lora(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: onSurface.withOpacity(0.85),
      ),
      BlockType.cita => theme.textTheme.bodyLarge!.copyWith(
        height: 1.8,
        color: onSurface.withOpacity(0.5),
        fontStyle: FontStyle.italic,
        fontSize: 15,
      ),
      _ => theme.textTheme.bodyLarge!.copyWith(
        height: 1.75,
        color: onSurface.withOpacity(0.88),
        fontSize: 15,
      ),
    };

    // CallbackShortcuts: SOLO captura Enter en desktop/teclado físico.
    // Backspace es manejado por el FocusNode en pagina_editor_page.dart
    // NewlineInterceptor: maneja Enter en móvil (teclado virtual).
    final field = CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.enter): onEnter},
      child: TextField(
        controller: ctrl,
        focusNode: focus,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        inputFormatters: [NewlineInterceptor(onEnter: onEnter)],
        style: style,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: _hint(block.type),
          hintStyle: style.copyWith(color: onSurface.withOpacity(0.18)),
        ),
      ),
    );

    return switch (block.type) {
      BlockType.bullet => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, right: 10),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: onSurface.withOpacity(0.35), shape: BoxShape.circle),
            ),
          ),
          Expanded(child: field),
        ],
      ),
      BlockType.checklist => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggleCheck,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: block.checked ? theme.colorScheme.primary : Colors.transparent,
                  border: Border.all(
                    color: block.checked ? theme.colorScheme.primary : onSurface.withOpacity(0.3),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: block.checked
                    ? Icon(Icons.check_rounded, size: 13, color: theme.colorScheme.onPrimary)
                    : null,
              ),
            ),
          ),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(
                decoration: block.checked ? TextDecoration.lineThrough : null,
                color: block.checked ? onSurface.withOpacity(0.35) : null,
              ),
              child: field,
            ),
          ),
        ],
      ),
      BlockType.cita => Container(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          border: Border(
            left: BorderSide(color: theme.colorScheme.primary.withOpacity(0.4), width: 3),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: field,
      ),
      _ => field,
    };
  }

  String _hint(BlockType t) => switch (t) {
    BlockType.titulo => 'Título...',
    BlockType.subtitulo => 'Subtítulo...',
    BlockType.bullet => 'Elemento...',
    BlockType.checklist => 'Tarea...',
    BlockType.cita => 'Nota importante...',
    _ => '',
  };
}
