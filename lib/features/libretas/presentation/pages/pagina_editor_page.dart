import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/libretas/domain/entities/libreta.dart';
import 'package:a_core/features/libretas/domain/entities/pagina.dart';
import 'package:a_core/features/libretas/presentation/provider/libretas_provider.dart';

// ─── Modelo de bloque ───────────────────────────────────────────────────
enum BlockType { titulo, subtitulo, parrafo, bullet, checklist, cita, separador }

class Block {
  final String id;
  BlockType type;
  String text;
  bool checked;

  Block({required this.id, this.type = BlockType.parrafo, this.text = '', this.checked = false});

  static String _uid() => DateTime.now().microsecondsSinceEpoch.toString();
  static Block blank() => Block(id: _uid());

  String toRaw() => '${type.name}|${checked ? '1' : '0'}|$text';

  static Block fromRaw(String raw) {
    final parts = raw.split('|');
    if (parts.length < 3) return Block(id: _uid(), text: raw);
    return Block(
      id: _uid(),
      type: BlockType.values.firstWhere((t) => t.name == parts[0], orElse: () => BlockType.parrafo),
      checked: parts[1] == '1',
      text: parts.sublist(2).join('|'),
    );
  }

  Block copyWith({BlockType? type, String? text, bool? checked}) => Block(
    id: id,
    type: type ?? this.type,
    text: text ?? this.text,
    checked: checked ?? this.checked,
  );
}

List<Block> _parse(String content) {
  if (content.trim().isEmpty) return [Block.blank()];
  return content.split('\n').map(Block.fromRaw).toList();
}

String _serialize(List<Block> blocks) => blocks.map((b) => b.toRaw()).join('\n');

// ─── Página ─────────────────────────────────────────────────────────────
class PaginaEditorPage extends StatefulWidget {
  final Pagina pagina;
  final Libreta libreta;
  const PaginaEditorPage({super.key, required this.pagina, required this.libreta});

  @override
  State<PaginaEditorPage> createState() => _PaginaEditorPageState();
}

class _PaginaEditorPageState extends State<PaginaEditorPage> {
  late List<Block> _blocks;
  final Map<String, TextEditingController> _ctrls = {};
  final Map<String, FocusNode> _focuses = {};
  final Set<String> _ignoreNextChange = {};
  Timer? _timer;
  bool _saved = true;

  @override
  void initState() {
    super.initState();
    _blocks = _parse(widget.pagina.contenido ?? '');
    for (final b in _blocks) _init(b);
  }

  void _init(Block b) {
    _ctrls[b.id] = TextEditingController(text: b.text)
      ..addListener(() {
        final idx = _blocks.indexWhere((x) => x.id == b.id);
        if (idx == -1) return;

        if (_ignoreNextChange.contains(b.id)) {
          _ignoreNextChange.remove(b.id);
          return;
        }

        final raw = _ctrls[b.id]!.text;

        if (raw.contains('\n')) {
          final parts = raw.split('\n');
          final before = parts[0];
          final after = parts.sublist(1).join('');

          _ignoreNextChange.add(b.id);
          _ctrls[b.id]!.value = TextEditingValue(
            text: before,
            selection: TextSelection.collapsed(offset: before.length),
          );
          _blocks[idx].text = before;
          _schedule();
          _addAfterWithText(idx, after);
          return;
        }

        _blocks[idx].text = raw;
        _schedule();
      });
    _focuses[b.id] = FocusNode();
  }

  void _dispose(String id) {
    _ctrls[id]?.dispose();
    _focuses[id]?.dispose();
    _ctrls.remove(id);
    _focuses.remove(id);
  }

  void _schedule() {
    if (mounted && _saved) setState(() => _saved = false);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), _save);
  }

  Future<void> _save() async {
    if (!mounted) return;
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final updated = widget.pagina.copyWith(
      contenido: _serialize(_blocks),
      updatedAt: DateTime.now(),
    );
    await context.read<LibretasProvider>().savePagina(uid, updated);
    if (mounted) setState(() => _saved = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    for (final id in _ctrls.keys.toList()) _dispose(id);
    super.dispose();
  }

  void _addAfter(int idx) {
    if (!mounted) return;
    final b = Block.blank();
    _init(b);
    setState(() => _blocks.insert(idx + 1, b));
    Future.microtask(() {
      if (mounted) _focuses[b.id]?.requestFocus();
    });
  }

  void _addAfterWithText(int idx, String initialText) {
    if (!mounted) return;
    final b = Block(id: Block._uid(), text: initialText);
    _init(b);
    setState(() => _blocks.insert(idx + 1, b));
    Future.microtask(() {
      if (!mounted) return;
      final ctrl = _ctrls[b.id];
      if (ctrl != null) {
        ctrl.selection = TextSelection.collapsed(offset: initialText.length);
      }
      _focuses[b.id]?.requestFocus();
    });
  }

  void _deleteAt(int idx) {
    if (!mounted) return;
    if (_blocks.length == 1) {
      _ctrls[_blocks[0].id]?.clear();
      return;
    }
    final id = _blocks[idx].id;
    setState(() => _blocks.removeAt(idx));
    _dispose(id);
    final focusIdx = (idx - 1).clamp(0, _blocks.length - 1);
    Future.microtask(() {
      if (mounted) _focuses[_blocks[focusIdx].id]?.requestFocus();
    });
  }

  void _changeType(int idx, BlockType type) {
    if (!mounted) return;
    setState(() => _blocks[idx] = _blocks[idx].copyWith(type: type));
    _schedule();
    Future.microtask(() {
      if (mounted) _focuses[_blocks[idx].id]?.requestFocus();
    });
  }

  void _toggleCheck(int idx) {
    if (!mounted) return;
    setState(() => _blocks[idx] = _blocks[idx].copyWith(checked: !_blocks[idx].checked));
    _schedule();
  }

  int get _activeIdx {
    for (int i = 0; i < _blocks.length; i++) {
      if (_focuses[_blocks[i].id]?.hasFocus == true) return i;
    }
    return -1;
  }

  void _applyFormat(String tag) {
    final idx = _activeIdx;
    if (idx == -1) return;
    final ctrl = _ctrls[_blocks[idx].id]!;
    final sel = ctrl.selection;
    if (!sel.isValid || sel.isCollapsed) return;
    final selected = ctrl.text.substring(sel.start, sel.end);
    final replacement = '$tag$selected$tag';
    final newText = ctrl.text.replaceRange(sel.start, sel.end, replacement);
    ctrl.value = ctrl.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + replacement.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Color(int.parse('FF${widget.libreta.color}', radix: 16));
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.pagina.titulo,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Text(widget.libreta.emoji, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(
                  widget.libreta.titulo,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _saved
                ? Row(
                    key: const ValueKey('s'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 14, color: accent),
                      const SizedBox(width: 4),
                      Text('Guardado', style: theme.textTheme.labelSmall?.copyWith(color: accent)),
                    ],
                  )
                : Row(
                    key: const ValueKey('u'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Editando',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Toolbar centrado en web
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWide ? 760 : double.infinity),
              child: _FormatToolbar(
                onBold: () => _applyFormat('**'),
                onItalic: () => _applyFormat('_'),
                onUnderline: () => _applyFormat('__'),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(0, 12, 0, 120),
              itemCount: _blocks.length,
              itemBuilder: (ctx, i) => Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 760 : double.infinity),
                  child: _BlockRow(
                    key: ValueKey(_blocks[i].id),
                    block: _blocks[i],
                    ctrl: _ctrls[_blocks[i].id]!,
                    focus: _focuses[_blocks[i].id]!,
                    onEnter: () => _addAfter(i),
                    onBackspaceEmpty: () => _deleteAt(i),
                    onToggleCheck: () => _toggleCheck(i),
                    onDelete: () => _deleteAt(i),
                    onChangeType: (type) => _changeType(i, type),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Toolbar ────────────────────────────────────────────────────────────
class _FormatToolbar extends StatelessWidget {
  final VoidCallback onBold, onItalic, onUnderline;
  const _FormatToolbar({required this.onBold, required this.onItalic, required this.onUnderline});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _FBtn(icon: Icons.format_bold_rounded, tooltip: 'Negrita', onTap: onBold),
          _FBtn(icon: Icons.format_italic_rounded, tooltip: 'Cursiva', onTap: onItalic),
          _FBtn(icon: Icons.format_underline_rounded, tooltip: 'Subrayado', onTap: onUnderline),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
          ),
          Icon(
            Icons.touch_app_outlined,
            size: 13,
            color: theme.colorScheme.onSurface.withOpacity(0.25),
          ),
          const SizedBox(width: 4),
          Text(
            'Toca ⋮⋮ para cambiar el tipo de bloque',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.25),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _FBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _FBtn({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    ),
  );
}

// ─── Fila de bloque ──────────────────────────────────────────────────────
class _BlockRow extends StatefulWidget {
  final Block block;
  final TextEditingController ctrl;
  final FocusNode focus;
  final VoidCallback onEnter;
  final VoidCallback onBackspaceEmpty;
  final VoidCallback onToggleCheck;
  final VoidCallback onDelete;
  final Function(BlockType) onChangeType;

  const _BlockRow({
    super.key,
    required this.block,
    required this.ctrl,
    required this.focus,
    required this.onEnter,
    required this.onBackspaceEmpty,
    required this.onToggleCheck,
    required this.onDelete,
    required this.onChangeType,
  });

  @override
  State<_BlockRow> createState() => _BlockRowState();
}

class _BlockRowState extends State<_BlockRow> {
  bool _showHandle = false;
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

  void _openTypeMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _BlockTypeSheet(
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

    final topPad = switch (block.type) {
      BlockType.titulo => 28.0,
      BlockType.subtitulo => 20.0,
      BlockType.separador => 8.0,
      _ => 2.0,
    };

    final isSeparador = block.type == BlockType.separador;

    return MouseRegion(
      onEnter: (_) {
        if (mounted) setState(() => _showHandle = true);
      },
      onExit: (_) {
        if (mounted) setState(() => _showHandle = false);
      },
      child: GestureDetector(
        onLongPress: () {
          if (mounted) setState(() => _showHandle = !_showHandle);
        },
        child: Padding(
          padding: EdgeInsets.only(top: topPad, bottom: 2),
          child: Row(
            crossAxisAlignment: isSeparador ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              // Handle
              GestureDetector(
                onTap: () => _openTypeMenu(context),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _hasFocus || _showHandle ? 0.5 : 0.12,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              // Contenido
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
                  child: _BlockContent(
                    block: block,
                    ctrl: widget.ctrl,
                    focus: widget.focus,
                    onEnter: widget.onEnter,
                    onBackspaceEmpty: widget.onBackspaceEmpty,
                    onToggleCheck: widget.onToggleCheck,
                  ),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Contenido del bloque ────────────────────────────────────────────────
class _BlockContent extends StatelessWidget {
  final Block block;
  final TextEditingController ctrl;
  final FocusNode focus;
  final VoidCallback onEnter;
  final VoidCallback onBackspaceEmpty;
  final VoidCallback onToggleCheck;

  const _BlockContent({
    required this.block,
    required this.ctrl,
    required this.focus,
    required this.onEnter,
    required this.onBackspaceEmpty,
    required this.onToggleCheck,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    TextStyle style = switch (block.type) {
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

    final field = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.backspace): () {
          if (ctrl.text.isEmpty) onBackspaceEmpty();
        },
      },
      child: TextField(
        controller: ctrl,
        focusNode: focus,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
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

// ─── Sheet tipo de bloque ────────────────────────────────────────────────
class _BlockTypeSheet extends StatelessWidget {
  final BlockType current;
  final Function(BlockType) onSelect;
  final VoidCallback onDelete;

  const _BlockTypeSheet({required this.current, required this.onSelect, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
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
            final isActive = current == type;
            return ListTile(
              leading: Icon(
                icon,
                size: 20,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.55),
              ),
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? theme.colorScheme.primary : null,
                  fontSize: 14,
                ),
              ),
              trailing: isActive
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
