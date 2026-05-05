import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:a_core/core/routes/app_router.dart';
import 'package:a_core/features/auth/presentation/provider/auth_provider.dart';
import 'package:a_core/features/diario/domain/entities/diary_entry.dart';
import 'package:a_core/features/diario/presentation/provider/diary_provider.dart';

const _moods = {
  'great': ('😄', 'Genial'),
  'good': ('🙂', 'Bien'),
  'neutral': ('😐', 'Neutral'),
  'bad': ('😕', 'Mal'),
  'awful': ('😞', 'Pésimo'),
};

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({super.key});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) context.read<DiaryProvider>().init(uid);
    });
  }

  List<DiaryEntry> _entriesForDay(List<DiaryEntry> all, DateTime day) =>
      all.where((e) => isSameDay(e.date, day)).toList();

  @override
  @override
  Widget build(BuildContext context) {
    final diary = context.watch<DiaryProvider>();
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final theme = Theme.of(context);
    final entries = _entriesForDay(diary.entries, _selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Diario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          final calendar = TableCalendar<DiaryEntry>(
            locale: 'es_MX',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
            selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
            eventLoader: (d) => _entriesForDay(diary.entries, d),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: theme.textTheme.titleSmall!,
              leftChevronMargin: EdgeInsets.zero,
              rightChevronMargin: EdgeInsets.zero,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markerSize: 5,
              cellMargin: const EdgeInsets.all(4),
            ),
            onDaySelected: (selected, focused) => setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            }),
            onPageChanged: (focused) => setState(() => _focusedDay = focused),
          );

          final dayHeader = Padding(
            padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 16, isWide ? 24 : 16, 0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE d \'de\' MMMM', 'es').format(_selectedDay),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entries.length} entrada${entries.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.diaryEntry),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nueva entrada'),
                ),
              ],
            ),
          );

          final entryList = entries.isEmpty
              ? _EmptyState(theme: theme)
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 8, isWide ? 24 : 16, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final entry = entries[i];
                    return _EntryCard(
                      entry: entry,
                      onTap: () => context.push(AppRoutes.diaryEntry, extra: entry),
                      onDelete: () => diary.deleteEntry(uid, entry.id),
                    );
                  },
                );

          if (isWide) {
            // ── Web: dos columnas ──────────────────────────
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: theme.dividerColor, width: 0.5)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: calendar,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      dayHeader,
                      const SizedBox(height: 12),
                      Divider(height: 1, color: theme.dividerColor),
                      const SizedBox(height: 8),
                      Expanded(child: entryList),
                    ],
                  ),
                ),
              ],
            );
          }

          // ── Móvil: una columna ─────────────────────────
          return Column(
            children: [
              calendar,
              Divider(height: 1, color: theme.dividerColor),
              dayHeader,
              const SizedBox(height: 8),
              Expanded(child: entryList),
            ],
          );
        },
      ),
      // FAB solo en móvil
      floatingActionButton: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth > 700
            ? const SizedBox.shrink()
            : FloatingActionButton.extended(
                onPressed: () => context.push(AppRoutes.diaryEntry),
                icon: const Icon(Icons.add),
                label: const Text('Nueva entrada'),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _EntryCard extends StatelessWidget {
  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EntryCard({required this.entry, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mood = _moods[entry.mood] ?? ('😐', 'Neutral');
    final dateStr = DateFormat('EEE d MMM', 'es').format(entry.date);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(mood.$1, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.content,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: entry.tags
                            .map(
                              (t) => Chip(
                                label: Text(t),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.zero,
                                labelStyle: theme.textTheme.labelSmall,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    useRootNavigator: true,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Eliminar entrada'),
                      content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.book_outlined, size: 56, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Sin entradas este período',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para escribir tu primera entrada',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
