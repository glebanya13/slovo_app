import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// PROF-01 / MORE-01 — Профиль.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final s = ref.watch(sessionProvider);
    final journal = ref.watch(journalProvider).length;
    final prayers = ref.watch(myPrayersProvider).length;
    final bookmarks = ref.watch(readerMarksProvider).values.where((m) => m.bookmarked).length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 4, AppSpace.page, 28),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(tooltip: 'Настройки', onPressed: () => context.go('/more/settings'), icon: const Icon(PhosphorIconsRegular.gear)),
            ),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: c.surface, width: 3),
                  ),
                  child: const Photo('avatar_landscape', radius: 44, width: 88, height: 88),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.isGuest ? 'Гость' : (s.name.isEmpty ? 'Мой профиль' : s.name), style: t.headlineSmall),
                      const SizedBox(height: 4),
                      Text('Иду вместе с Богом', style: t.bodyMedium?.copyWith(color: c.textMuted)),
                      const SizedBox(height: 2),
                      Text(s.tradition.title, style: t.bodySmall?.copyWith(color: c.goldStrong)),
                    ],
                  ),
                ),
              ],
            ),
            if (s.isGuest) ...[
              const SizedBox(height: 14),
              PrimaryButton(label: 'Войти, чтобы не потерять данные', onPressed: () => context.push('/auth')),
            ],
            const SizedBox(height: AppSpace.xxl),
            Row(
              children: [
                _Stat(value: '$journal', label: 'записей\nв дневнике'),
                Container(width: 1, height: 40, color: c.border),
                _Stat(value: '$prayers', label: 'моих\nмолитв'),
                Container(width: 1, height: 40, color: c.border),
                _Stat(value: '$bookmarks', label: 'закладок\nв Библии'),
              ],
            ),
            const SizedBox(height: AppSpace.xxl),
            FlatSection(
              children: [
                SettingsTile(icon: PhosphorIconsRegular.chartLine, iconColor: c.gold, title: 'История пути', onTap: () => context.go('/more/history')),
                SettingsTile(icon: PhosphorIconsRegular.notePencil, iconColor: c.gold, title: 'Мой дневник', onTap: () => context.go('/more/journal')),
                SettingsTile(icon: PhosphorIconsRegular.flowerLotus, iconColor: c.gold, title: 'Подготовка к исповеди', onTap: () => context.push('/confession')),
                SettingsTile(icon: PhosphorIconsRegular.gear, iconColor: c.gold, title: 'Настройки', onTap: () => context.go('/more/settings')),
                SettingsTile(icon: PhosphorIconsRegular.bell, iconColor: c.gold, title: 'Уведомления', onTap: () => context.push('/notifications')),
                SettingsTile(icon: PhosphorIconsRegular.info, iconColor: c.gold, title: 'Помощь и поддержка', onTap: () => context.push('/more/support')),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: () => context.push('/help-now'),
                icon: Icon(PhosphorIconsRegular.lifebuoy, color: c.danger, size: 20),
                label: Text('Мне нужна помощь прямо сейчас', style: TextStyle(color: c.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value, style: context.text.headlineSmall),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: context.text.bodySmall?.copyWith(color: context.colors.textMuted, fontSize: 11.5)),
          ],
        ),
      );
}
