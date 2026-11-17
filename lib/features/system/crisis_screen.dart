import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/app_actions.dart';
import '../../design/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// SYS-01 — кризисный экран (раздел 16.3 ТЗ). Работает без сети и без защит.
class CrisisScreen extends StatelessWidget {
  const CrisisScreen({super.key});

  static const _contacts = [
    ('Экстренные службы', '112'),
    ('Детский телефон доверия (Россия)', '8-800-2000-122'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      appBar: appHeader(context, 'Вы не одни'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(
            'Похоже, вам сейчас очень тяжело. Это важно, и вы заслуживаете поддержки.',
            style: t.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Пожалуйста, свяжитесь с тем, кто может помочь прямо сейчас: близким человеком, специалистом или священником. '
            'Если есть непосредственная опасность — позвоните в экстренную службу.',
            style: t.bodyLarge,
          ),
          const SizedBox(height: 20),
          for (final (name, phone) in _contacts) ...[
            AppCard(
              onTap: () => callPhone(context, phone),
              child: Row(
                children: [
                  IconBadge(PhosphorIconsRegular.phone, tint: c.danger),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: t.titleMedium),
                        Text(phone, style: t.titleLarge?.copyWith(color: c.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          SecondaryButton(
            label: 'Написать близкому человеку',
            onPressed: () => shareText(
              'Мне сейчас тяжело. Можешь, пожалуйста, написать или позвонить?',
              subject: 'Мне нужна поддержка',
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            color: c.surfaceWarm,
            child: Text(
              'Господи, будь со мной в этот час. Дай мне сил попросить о помощи и не оставляй меня. Аминь.',
              style: t.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 12),
          Text('Номера телефонов зависят от страны и будут подставляться автоматически.',
              style: t.bodySmall?.copyWith(color: c.textMuted)),
        ],
      ),
    );
  }
}
