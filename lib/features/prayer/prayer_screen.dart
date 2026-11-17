import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/mock_data.dart';
import '../../design/listen_sheet.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// PR-01 — Молитва: поиск, избранное, молитвослов и свои тексты.
class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  int _tab = 0;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final tradition = ref.watch(sessionProvider).tradition;
    final mine = ref.watch(myPrayersProvider);
    final favs = ref.watch(favoritePrayersProvider);
    final book = prayerBook(tradition);
    final allPrayers = [for (final s in book) ...s.prayers];
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? allPrayers
        : allPrayers.where((p) => p.title.toLowerCase().contains(q) || (p.note?.toLowerCase().contains(q) ?? false) || p.text.toLowerCase().contains(q)).toList();
    final favoritePrayers = allPrayers.where((p) => favs.contains(p.id)).toList();
    final mineFiltered = q.isEmpty
        ? mine
        : mine.where((p) => p.title.toLowerCase().contains(q) || p.text.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: appHeader(context, 'Молитва', actions: [
        IconButton(tooltip: 'Озвучить любой текст', onPressed: () => _speakAnyText(context), icon: const Icon(PhosphorIconsRegular.speakerHigh)),
      ]),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          SegmentedTabs(labels: const ['Молитвослов', 'Избранное', 'Мои'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 12),
          SearchField(hint: 'Поиск молитв...', onChanged: (v) => setState(() => _query = v), onSubmitted: (v) => setState(() => _query = v)),
          const SizedBox(height: 16),
          AppCard(
            elevated: true,
            color: c.surfaceWarm,
            onTap: () => context.push('/prayer-create'),
            padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
            child: Row(
              children: [
                Expanded(child: Text('Написать молитву', style: t.titleMedium?.copyWith(fontSize: 16.5))),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: c.goldGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  ),
                  child: Icon(PhosphorIconsRegular.plus, color: c.onGold, size: 26),
                ),
              ],
            ),
          ),
          if (_tab == 0) ...[
            if (q.isNotEmpty) ...[
              SectionHeader('Найдено: ${filtered.length}'),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Ничего не найдено', textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: c.textMuted)),
                )
              else
                FlatSection(
                  children: [
                    for (final p in filtered) _prayerRow(context, p, favs.contains(p.id)),
                  ],
                ),
            ] else ...[
              SectionHeader(tradition == Tradition.catholic ? 'Молитвенник' : 'Молитвослов'),
              FlatSection(
                children: [
                  for (final (i, s) in book.indexed)
                    ListRowCard(
                      leading: PastelIcon(
                        const [PhosphorIconsRegular.cloudSun, PhosphorIconsRegular.moon, PhosphorIconsRegular.flame, PhosphorIconsRegular.lightning][i % 4],
                        const [Pastel.honey, Pastel.lavender, Pastel.peach, Pastel.mint][i % 4],
                        size: 44,
                        square: true,
                      ),
                      title: s.title,
                      subtitle: s.subtitle,
                      onTap: () => _openSection(context, s),
                    ),
                  ListRowCard(
                    leading: const PastelIcon(PhosphorIconsRegular.users, Pastel.rose, size: 44, square: true),
                    title: 'Молитва за близких',
                    subtitle: 'Молитва Господня',
                    onTap: () => context.push('/pray/our_father'),
                  ),
                ],
              ),
            ],
          ] else if (_tab == 1) ...[
            const SizedBox(height: 8),
            if (favoritePrayers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Добавляйте молитвы в избранное сердечком на экране чтения', textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: c.textMuted)),
              )
            else
              FlatSection(
                children: [
                  for (final p in favoritePrayers.where((p) => q.isEmpty || p.title.toLowerCase().contains(q)))
                    _prayerRow(context, p, true),
                ],
              ),
          ] else ...[
            const SizedBox(height: 8),
            if (mineFiltered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Сохранённые молитвы появятся здесь', textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: c.textMuted)),
              )
            else
              for (final p in mineFiltered) ...[
                AppCard(
                  onTap: () => showListenSheet(context, ref, title: p.title, text: p.text),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(p.title, style: t.titleMedium)),
                        if (p.aiGenerated) const AiBadge(label: 'составлено с AI'),
                        IconButton(
                          tooltip: 'Слушать',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => showListenSheet(context, ref, title: p.title, text: p.text),
                          icon: Icon(PhosphorIconsRegular.speakerHigh, color: c.goldStrong, size: 20),
                        ),
                        IconButton(
                          tooltip: 'Удалить',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => ref.read(myPrayersProvider.notifier).remove(p),
                          icon: Icon(PhosphorIconsRegular.trash, color: c.textMuted, size: 20),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text(p.text, style: t.bodyMedium, maxLines: 4, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
          ],
          const SectionHeader('Сегодня с тобой в молитве'),
          const QuoteCard(text: 'Просите, и дано будет вам; ищите, и найдёте; стучите, и отворят вам', reference: 'Матфея 7:7'),
        ],
      ),
    );
  }

  Widget _prayerRow(BuildContext context, Prayer p, bool fav) {
    final c = context.colors;
    return ListRowCard(
      title: p.title,
      subtitle: p.note,
      onTap: () => context.push('/pray/${p.id}'),
      trailing: IconButton(
        tooltip: fav ? 'Убрать из избранного' : 'В избранное',
        onPressed: () => ref.read(favoritePrayersProvider.notifier).toggle(p.id),
        icon: Icon(fav ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart, color: fav ? c.danger : c.textMuted, size: 22),
      ),
    );
  }

  Future<void> _speakAnyText(BuildContext context) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Озвучить текст'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          minLines: 4,
          maxLines: 10,
          decoration: const InputDecoration(hintText: 'Вставьте молитву, псалом или свой текст'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(d, ctrl.text), child: const Text('Создать аудио')),
        ],
      ),
    );
    ctrl.dispose();
    if (text != null && text.trim().isNotEmpty && context.mounted) {
      await showListenSheet(context, ref, title: 'Мой текст', text: text);
    }
  }

  void _openSection(BuildContext context, PrayerSection s) {
    final favs = ref.read(favoritePrayersProvider);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(s.title, style: sheet.text.titleLarge)),
              const SizedBox(height: 8),
              for (final p in s.prayers)
                ListRowCard(
                  title: p.title,
                  subtitle: p.note,
                  onTap: () {
                    Navigator.pop(sheet);
                    context.push('/pray/${p.id}');
                  },
                  trailing: IconButton(
                    onPressed: () => ref.read(favoritePrayersProvider.notifier).toggle(p.id),
                    icon: Icon(
                      favs.contains(p.id) ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
                      color: favs.contains(p.id) ? sheet.colors.danger : sheet.colors.textMuted,
                      size: 22,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
