import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/app_actions.dart';
import '../../core/brand.dart';
import '../../design/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Помощь и поддержка.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      appBar: appHeader(context, 'Помощь и поддержка'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          AppCard(
            color: c.surfaceWarm,
            child: Text(
              'Если вам тяжело прямо сейчас — откройте экран экстренной помощи. '
              'По техническим вопросам напишите нам на почту.',
              style: t.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
          GroupCard(
            children: [
              ListRowCard(
                leading: IconBadge(PhosphorIconsRegular.lifebuoy, tint: c.danger),
                title: 'Мне нужна помощь сейчас',
                subtitle: 'Кризисный экран с телефонами доверия',
                onTap: () => context.push('/help-now'),
              ),
              ListRowCard(
                leading: const IconBadge(PhosphorIconsRegular.envelope),
                title: 'Написать в поддержку',
                subtitle: AppBrand.supportEmail,
                onTap: () => sendEmail(
                  context,
                  to: AppBrand.supportEmail,
                  subject: '${AppBrand.name}: поддержка',
                ),
              ),
              ListRowCard(
                leading: const IconBadge(PhosphorIconsRegular.info),
                title: 'О приложении',
                onTap: () => context.push('/more/about'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
