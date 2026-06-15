import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/libretas/domain/entities/libreta.dart';
import 'package:a_core/features/libretas/domain/entities/pagina.dart';
import 'package:a_core/features/libretas/presentation/provider/libretas_provider.dart';
import 'package:a_core/features/libretas/presentation/widgets/block.dart';
import 'package:a_core/features/libretas/presentation/widgets/block_row.dart';
import 'package:a_core/features/libretas/presentation/widgets/format_toolbar.dart';

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
  Timer? _timer;
  bool _saved = true;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _blocks = parseBlocks(widget.pagina.contenido ?? '');
    for (final b in _blocks) _initBlock(b);
  }

  // ── Lifecycle de bloques ──────────────────────────────────────────────

  void _initBlock(Block b) {
    final ctrl = TextEditingController(text: b.text);

    ctrl.addListener(() {
      if (_disposed) return;
      final idx = _blocks.indexWhere((x) => x.id == b.id);
      if (idx == -1) return;
      _blocks[idx].text = ctrl.text;
      _schedule();
    });

    final fn = FocusNode(
      onKeyEvent: (_, ev) {
        if (_disposed || ev is! KeyDownEvent) return KeyEventResult.ignored;
        if (ev.logicalKey != LogicalKeyboardKey.backspace) return KeyEventResult.ignored;
        if (!ctrl.selection.isCollapsed || ctrl.selection.baseOffset != 0) {
          return KeyEventResult.ignored;
        }
        final idx = _blocks.indexWhere((x) => x.id == b.id);
        if (idx == -1) return KeyEventResult.ignored;
        if (ctrl.text.isEmpty) {
          _deleteAt(idx);
        } else {
          _mergeWithPrevious(idx);
        }
        return KeyEventResult.handled;
      },
    );

    _ctrls[b.id] = ctrl;
    _focuses[b.id] = fn;
  }

  void _disposeBlock(String id) {
    _ctrls[id]?.dispose();
    _focuses[id]?.dispose();
    _ctrls.remove(id);
    _focuses.remove(id);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    for (final id in _ctrls.keys.toList()) _disposeBlock(id);
    super.dispose();
  }

  // ── Guardado ──────────────────────────────────────────────────────────

  void _schedule() {
    if (_disposed) return;
    if (mounted && _saved) setState(() => _saved = false);
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), _save);
  }

  Future<void> _save() async {
    if (_disposed || !mounted) return;
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final updated = widget.pagina.copyWith(
      contenido: serializeBlocks(_blocks),
      updatedAt: DateTime.now(),
    );
    await context.read<LibretasProvider>().savePagina(uid, updated);
    if (!_disposed && mounted) setState(() => _saved = true);
  }

  Future<void> _saveNow() async {
    _timer?.cancel();
    if (!_saved) await _save();
  }

  // ── Operaciones de bloque ─────────────────────────────────────────────

  void _addAfter(int idx, {String initialText = ''}) {
    if (_disposed || !mounted) return;
    final b = Block(id: Block.uid(), text: initialText);
    _initBlock(b);
    setState(() => _blocks.insert(idx + 1, b));
    Future.microtask(() {
      if (_disposed || !mounted) return;
      if (initialText.isNotEmpty) {
        _ctrls[b.id]?.selection = TextSelection.collapsed(offset: initialText.length);
      }
      _focuses[b.id]?.requestFocus();
    });
    _schedule();
  }

  void _deleteAt(int idx) {
    if (_disposed || !mounted) return;
    if (_blocks.length == 1) {
      _ctrls[_blocks[0].id]?.clear();
      return;
    }
    final id = _blocks[idx].id;
    setState(() => _blocks.removeAt(idx));
    _disposeBlock(id);
    final fi = (idx - 1).clamp(0, _blocks.length - 1);
    Future.microtask(() {
      if (!_disposed && mounted) _focuses[_blocks[fi].id]?.requestFocus();
    });
    _schedule();
  }

  void _mergeWithPrevious(int idx) {
    if (_disposed || !mounted || idx == 0) return;
    final prev = _blocks[idx - 1];
    final curr = _blocks[idx];
    final prevCtrl = _ctrls[prev.id]!;
    final caretPos = prev.text.length;
    final merged = prev.text + curr.text;

    prev.text = merged;
    prevCtrl.value = TextEditingValue(
      text: merged,
      selection: TextSelection.collapsed(offset: caretPos),
    );

    final id = curr.id;
    setState(() => _blocks.removeAt(idx));
    _disposeBlock(id);

    Future.microtask(() {
      if (!_disposed && mounted) {
        _focuses[prev.id]?.requestFocus();
        _ctrls[prev.id]?.selection = TextSelection.collapsed(offset: caretPos);
      }
    });
    _schedule();
  }

  void _changeType(int idx, BlockType type) {
    if (_disposed || !mounted) return;
    setState(() => _blocks[idx] = _blocks[idx].copyWith(type: type));
    _schedule();
    Future.microtask(() {
      if (!_disposed && mounted) _focuses[_blocks[idx].id]?.requestFocus();
    });
  }

  void _toggleCheck(int idx) {
    if (_disposed || !mounted) return;
    setState(() => _blocks[idx] = _blocks[idx].copyWith(checked: !_blocks[idx].checked));
    _schedule();
  }

  void _onReorder(int oldIdx, int newIdx) {
    if (_disposed || !mounted) return;
    if (newIdx > oldIdx) newIdx--;
    setState(() => _blocks.insert(newIdx, _blocks.removeAt(oldIdx)));
    _schedule();
  }

  // ── Enter: dividir bloque ─────────────────────────────────────────────

  void _handleEnter(int idx) {
    if (_disposed || !mounted) return;

    final ctrl = _ctrls[_blocks[idx].id]!;
    final cursorPos = ctrl.selection.baseOffset;
    final currentText = ctrl.text;

    // Parte 1: texto antes del cursor
    final beforeCursor = currentText.substring(0, cursorPos);
    // Parte 2: texto después del cursor
    final afterCursor = currentText.substring(cursorPos);

    // Actualiza el bloque actual
    _blocks[idx].text = beforeCursor;
    ctrl.text = beforeCursor;

    // Crea nuevo bloque con el texto después
    final newBlock = Block(id: Block.uid(), text: afterCursor);
    _initBlock(newBlock);

    setState(() => _blocks.insert(idx + 1, newBlock));

    Future.microtask(() {
      if (!_disposed && mounted) {
        _focuses[newBlock.id]?.requestFocus();
      }
    });

    _schedule();
  }

  // ── Formato inline ────────────────────────────────────────────────────

  int get _activeIdx {
    for (int i = 0; i < _blocks.length; i++) {
      if (_focuses[_blocks[i].id]?.hasFocus == true) return i;
    }
    return -1;
  }

  void _applyFormat(String tag) {
    if (_disposed) return;
    final idx = _activeIdx;
    if (idx == -1) return;
    final ctrl = _ctrls[_blocks[idx].id]!;
    final sel = ctrl.selection;
    if (!sel.isValid || sel.isCollapsed) return;
    final selected = ctrl.text.substring(sel.start, sel.end);
    final replacement = '$tag$selected$tag';
    ctrl.value = ctrl.value.copyWith(
      text: ctrl.text.replaceRange(sel.start, sel.end, replacement),
      selection: TextSelection.collapsed(offset: sel.start + replacement.length),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = Color(int.parse('FF${widget.libreta.color}', radix: 16));
    final isWide = MediaQuery.of(context).size.width > 800;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _saveNow();
      },
      child: Scaffold(
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
                        Text(
                          'Guardado',
                          style: theme.textTheme.labelSmall?.copyWith(color: accent),
                        ),
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
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWide ? 760 : double.infinity),
                child: FormatToolbar(
                  onBold: () => _applyFormat('**'),
                  onItalic: () => _applyFormat('_'),
                  onUnderline: () => _applyFormat('__'),
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 120),
                onReorder: _onReorder,
                buildDefaultDragHandles: false,
                itemCount: _blocks.length,
                itemBuilder: (ctx, i) {
                  final b = _blocks[i];
                  return Center(
                    key: ValueKey(b.id),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isWide ? 760 : double.infinity),
                      child: BlockRow(
                        block: b,
                        index: i,
                        ctrl: _ctrls[b.id]!,
                        focus: _focuses[b.id]!,
                        onEnter: () => _handleEnter(i),
                        onToggleCheck: () => _toggleCheck(i),
                        onDelete: () => _deleteAt(i),
                        onChangeType: (type) => _changeType(i, type),
                        onBackspaceEmpty: () => _deleteAt(i),
                        onMergeWithPrevious: () => _mergeWithPrevious(i),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
