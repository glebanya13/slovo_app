import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../app/theme.dart';
import '../state/app_state.dart';
import 'app_actions.dart';
import 'brand.dart';

/// Согласие на передачу данных в Gemini и ElevenLabs.
bool hasAiConsent(WidgetRef ref) => ref.read(sessionProvider).aiConsent;

/// Показывает полное раскрытие и запрашивает согласие.
/// Возвращает true, если согласие уже есть или только что получено.
Future<bool> ensureAiConsent(BuildContext context, WidgetRef ref) async {
  if (hasAiConsent(ref)) return true;
  if (!context.mounted) return false;

  final accepted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) {
      final c = sheet.colors;
      final t = sheet.text;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheet).height * 0.9,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    PhosphorIconsRegular.sparkle,
                    size: 40,
                    color: c.goldStrong,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'Разрешение на AI и озвучку',
                    style: t.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Чтобы ответить на вопрос, создать молитву или озвучить текст, приложение передаёт данные сторонним сервисам. Без разрешения эти функции недоступны.',
                  style: t.bodyMedium?.copyWith(color: c.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                _InfoList(
                  title: 'Что отправляется',
                  style: t.bodyMedium,
                  items: const [
                    'Текст вопроса и предыдущие сообщения текущей беседы.',
                    'Выбранная традиция (сведения о религиозных взглядах), если вы разрешили её хранить.',
                    'Для молитвы — повод и описание, которое вы указали.',
                    'Для объяснения стиха — ссылка и текст стиха.',
                    'Для озвучки — текст, который вы выбрали.',
                    'Технические данные запроса: время, версия приложения, IP-адрес.',
                  ],
                ),
                const SizedBox(height: 14),
                _InfoList(
                  title: 'Кому',
                  style: t.bodyMedium,
                  items: const [
                    'Google LLC (Gemini API) — генерация ответов, молитв и объяснений.',
                    'ElevenLabs — озвучка текста.',
                    'Cloudflare Workers — наш прокси для запросов.',
                    'Firebase (Google) — вход, синхронизация, push и диагностика.',
                  ],
                ),
                const SizedBox(height: 14),
                _InfoList(
                  title: 'Важно',
                  style: t.bodyMedium,
                  items: const [
                    'Мы не добавляем имя, email и контакты в AI-запросы, но если вы сами напишете их, они уйдут провайдеру.',
                    'Не вводите медицинские и другие чувствительные данные, если не хотите их передавать.',
                    'Google и ElevenLabs обрабатывают запросы по своим условиям; сроки хранения и удаление описаны в политике.',
                    'Ответы AI могут содержать ошибки.',
                    'Отозвать разрешение можно в Настройках → Конфиденциальность.',
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheet, true),
                    child: const Text('Разрешить'),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheet, false),
                    child: const Text('Не сейчас'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => openUri(Uri.parse(AppBrand.privacyUrl)),
                    child: const Text('Политика конфиденциальности'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  if (accepted == true) {
    ref
        .read(sessionProvider.notifier)
        .update((s) => s.copyWith(aiConsent: true));
    return true;
  }
  if (context.mounted) {
    showSnack(context, 'AI и озвучка выключены. Включить можно в настройках.');
  }
  return false;
}

class _InfoList extends StatelessWidget {
  const _InfoList({
    required this.title,
    required this.items,
    required this.style,
  });

  final String title;
  final List<String> items;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleMedium),
        const SizedBox(height: 6),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•', style: style?.copyWith(color: c.goldStrong)),
                const SizedBox(width: 8),
                Expanded(child: Text(item, style: style)),
              ],
            ),
          ),
      ],
    );
  }
}
