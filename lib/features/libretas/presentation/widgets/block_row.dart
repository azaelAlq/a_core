import 'package:flutter/material.dart';
import 'package:a_core/features/libretas/presentation/widgets/block.dart';
import 'package:a_core/features/libretas/presentation/widgets/block_content.dart';
import 'package:a_core/features/libretas/presentation/widgets/block_type_sheet.dart';

class BlockRow extends StatefulWidget {
  final Block block;
  final int index;
  final TextEditingController ctrl;
  final FocusNode focus;
  final VoidCallback onEnter;
  final VoidCallback onBackspaceEmpty;
  final VoidCallback onMergeWithPrevious;
  final VoidCallback onToggleCheck;
  final VoidCallback onDelete;
  final Function(BlockType) onChangeType;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onToggleSelect;

  const BlockRow({
    super.key,
    required this.block,
    required this.index,
    required this.ctrl,
    required this.focus,
    required this.onEnter,
    required this.onBackspaceEmpty,
    required this.onMergeWithPrevious,
    required this.onToggleCheck,
    required this.onDelete,
    required this.onChangeType,
    required this.selected,
    required this.selectionMode,
    required this.onToggleSelect,
  });

  @override
  State<BlockRow> createState() => _BlockRowState();
}

class _BlockRowState extends State<BlockRow> {
  bool _hovering = false;
  bool _hasFocus = false;
  late final VoidCallback _focusListener;

  @override
  void initState() {
    super.initState();
    _hasFocus = widget.focus.hasFocus;
    _focusListener = () {
      if (mounted) setState(() => _hasFocus = widget.focus.hasFocus);
    };
    widget.focus.addListener(_focusListener);
  }

  @override
  void dispose() {
    widget.focus.removeListener(_focusListener);
    super.dispose();
  }

  void _openTypeMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlockTypeSheet(
        current: widget.block.type,
        onSelect: widget.onChangeType,
        onDelete: widget.onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = widget.block;
    final isSeparador = block.type == BlockType.separador;

    final topPad = switch (block.type) {
      BlockType.titulo => 28.0,
      BlockType.subtitulo => 20.0,
      BlockType.separador => 8.0,
      _ => 2.0,
    };

    final handleOpacity = _hasFocus || _hovering ? 0.5 : 0.12;

    final handle = SizedBox(
      width: 32,
      height: 32,
      child: Center(
        child: widget.selectionMode
            ? Icon(
                widget.selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 18,
                color: widget.selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.3),
              )
            : AnimatedOpacity(
                opacity: handleOpacity,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  Icons.drag_indicator_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
      ),
    );

    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _hovering = false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.selectionMode ? widget.onToggleSelect : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: widget.selected ? theme.colorScheme.primary.withOpacity(0.08) : Colors.transparent,
          child: Padding(
            padding: EdgeInsets.only(top: topPad, bottom: 2),
            child: Row(
              crossAxisAlignment: isSeparador
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.selectionMode ? widget.onToggleSelect : _openTypeMenu,
                  onLongPress: widget.onToggleSelect,
                  child: widget.selectionMode
                      ? handle
                      : ReorderableDragStartListener(index: widget.index, child: handle),
                ),
                if (isSeparador)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Divider(
                        height: 1,
                        thickness: 0.5,
                        color: theme.colorScheme.onSurface.withOpacity(0.15),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: AbsorbPointer(
                      absorbing: widget.selectionMode,
                      child: BlockContent(
                        block: block,
                        ctrl: widget.ctrl,
                        focus: widget.focus,
                        onEnter: widget.onEnter,
                        onBackspaceEmpty: widget.onBackspaceEmpty,
                        onMergeWithPrevious: widget.onMergeWithPrevious,
                        onToggleCheck: widget.onToggleCheck,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
