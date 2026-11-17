import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/ai_gate.dart';
import '../../core/app_actions.dart';
import '../../core/gemini_service.dart';
import '../../core/smooth_stream.dart';
import '../../design/listen_sheet.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// PR-05 — создать молитву с AI (демо-генерация).
class CreatePrayerScreen extends ConsumerStatefulWidget {
  const CreatePrayerScreen({super.key});

  @override
  ConsumerState<CreatePrayerScreen> createState() => _CreatePrayerScreenState();
}

class _CreatePrayerScreenState extends ConsumerState<CreatePrayerScreen> {
  static const _occasions = [
    'За здоровье',
    'За семью',
    'За ребёнка',
    'За родителей',
    'О прощении',
    'О защите',
    'Благодарность',
    'Перед важным событием',
    'В трудный момент',
    'Об умершем',
    'О мире',
  ];

  final _about = TextEditingController();
  String _occasion = 'За семью';
  int _length = 0;
  bool _loading = false;
  String? _result;
  SmoothStreamBuffer? _reveal;
  StreamSubscription<String>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    _reveal?.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!await ensureAiConsent(context, ref)) return;
    _sub?.cancel();
    _reveal?.dispose();
    setState(() {
      _loading = true;
      _result = '';
    });
    final about = _about.text.trim();
    final length = const [
      'короткую (3–4 предложения)',
      'среднюю (6–8 предложений)',
      'длинную (10–14 предложений)',
    ][_length];
    final prompt =
        'Составь $length личную молитву. Повод: «$_occasion». '
        '${about.isEmpty ? '' : 'О ком или о чём: «$about». '}'
        'Пиши от первого лица, в стиле молитв моей традиции, обращаясь к Богу, закончи словом «Аминь». '
        'Не добавляй фактов и чувств, которых я не называл, и не обещай результата. '
        'Выведи только текст молитвы, без заголовка и пояснений.';

    final done = Completer<void>();
    _reveal = SmoothStreamBuffer(
      onUpdate: () {
        if (!mounted) return;
        setState(() => _result = _reveal!.visible);
      },
      onCaughtUp: () {
        if (!mounted) return;
        setState(() => _loading = false);
        if (!done.isCompleted) done.complete();
      },
    );

    try {
      _sub = ref
          .read(geminiServiceProvider)
          .streamReply(
            history: [ChatTurn(fromUser: true, text: prompt)],
            tradition: ref.read(sessionProvider).specialDataConsent
                ? ref.read(sessionProvider).tradition
                : Tradition.undecided,
          )
          .listen(
            (chunk) => _reveal?.add(chunk),
            onError: (Object e) {
              _reveal?.dispose();
              _reveal = null;
              if (!mounted) return;
              setState(() {
                _result = null;
                _loading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    e is GeminiException
                        ? e.message
                        : 'Не удалось создать молитву',
                  ),
                ),
              );
              if (!done.isCompleted) done.complete();
            },
            onDone: () => _reveal?.markStreamDone(),
            cancelOnError: true,
          );
      await done.future;
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() {
        _result = null;
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      appBar: appHeader(context, 'Создать молитву'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text('Повод', style: t.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in _occasions)
                SoftChip(
                  label: o,
                  selected: o == _occasion,
                  onTap: () => setState(() => _occasion = o),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('О ком или о чём молитва', style: t.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _about,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Например: о сыне, у него экзамен',
              suffixIcon: IconButton(
                tooltip: 'Сказать голосом',
                onPressed: () => dictateInto(context, _about),
                icon: Icon(
                  PhosphorIconsRegular.microphone,
                  color: c.goldStrong,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Длина', style: t.titleMedium),
          const SizedBox(height: 8),
          SegmentedTabs(
            labels: const ['Короткая', 'Средняя', 'Длинная'],
            index: _length,
            onChanged: (i) => setState(() => _length = i),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: _loading ? 'Составляю…' : 'Создать',
            icon: PhosphorIconsRegular.sparkle,
            onPressed: _loading ? null : _generate,
          ),
          if (_result != null) ...[
            const SizedBox(height: 22),
            AppCard(
              color: c.aiTint,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(_occasion, style: t.titleMedium)),
                      const AiBadge(label: 'составлено с AI'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _result!,
                    style: t.bodyLarge?.copyWith(
                      fontFamily: t.titleLarge?.fontFamily,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Изменить',
                    onPressed: _generate,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SecondaryButton(
                    label: 'Озвучить',
                    onPressed: _loading
                        ? null
                        : () => showListenSheet(
                            context,
                            ref,
                            title: _occasion,
                            text: _result!,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Сохранить в мои молитвы',
              onPressed: _loading
                  ? null
                  : () {
                      ref
                          .read(myPrayersProvider.notifier)
                          .add(
                            MyPrayer(
                              title: _occasion,
                              text: _result!,
                              aiGenerated: true,
                            ),
                          );
                      context.pop();
                    },
            ),
          ],
        ],
      ),
    );
  }
}
