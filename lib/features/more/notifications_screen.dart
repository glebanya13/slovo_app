import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// NOTIF-01 — список напоминаний и статус уведомлений.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final s = ref.watch(sessionProvider);
    final morning = TimeOfDay(hour: s.morningHour, minute: s.morningMinute).format(context);
    final evening = TimeOfDay(hour: s.eveningHour, minute: s.eveningMinute).format(context);

    return Scaffold(
      appBar: appHeader(context, 'Уведомления'),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          AppCard(
            color: c.surfaceWarm,
            child: Text(
              s.pushEnabled
                  ? 'Локальные напоминания включены. Рассылки от приложения (если настроены) приходят через push.'
                  : 'Уведомления выключены. Включите их в настройках, чтобы получать утренние и вечерние напоминания.',
              style: t.bodyMedium,
            ),
          ),
          const SectionHeader('Напоминания'),
          GroupCard(
            children: [
              ListRowCard(
                leading: PastelIcon(PhosphorIconsRegular.cloudSun, Pastel.honey, size: 44, square: true),
                title: 'Утреннее напоминание',
                subtitle: s.morningReminder && s.pushEnabled ? 'Каждый день в $morning' : 'Выключено',
                onTap: () => context.push('/more/settings'),
              ),
              ListRowCard(
                leading: PastelIcon(PhosphorIconsRegular.moon, Pastel.lavender, size: 44, square: true),
                title: 'Вечернее напоминание',
                subtitle: s.eveningReminder && s.pushEnabled ? 'Каждый день в $evening' : 'Выключено',
                onTap: () => context.push('/more/settings'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Нажмите на уведомление, чтобы открыть молитву или вечерний разбор.',
            style: t.bodySmall?.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}
