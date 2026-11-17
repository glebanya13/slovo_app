import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';

/// HOME-02 — вечерний разбор дня (раздел 12.2 ТЗ).
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  static const _questions = [
    'За что ты благодарен сегодня?',
    'Кого ты мог сегодня обидеть?',
    'Кого тебе трудно простить?',
    'Что хорошего ты сделал?',
    'Что хочешь изменить завтра?',
  ];

  int _step = 0;
  final _answers = List.generate(_questions.length, (_) => TextEditingController());

  @override
  void dispose() {
    for (final a in _answers) {
      a.dispose();
    }
    super.dispose();
  }

  void _finish() {
    final text = [
      for (var i = 0; i < _questions.length; i++)
        if (_answers[i].text.trim().isNotEmpty) '${_questions[i]}\n${_answers[i].text.trim()}',
    ].join('\n\n');
    if (text.isNotEmpty) {
      ref.read(journalProvider.notifier).add(JournalEntry(date: DateTime.now(), text: text, mood: 3));
    }
    ref.read(practicesProvider.notifier).toggle('evening');
    setState(() => _step = _questions.length);
  }

  @override
  Widget build(BuildContext context) {
    final last = _step >= _questions.length;

    return Theme(
      data: AppTheme.dark(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: appHeader(context, 'Как прошёл твой день?'),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: last
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Вечерняя молитва', style: context.text.headlineSmall),
                        const SizedBox(height: 16),
                        Text(
                          'Господи, благодарю Тебя за прошедший день. Прости мне всё, чем я согрешил словом, делом и помышлением. Сохрани меня в эту ночь и дай мне мирный сон. Аминь.',
                          style: context.text.bodyLarge?.copyWith(fontSize: 19, height: 1.6),
                        ),
                        const Spacer(),
                        Text('Ответы сохранены в дневник', style: context.text.bodySmall?.copyWith(color: context.colors.textMuted)),
                        const SizedBox(height: 12),
                        PrimaryButton(label: 'Спокойной ночи', onPressed: () => context.pop()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: (_step + 1) / _questions.length,
                          color: context.colors.gold,
                          backgroundColor: context.colors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 28),
                        Text(_questions[_step], style: context.text.headlineSmall),
                        const SizedBox(height: 16),
                        TextField(
                          key: ValueKey(_step),
                          controller: _answers[_step],
                          maxLines: 5,
                          autofocus: true,
                          decoration: const InputDecoration(hintText: 'Напиши пару слов — или пропусти'),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => _step == _questions.length - 1 ? _finish() : setState(() => _step++),
                              child: const Text('Пропустить'),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 160,
                              child: PrimaryButton(
                                label: _step == _questions.length - 1 ? 'Готово' : 'Дальше',
                                onPressed: () => _step == _questions.length - 1 ? _finish() : setState(() => _step++),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
