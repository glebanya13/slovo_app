import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/ai_gate.dart';
import '../../core/app_actions.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// AI-01 — «Спросить» (в макете отсутствует, сделан в его стиле).
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key});

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final _input = TextEditingController();

  static const _suggestions = [
    'Почему Бог допускает страдания?',
    'Что такое Троица?',
    'Как простить человека, который меня обидел?',
    'Почему христиане молятся святым?',
  ];

  @override
  void initState() {
    super.initState();
    // Прогрев распознавания речи — иначе «Поговорить голосом» долго стартует.
    unawaited(warmSpeechToText());
  }

  Future<void> _ask(String q) async {
    if (q.trim().isEmpty) return;
    if (!await ensureAiConsent(context, ref)) return;
    _input.clear();
    if (!mounted) return;
    context.push('/chat?q=${Uri.encodeComponent(q.trim())}');
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final s = ref.watch(sessionProvider);
    final history = ref.watch(chatHistoryProvider);

    return Scaffold(
      appBar: appHeader(context, 'Спросить', actions: [
          IconButton(
            tooltip: s.privateAi ? 'Приватный режим включён' : 'Приватный режим',
            onPressed: () {
              final next = !s.privateAi;
              ref.read(sessionProvider.notifier).update((x) => x.copyWith(privateAi: next));
              if (next) ref.read(chatHistoryProvider.notifier).clear();
            },
            icon: Icon(s.privateAi ? PhosphorIconsRegular.lock : PhosphorIconsRegular.lockOpen, color: s.privateAi ? c.goldStrong : null),
          ),
      ]),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          AppCard(
            color: c.surfaceWarm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const IconBadge(PhosphorIconsRegular.sparkle),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Помощник в вопросах веры', style: t.titleMedium)),
                ]),
                const SizedBox(height: 10),
                Text(
                  'Я могу помочь изучать Писание, молиться, разбирать вопросы веры, готовиться к исповеди и просто поговорить. '
                  'Отвечаю с учётом традиции: ${s.tradition.title.toLowerCase()}.',
                  style: t.bodyMedium,
                ),
                if (s.privateAi) ...[
                  const SizedBox(height: 8),
                  Text('Приватный режим: беседы не сохраняются', style: t.bodySmall?.copyWith(color: c.goldStrong)),
                ],
              ],
            ),
          ),
          if (history.isNotEmpty && !s.privateAi) ...[
            const SizedBox(height: 12),
            AppCard(
              elevated: true,
              color: c.surface,
              onTap: () => context.push('/chat'),
              child: Row(
                children: [
                  Icon(PhosphorIconsRegular.chatCircleDots, color: c.goldStrong),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Продолжить беседу', style: t.titleMedium),
                        Text(
                          '${history.where((m) => m.fromUser).length} сообщений сохранено на телефоне',
                          style: t.bodySmall?.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(PhosphorIconsRegular.caretRight, color: c.textMuted),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          ChatInput(
            controller: _input,
            onSend: () => _ask(_input.text),
            onMic: () async {
              if (await dictateInto(context, _input) && mounted) _ask(_input.text);
            },
          ),
          const SectionHeader('Частые вопросы'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final q in _suggestions) SoftChip(label: q, onTap: () => _ask(q))],
          ),
          const SectionHeader('Режимы'),
          FlatSection(
            children: [
              ListRowCard(
                leading: IconBadge(PhosphorIconsRegular.arrowsLeftRight, tint: c.goldStrong),
                title: 'Православие и католицизм',
                subtitle: 'Нейтральное сравнение учений и практик',
                onTap: () => _ask('Сравни: что такое Евхаристия в православии и католицизме?'),
              ),
              ListRowCard(
                leading: IconBadge(PhosphorIconsRegular.flowerLotus, tint: c.gold),
                title: 'Подготовка к исповеди',
                subtitle: 'Хранится только на этом телефоне',
                onTap: () => context.push('/confession'),
              ),
              ListRowCard(
                leading: IconBadge(PhosphorIconsRegular.waveform, tint: c.goldStrong),
                title: 'Поговорить голосом',
                subtitle: 'Диктовка вопроса',
                onTap: () async {
                  if (await dictateInto(context, _input) && mounted) _ask(_input.text);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton.icon(
              onPressed: () => context.push('/help-now'),
              icon: Icon(PhosphorIconsRegular.lifebuoy, color: c.danger),
              label: Text('Мне нужна помощь прямо сейчас', style: TextStyle(color: c.danger)),
            ),
          ),
        ],
      ),
    );
  }
}
