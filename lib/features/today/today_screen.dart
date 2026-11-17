import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/brand.dart';
import '../../data/mock_data.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// HOME-01 — главный экран: бренд, продолжение чтения и планы.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  static const _plans = [
    (id: 'mark', ch: 1, title: 'Евангелие от Марка', sub: '16 дней · по главе в день'),
    (id: 'matt', ch: 5, title: 'Нагорная проповедь', sub: 'Мф 5–7 · учение Иисуса'),
    (id: 'ps', ch: 22, title: 'Псалмы утешения', sub: 'Начните с псалма 22'),
    (id: 'john', ch: 1, title: 'Евангелие от Иоанна', sub: '21 день · Слово и жизнь'),
  ];

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final Animation<double> _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slide = Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(_fade);

  @override
  void initState() {
    super.initState();
    _enter.forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final session = ref.watch(sessionProvider);
    final done = ref.watch(practicesProvider);
    final last = ref.watch(lastReadingProvider);
    final now = DateTime.now();
    final catholic = session.tradition == Tradition.catholic;
    final tradition = session.tradition;

    final practices = [
      _Practice('morning', PhosphorIconsRegular.cloudSun, Pastel.honey, 'Утренняя молитва',
          catholic ? 'Отче наш, Радуйся, Мария' : 'Утреннее правило', '/pray/${catholic ? 'our_father' : 'publican'}'),
      _Practice(
        'gospel',
        PhosphorIconsRegular.bookOpen,
        Pastel.peach,
        'Читать Писание',
        last == null ? 'Открыть Библию' : 'Продолжить · ${chapterTitle(bookById(last.bookId), last.chapter, tradition)}:${last.verse}',
        last == null ? '/bible' : '/read/${last.bookId}/${last.chapter}?v=${last.verse}',
      ),
      const _Practice('reflection', PhosphorIconsRegular.flowerLotus, Pastel.mint, 'Размышление', 'Спросить AI-помощника', '/ask'),
      const _Practice('loved', PhosphorIconsRegular.heart, Pastel.rose, 'Молитва за близких', 'Молитва Господня', '/pray/our_father'),
      const _Practice('evening', PhosphorIconsRegular.moon, Pastel.sky, 'Вечерний разбор', 'Благодарность и молитва на ночь', '/review'),
    ];

    final greeting = switch (now.hour) {
      < 5 => 'Доброй ночи',
      < 12 => 'Доброе утро',
      < 18 => 'Добрый день',
      _ => 'Добрый вечер',
    };

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: ListView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, 28),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CrossMark(size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppBrand.name, style: t.headlineMedium?.copyWith(fontSize: 30, height: 1)),
                          const SizedBox(height: 2),
                          Text(
                            session.name.isEmpty ? greeting : '$greeting, ${session.name}',
                            style: t.bodyMedium?.copyWith(color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/more'),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.surface, width: 2),
                        ),
                        child: const Photo('avatar_landscape', radius: 24, width: 46, height: 46),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  formatDate(now),
                  style: t.bodySmall?.copyWith(color: c.goldStrong, fontWeight: FontWeight.w500),
                ),
                if (last != null) ...[
                  const SizedBox(height: AppSpace.lg),
                  AppCard(
                    elevated: true,
                    onTap: () => context.push('/read/${last.bookId}/${last.chapter}?v=${last.verse}'),
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                    color: c.surfaceWarm,
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
                              Text(
                                '${chapterTitle(bookById(last.bookId), last.chapter, tradition)}:${last.verse}',
                                style: t.bodySmall?.copyWith(color: c.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Icon(PhosphorIconsRegular.caretRight, color: c.goldStrong, size: 22),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.lg),
                QuoteCard(
                  text: 'Предай Господу дела твои, и предприятия твои совершатся',
                  reference: 'Притчи 16:3',
                  onTap: () => context.push('/chat?q=${Uri.encodeComponent('Что значит «Предай Господу дела твои»?')}'),
                ),
                const SizedBox(height: AppSpace.xxl),
                Row(
                  children: [
                    Expanded(
                      child: ActionTile(
                        icon: PhosphorIconsRegular.bookOpen,
                        label: 'Библия',
                        pastel: Pastel.peach,
                        onTap: () => last == null
                            ? context.go('/bible')
                            : context.push('/read/${last.bookId}/${last.chapter}?v=${last.verse}'),
                      ),
                    ),
                    Expanded(child: ActionTile(icon: PhosphorIconsRegular.flame, label: 'Молитва', pastel: Pastel.mint, onTap: () => context.go('/prayer'))),
                    Expanded(child: ActionTile(icon: PhosphorIconsRegular.chatCircle, label: 'Спросить', pastel: Pastel.sky, onTap: () => context.go('/ask'))),
                    Expanded(child: ActionTile(icon: PhosphorIconsRegular.notePencil, label: 'Дневник', pastel: Pastel.honey, onTap: () => context.go('/more/journal'))),
                  ],
                ),
                const SectionHeader('Планы чтения'),
                for (final p in TodayScreen._plans) ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => context.push('/read/${p.id}/${p.ch}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          PastelIcon(PhosphorIconsRegular.books, Pastel.peach, size: 44, square: true),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.title, style: t.titleMedium),
                                const SizedBox(height: 2),
                                Text(p.sub, style: t.bodySmall?.copyWith(color: c.textMuted)),
                              ],
                            ),
                          ),
                          Icon(PhosphorIconsRegular.caretRight, color: c.textMuted.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  ),
                  if (p != TodayScreen._plans.last) Divider(height: 1, color: c.border.withValues(alpha: 0.8)),
                ],
                SectionHeader('Сегодня для тебя', action: 'Смотреть все', onAction: () => context.go('/prayer')),
                SizedBox(
                  height: 168,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: [
                      _FeatureCard(
                        image: 'valley_sunrise',
                        title: 'Начни день с Богом',
                        subtitle: 'Утренняя молитва',
                        onTap: () => context.push('/pray/${catholic ? 'our_father' : 'publican'}'),
                      ),
                      _FeatureCard(
                        image: 'plan_1',
                        title: last == null ? 'Библия' : 'Продолжить чтение',
                        subtitle: last == null ? 'Читать Писание' : chapterTitle(bookById(last.bookId), last.chapter, tradition),
                        onTap: () => last == null
                            ? context.go('/bible')
                            : context.push('/read/${last.bookId}/${last.chapter}?v=${last.verse}'),
                      ),
                      _FeatureCard(image: 'plan_4', title: 'Вечерняя молитва', subtitle: 'Завершить день с миром', onTap: () => context.push('/review')),
                    ],
                  ),
                ),
                SectionHeader('Практики дня', action: '${done.length} из ${practices.length}'),
                for (final p in practices) ...[
                  ListRowCard(
                    onTap: () {
                      if (p.route.startsWith('/read/') || p.route.startsWith('/pray/') || p.route == '/review') {
                        context.push(p.route);
                      } else {
                        context.go(p.route);
                      }
                    },
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                    leading: PastelIcon(p.icon, p.pastel, size: 44, square: true),
                    title: p.title,
                    subtitle: p.subtitle,
                    trailing: IconButton(
                      tooltip: done.contains(p.id) ? 'Отметить как невыполненное' : 'Отметить как выполненное',
                      onPressed: () => ref.read(practicesProvider.notifier).toggle(p.id),
                      icon: Icon(
                        done.contains(p.id) ? PhosphorIconsRegular.checkCircle : PhosphorIconsRegular.circle,
                        color: done.contains(p.id) ? c.gold : c.border,
                        size: 28,
                      ),
                    ),
                  ),
                  if (p != practices.last) Divider(height: 1, color: c.border.withValues(alpha: 0.8)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Practice {
  const _Practice(this.id, this.icon, this.pastel, this.title, this.subtitle, this.route);
  final String id;
  final IconData icon;
  final Pastel pastel;
  final String title;
  final String subtitle;
  final String route;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.image, required this.title, required this.subtitle, required this.onTap});
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: SizedBox(
            width: 260,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Photo(image, radius: 0),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB3000000)],
                      stops: [0.4, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: t.titleMedium?.copyWith(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: t.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
