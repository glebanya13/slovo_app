import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme.dart';
import '../../core/app_actions.dart';
import '../../core/brand.dart';
import '../../design/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Экран «О приложении».
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      appBar: appHeader(context, 'О приложении'),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snap) {
          final info = snap.data;
          final version = info == null ? '…' : '${info.version} (${info.buildNumber})';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              const Center(child: CrossMark(size: 48)),
              const SizedBox(height: 16),
              Text(AppBrand.name, textAlign: TextAlign.center, style: t.headlineSmall),
              const SizedBox(height: 6),
              Text('Версия $version', textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.textMuted)),
              const SizedBox(height: 20),
              AppCard(
                color: c.surfaceWarm,
                child: Text(
                  'Приложение помогает читать Писание, молиться и разбирать вопросы веры. '
                  'AI-помощник не является священником и не заменяет Таинства и пастырское попечение.',
                  style: t.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              GroupCard(
                children: [
                  SettingsTile(
                    icon: PhosphorIconsRegular.envelope,
                    title: 'Написать разработчикам',
                    onTap: () => sendEmail(
                      context,
                      to: AppBrand.supportEmail,
                      subject: '${AppBrand.name}: обратная связь',
                    ),
                  ),
                  SettingsTile(
                    icon: PhosphorIconsRegular.lock,
                    title: 'Конфиденциальность',
                    onTap: () => context.push('/legal/privacy'),
                  ),
                  SettingsTile(
                    icon: PhosphorIconsRegular.fileText,
                    title: 'Условия использования',
                    onTap: () => context.push('/legal/terms'),
                  ),
                  SettingsTile(
                    icon: PhosphorIconsRegular.shareNetwork,
                    title: 'Поделиться приложением',
                    onTap: () => shareText(
                      '${AppBrand.name} — чтение Библии, молитвы и спокойные ответы на вопросы веры.',
                      subject: AppBrand.name,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
