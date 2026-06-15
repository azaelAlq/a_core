import 'package:flutter/material.dart';

class FormatToolbar extends StatelessWidget {
  final VoidCallback onBold, onItalic, onUnderline;
  const FormatToolbar({
    super.key,
    required this.onBold,
    required this.onItalic,
    required this.onUnderline,
  });

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
