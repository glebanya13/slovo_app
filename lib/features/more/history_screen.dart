import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/mock_data.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// HIST-01 — «История пути» в визуале экрана «Мои достижения» (макет, экран 13).
/// По ТЗ (раздел 14): только факты пути, без очков, серий и рейтингов.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final s = ref.watch(sessionProvider);
    final journal = ref.watch(journalProvider);
    final prayers = ref.watch(myPrayersProvider);
    final marks = ref.watch(readerMarksProvider);
    final joined = s.joinedAt ?? DateTime.now();

    final milestones = [
      (PhosphorIconsRegular.flag, Pastel.honey, 'Первые шаги', true),
      (PhosphorIconsRegular.bookOpen, Pastel.sky, 'Чтение Писания', marks.isNotEmpty),
      (PhosphorIconsRegular.notePencil, Pastel.lavender, 'Первая запись', journal.isNotEmpty),
      (PhosphorIconsRegular.flame, Pastel.peach, 'Своя молитва', prayers.isNotEmpty),
      (PhosphorIconsRegular.check, Pastel.mint, 'Вечерний разбор', journal.any((e) => e.text.contains('благодарен'))),
      (PhosphorIconsRegular.heart, Pastel.rose, 'Молитва за близких', true),
    ].where((m) => m.$4).toList();

    return Scaffold(
      appBar: appHeader(context, 'История пути'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          SegmentedTabs(labels: const ['Вехи', 'Прочитано'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
          const SizedBox(height: 16),
          if (_tab == 0) ...[
            AppCard(
              gradient: const LinearGradient(colors: [Color(0xFFFBF1E3), Color(0xFFF4E4CB)]),
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: c.goldGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                      border: Border.all(color: const Color(0xFFF6DDA8), width: 5),
                      boxShadow: [BoxShadow(color: c.gold.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: const Icon(PhosphorIconsRegular.sun, color: Colors.white, size: 38),
                  ),
                  const SizedBox(width: 20),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('с ${joined.day} ${monthGen[joined.month - 1]}', style: t.displaySmall?.copyWith(fontSize: 30)),
                        const SizedBox(height: 2),
                        Text('вы идёте этим путём', style: t.bodyMedium?.copyWith(color: c.text.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 18,
              childAspectRatio: 0.9,
              children: [
                for (final (icon, pastel, label, _) in milestones)
                  Column(
                    children: [
                      PastelIcon(icon, pastel, size: 76),
                      const SizedBox(height: 8),
                      Text(label, textAlign: TextAlign.center, style: t.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
              ],
            ),
          ] else ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Главы с отметками', style: t.titleMedium),
                  const SizedBox(height: 12),
                  if (marks.isEmpty)
                    Text('Пока пусто — отмечайте главы сердечком или закладкой.', style: t.bodyMedium?.copyWith(color: c.textMuted))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final k in marks.keys)
                          Chip(
                            label: Text(chapterTitle(bookById(k.split(':')[0]), int.parse(k.split(':')[1]), s.tradition)),
                            backgroundColor: c.surfaceWarm,
                            side: BorderSide.none,
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const QuoteCard(text: 'Верный в малом и во многом верен', reference: 'Луки 16:10'),
          const SizedBox(height: 14),
          Text(
            'Здесь нет очков и рейтингов: духовная жизнь не измеряется цифрами.',
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
