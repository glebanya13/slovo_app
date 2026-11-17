import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/mock_data.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// BIB-01 — Библия (макет, экран 6). Канон — по традиции (ТЗ, раздел 6.1).
class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({super.key});

  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  int _tab = 0;
  bool? _oldTestament; // null — показано «Популярное»
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final tradition = ref.watch(sessionProvider).tradition;
    final ot = oldTestament(tradition);
    final nt = newTestament(tradition);
    final progress = ref.watch(readingProgressProvider);
    final last = ref.watch(lastReadingProvider);
    const psalmRef = 22;

    final popular = [
      ('gen', 1, 'Бытие', 'Начало всего', PhosphorIconsRegular.sun, Pastel.honey),
      ('ps', psalmRef, 'Псалмы', 'Утешение и вдохновение', PhosphorIconsRegular.musicNote, Pastel.rose),
      ('prov', 3, 'Притчи', 'Мудрость на каждый день', PhosphorIconsRegular.lightbulb, Pastel.sand),
      ('matt', 5, 'Евангелие от Матфея', 'Жизнь и учение Иисуса', PhosphorIconsRegular.books, Pastel.lavender),
      ('rom', 8, 'Римлянам', 'Вера, изменяющая жизнь', PhosphorIconsRegular.envelope, Pastel.peach),
    ];

    return Scaffold(
      appBar: appHeader(context, 'Библия', actions: [
        IconButton(tooltip: 'Перевод', onPressed: () => _showTranslation(context, tradition), icon: const Icon(PhosphorIconsRegular.question)),
      ]),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          SegmentedTabs(labels: const ['Читать', 'Закладки'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 16),
          if (_tab == 0) ...[
            SearchField(hint: 'Поиск в Библии...', onSubmitted: (q) => setState(() => _query = q.trim())),
            const SizedBox(height: 16),
            if (_query.isNotEmpty) ...[
              Row(children: [
                Expanded(child: Text('Найдено по «$_query»', style: t.titleMedium)),
                TextButton(onPressed: () => setState(() => _query = ''), child: const Text('Сбросить')),
              ]),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final hits = Bible.instance.search(_query);
                if (hits.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Ничего не найдено. Введите хотя бы 3 буквы.', textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.textMuted)),
                  );
                }
                return GroupCard(children: [
                  for (final h in hits)
                    ListRowCard(
                      title: '${chapterTitle(bookById(h.book), h.chapter, tradition)}:${h.verse}',
                      subtitle: h.text,
                      onTap: () => context.push('/read/${h.book}/${h.chapter}?v=${h.verse}'),
                    ),
                ]);
              }),
            ] else ...[
            Row(
              children: [
                Expanded(
                  child: _TestamentCard(
                    title: 'Ветхий Завет',
                    count: ot.length,
                    icon: PhosphorIconsRegular.bookOpen,
                    pastel: Pastel.honey,
                    selected: _oldTestament == true,
                    onTap: () => setState(() => _oldTestament = _oldTestament == true ? null : true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TestamentCard(
                    title: 'Новый Завет',
                    count: nt.length,
                    icon: PhosphorIconsRegular.newspaper,
                    pastel: Pastel.sky,
                    selected: _oldTestament == false,
                    onTap: () => setState(() => _oldTestament = _oldTestament == false ? null : false),
                  ),
                ),
              ],
            ),
            if (_oldTestament == null) ...[
              if (last != null) ...[
                _ContinueReadingCard(
                  spot: last,
                  tradition: tradition,
                  onTap: () => context.push('/read/${last.bookId}/${last.chapter}?v=${last.verse}'),
                ),
                const SizedBox(height: 8),
              ],
              const SectionHeader('Популярное'),
              for (final (id, ch, title, sub, icon, pastel) in popular)
                Builder(builder: (context) {
                  final spot = progress[id];
                  final resumeCh = spot?.chapter ?? ch;
                  final resumeV = spot?.verse ?? 1;
                  final book = bookById(id);
                  final subtitle = spot == null
                      ? sub
                      : 'Продолжить · ${chapterTitle(book, resumeCh, tradition)}:$resumeV';
                  return ListRowCard(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    leading: PastelIcon(icon, pastel, size: 50, square: true),
                    title: title,
                    subtitle: subtitle,
                    onTap: () => context.push('/read/$id/$resumeCh?v=$resumeV'),
                  );
                }),
            ] else ...[
              SectionHeader(_oldTestament! ? 'Ветхий Завет' : 'Новый Завет'),
              GroupCard(
                children: [
                  for (final b in _oldTestament! ? ot : nt)
                    ListRowCard(
                      title: b.name,
                      subtitle: '${b.chapters} ${_plural(b.chapters)}',
                      onTap: () => context.go('/bible/${b.id}'),
                    ),
                ],
              ),
            ],
            ],
          ] else if (ref.watch(readerMarksProvider).isNotEmpty) ...[
            GroupCard(
              children: [
                for (final e in ref.watch(readerMarksProvider).entries)
                  ListRowCard(
                    leading: PastelIcon(
                      e.value.bookmarked ? PhosphorIconsRegular.bookmarkSimple : (e.value.liked ? PhosphorIconsRegular.heart : PhosphorIconsRegular.paintBrush),
                      e.value.bookmarked ? Pastel.honey : (e.value.liked ? Pastel.rose : Pastel.sand),
                      size: 42,
                      square: true,
                    ),
                    title: chapterTitle(bookById(e.key.split(':')[0]), int.parse(e.key.split(':')[1]), tradition),
                    subtitle: [
                      if (e.value.bookmarked) 'закладка',
                      if (e.value.liked) 'нравится',
                      if (e.value.highlights.isNotEmpty) 'выделено стихов: ${e.value.highlights.length}',
                    ].join(' · '),
                    onTap: () => context.push('/read/${e.key.replaceAll(':', '/')}'),
                  ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 50),
            Icon(PhosphorIconsRegular.bookmarkSimple, size: 52, color: c.gold.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text('Здесь появятся ваши закладки,\nвыделения и заметки', textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: c.textMuted)),
            const SizedBox(height: 6),
            Text('Нажмите на стих во время чтения', textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: c.textMuted)),
          ],
        ],
      ),
    );
  }

  void _showTranslation(BuildContext context, Tradition t) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Перевод', style: context.text.titleLarge),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Синодальный перевод'),
                  subtitle: const Text('73 книги, работает без интернета'),
                  trailing: Icon(PhosphorIconsRegular.check, color: context.colors.goldStrong),
                ),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: false,
                  title: Text('Церковнославянский'),
                  subtitle: Text('В следующей версии'),
                ),
              ],
            ),
          ),
        ),
      );

  static String _plural(int n) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return 'глава';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'главы';
    return 'глав';
  }
}

class _TestamentCard extends StatelessWidget {
  const _TestamentCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.pastel,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final int count;
  final IconData icon;
  final Pastel pastel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Color.lerp(pastel.bg.first, c.surface, 0.35),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: selected ? c.gold : c.border, width: selected ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: pastel.fg, size: 34),
              const SizedBox(height: 10),
              Text(title, style: context.text.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
              const SizedBox(height: 2),
              Text('$count книг', style: context.text.bodySmall?.copyWith(color: c.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.spot, required this.tradition, required this.onTap});
  final ReadingSpot spot;
  final Tradition tradition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final book = bookById(spot.bookId);
    final where = '${chapterTitle(book, spot.chapter, tradition)}:${spot.verse}';
    return AppCard(
      elevated: true,
      color: c.surfaceWarm,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      child: Row(
        children: [
          PastelIcon(PhosphorIconsRegular.bookOpen, Pastel.honey, size: 48, square: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Продолжить чтение', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(where, style: t.bodySmall?.copyWith(color: c.textMuted, fontSize: 13)),
              ],
            ),
          ),
          Icon(PhosphorIconsRegular.caretRight, color: c.goldStrong, size: 22),
        ],
      ),
    );
  }
}
