import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// CONF-01 — вступление к подготовке к исповеди (раздел 8 ТЗ).
class ConfessionIntroScreen extends ConsumerWidget {
  const ConfessionIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final listCount = ref.watch(confessionListProvider).length;
    return Scaffold(
      appBar: appHeader(context, 'Подготовка к исповеди'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          AppCard(
            color: c.surfaceWarm,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(PhosphorIconsRegular.info, color: c.goldStrong),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Важно', style: t.titleMedium)),
                ]),
                const SizedBox(height: 8),
                Text(
                  'Это личная беседа с AI-помощником. Она не является Таинством Исповеди и не заменяет исповедь перед священником.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(PhosphorIconsRegular.deviceMobile, size: 18, color: c.textMuted),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Записи хранятся только на этом устройстве', style: t.bodySmall?.copyWith(color: c.textMuted))),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GroupCard(
            children: [
              ListRowCard(
                leading: const IconBadge(PhosphorIconsRegular.listChecks),
                title: 'Подготовиться по темам',
                subtitle: 'Вопросы для испытания совести · без AI',
                onTap: () => context.push('/confession/examine'),
              ),
              ListRowCard(
                leading: const IconBadge(PhosphorIconsRegular.chatsCircle, tint: Color(0xFF7C6BB0)),
                title: 'Разговор по душам',
                subtitle: 'Спокойно рассказать, что на сердце',
                onTap: () => context.push('/chat?q=${Uri.encodeComponent('Хочу спокойно рассказать, что у меня на сердце, и подготовиться к исповеди. Выслушай и помоги разобраться без осуждения.')}'),
              ),
              ListRowCard(
                leading: const IconBadge(PhosphorIconsRegular.fileText, tint: Color(0xFF4F8A6B)),
                title: 'Мой список к исповеди',
                subtitle: listCount == 0 ? 'Пока пусто' : '$listCount пунктов',
                onTap: () => context.push('/confession/list'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Для Таинства Исповеди обратитесь к священнику.',
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

/// CONF-02 — подготовка по темам. Вопросы — демо, в продукте их утверждает консультант традиции.
class ExamineScreen extends ConsumerStatefulWidget {
  const ExamineScreen({super.key});

  @override
  ConsumerState<ExamineScreen> createState() => _ExamineScreenState();
}

class _ExamineScreenState extends ConsumerState<ExamineScreen> {
  final _checked = <String>{};

  Map<String, List<String>> _groups(Tradition t) => t == Tradition.catholic
      ? const {
          'Бог (1–3 заповеди)': ['Пропускал воскресную Мессу без серьёзной причины', 'Не молился, забывал о Боге', 'Произносил имя Божие без благоговения'],
          'Ближние (4–10 заповеди)': ['Был неуважителен к родителям', 'Гневался, держал обиду', 'Говорил неправду, осуждал', 'Завидовал'],
          'Заповеди Церкви': ['Не соблюдал дни поста и воздержания'],
        }
      : const {
          'Перед Богом': ['Оставлял молитву, молился рассеянно', 'Не благодарил Бога', 'Пропускал воскресную службу'],
          'Перед ближними': ['Гневался, раздражался', 'Осуждал других', 'Говорил неправду', 'Не прощал обиды'],
          'Перед собой': ['Предавался унынию', 'Был невоздержан', 'Тратил время впустую'],
        };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final groups = _groups(ref.watch(sessionProvider).tradition);
    return Scaffold(
      appBar: appHeader(context, 'Испытание совести'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          Text('Отметьте то, о чём хотите сказать на исповеди. Можно дописать своими словами в списке.',
              style: context.text.bodyMedium?.copyWith(color: c.textMuted)),
          for (final e in groups.entries) ...[
            SectionHeader(e.key),
            GroupCard(
              children: [
                for (final q in e.value)
                  CheckboxListTile(
                    value: _checked.contains(q),
                    activeColor: c.goldStrong,
                    onChanged: (v) => setState(() => v! ? _checked.add(q) : _checked.remove(q)),
                    title: Text(q),
                  ),
              ],
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: PrimaryButton(
            label: _checked.isEmpty ? 'Отметьте пункты' : 'Добавить в список (${_checked.length})',
            onPressed: _checked.isEmpty
                ? null
                : () {
                    ref.read(confessionListProvider.notifier).addAll(_checked);
                    context.pushReplacement('/confession/list');
                  },
          ),
        ),
      ),
    );
  }
}

/// CONF-05 — «Мой список к исповеди».
class ConfessionListScreen extends ConsumerWidget {
  const ConfessionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final items = ref.watch(confessionListProvider);
    final n = ref.read(confessionListProvider.notifier);

    return Scaffold(
      appBar: appHeader(context, 'Сказать священнику', actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Удалить навсегда',
              icon: const Icon(PhosphorIconsRegular.trash),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('Удалить навсегда?'),
                    content: const Text('Список и связанные данные будут удалены с этого устройства без возможности восстановления.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Отмена')),
                      TextButton(onPressed: () => Navigator.pop(d, true), child: Text('Удалить', style: TextStyle(color: c.danger))),
                    ],
                  ),
                );
                if (ok == true) n.clear();
              },
            ),
      ]),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Список пуст.\nНачните с подготовки по темам.', textAlign: TextAlign.center, style: t.bodyLarge?.copyWith(color: c.textMuted)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text('Перед разговором со священником я хочу сказать:', style: t.titleMedium),
                const SizedBox(height: 12),
                GroupCard(
                  children: [
                    for (final i in items)
                      ListTile(
                        title: Text(i),
                        trailing: IconButton(tooltip: 'Убрать', icon: const Icon(PhosphorIconsRegular.x), onPressed: () => n.remove(i)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Я был(а) на исповеди',
                  onPressed: () {
                    n.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Слава Богу! Список удалён.'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
