import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/app_actions.dart';
import '../../data/mock_data.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Настроения из макета (экран 10): цветные «смайлы».
const moods = [
  (PhosphorIconsRegular.smileySad, 'Тяжело', [Color(0xFFF5A15A), Color(0xFFE07A2E)]),
  (PhosphorIconsRegular.smileyMeh, 'Грустно', [Color(0xFFFBD56B), Color(0xFFF0B63A)]),
  (PhosphorIconsRegular.smileyMeh, 'Спокойно', [Color(0xFF9FDABD), Color(0xFF6DC29B)]),
  (PhosphorIconsRegular.smiley, 'Хорошо', [Color(0xFF9FCDF0), Color(0xFF6CB0E3)]),
  (PhosphorIconsRegular.smiley, 'Радостно', [Color(0xFFCDBDF5), Color(0xFFA78CE8)]),
];

class MoodFace extends StatelessWidget {
  const MoodFace(this.index, {super.key, this.size = 56, this.selected = false, this.onTap});
  final int index;
  final double size;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, label, colors) = moods[index];
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.1 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
              border: Border.all(color: selected ? context.colors.gold : Colors.white, width: selected ? 3 : 2),
              boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Icon(icon, color: Colors.black.withValues(alpha: 0.55), size: size * 0.62),
          ),
        ),
      ),
    );
  }
}

/// JRN-01 — дневник (макет, экран 10): запись прямо на экране + список записей.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _text = TextEditingController();
  int? _mood;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _save() {
    if (_text.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Напиши хотя бы пару слов')));
      return;
    }
    ref.read(journalProvider.notifier).add(JournalEntry(date: DateTime.now(), text: _text.text.trim(), mood: _mood ?? 2));
    _text.clear();
    setState(() => _mood = null);
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Запись сохранена')));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final entries = ref.watch(journalProvider);
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final daysWithEntries = {for (final e in entries) DateTime(e.date.year, e.date.month, e.date.day)};

    return Scaffold(
      appBar: appHeader(context, 'Дневник', actions: [
        Padding(padding: const EdgeInsets.only(right: 4), child: Icon(PhosphorIconsRegular.lock, color: c.text.withValues(alpha: 0.7), size: 22)),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Сегодня', style: t.bodySmall?.copyWith(color: c.text.withValues(alpha: 0.7))),
                const SizedBox(height: 2),
                Text('${now.day} ${monthGen[now.month - 1]} ${now.year}', style: t.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Column(
                          children: [
                            Text(const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'][i], style: t.bodySmall?.copyWith(color: c.textMuted)),
                            const SizedBox(height: 8),
                            Builder(builder: (context) {
                              final d = start.add(Duration(days: i));
                              final isToday = d.day == now.day && d.month == now.month;
                              return Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: isToday ? LinearGradient(colors: c.goldGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${d.day}', style: t.bodyMedium?.copyWith(color: isToday ? c.onGold : c.text, fontWeight: FontWeight.w600)),
                                    if (daysWithEntries.contains(d) && !isToday)
                                      Container(width: 4, height: 4, decoration: BoxDecoration(color: c.gold, shape: BoxShape.circle)),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('За что ты сегодня благодарен?', style: t.titleMedium?.copyWith(fontSize: 16.5)),
          const SizedBox(height: 10),
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Напиши свои мысли...',
              suffixIcon: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: IconButton(
                  tooltip: 'Сказать голосом',
                  onPressed: () => dictateInto(context, _text),
                  icon: Icon(PhosphorIconsRegular.microphone, color: c.textMuted),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text('Как прошёл твой день?', style: t.titleMedium?.copyWith(fontSize: 16.5)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < moods.length; i++) MoodFace(i, selected: _mood == i, onTap: () => setState(() => _mood = i)),
            ],
          ),
          const SizedBox(height: 26),
          PrimaryButton(label: 'Сохранить запись', onPressed: _save),
          if (entries.isNotEmpty) ...[
            const SectionHeader('Мои записи'),
            for (final e in entries) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      MoodFace(e.mood, size: 28),
                      const SizedBox(width: 10),
                      Expanded(child: Text(formatDate(e.date), style: t.bodySmall?.copyWith(color: c.textMuted))),
                      IconButton(
                        tooltip: 'Удалить запись',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => ref.read(journalProvider.notifier).remove(e),
                        icon: Icon(PhosphorIconsRegular.trash, size: 20, color: c.textMuted),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(e.text, style: t.bodyMedium, maxLines: 6, overflow: TextOverflow.ellipsis),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: c.goldStrong),
                        onPressed: () => context.push('/chat?q=${Uri.encodeComponent('Помоги разобраться с записью в дневнике: ${e.text}')}'),
                        icon: const Icon(PhosphorIconsRegular.sparkle, size: 18),
                        label: const Text('Разобраться с AI'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
          const SizedBox(height: 8),
          Center(child: Text('Записи хранятся только на этом устройстве', style: t.bodySmall?.copyWith(color: c.textMuted))),
        ],
      ),
    );
  }
}

/// JRN-02 — отдельная запись (из уведомлений и «Мой день»).
class JournalEntryScreen extends StatelessWidget {
  const JournalEntryScreen({super.key});

  @override
  Widget build(BuildContext context) => const JournalScreen();
}
