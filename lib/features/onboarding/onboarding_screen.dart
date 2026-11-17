import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/account.dart';
import '../../core/ai_gate.dart';
import '../../core/local_reminders.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Короткий онбординг (3 шага) + быстрый гостевой вход к Библии.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;
  static const _steps = 3;

  Future<void> _enterGuest() async {
    final n = ref.read(sessionProvider.notifier);
    if (!ref.read(sessionProvider).specialDataConsent) {
      n.update((s) => s.copyWith(tradition: Tradition.undecided));
    }
    n.finishOnboarding(signedIn: false);
    await rescheduleReminders(
      session: ref.read(sessionProvider),
      reminders: ref.read(localReminderProvider),
      push: ref.read(pushServiceProvider),
    );
    if (mounted) context.go('/today');
  }

  void _next() {
    if (_index == _steps - 1) {
      context.go('/auth');
      return;
    }
    _page.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skip() async {
    // Пропуск = сразу читать Библию без аккаунта (Guideline: core content без обязательной регистрации).
    await _enterGuest();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final photoPage = _index == 0;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _page,
            onPageChanged: (i) => setState(() => _index = i),
            physics: _index == 0
                ? const PageScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            children: const [
              _PhotoStep(
                image: 'lake_church',
                title: 'Добро\nпожаловать!',
                text:
                    'Читайте Писание, молитесь и задавайте вопросы о вере. Можно начать без регистрации.',
              ),
              _TraditionStep(),
              _RemindersConsentStep(),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
              child: Row(
                children: [
                  if (_index > 0)
                    IconButton(
                      tooltip: 'Назад',
                      icon: const Icon(
                        PhosphorIconsRegular.caretLeft,
                        size: 20,
                      ),
                      onPressed: () => _page.previousPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: c.text.withValues(alpha: 0.7),
                    ),
                    child: Text(
                      _index == 0 ? 'Читать Библию' : 'Пропустить',
                      style: context.text.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: photoPage
                    ? null
                    : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          c.background.withValues(alpha: 0),
                          c.background,
                          c.background,
                        ],
                        stops: const [0, 0.3, 1],
                      ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(top: 30, bottom: 18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _steps; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i == _index
                                    ? (photoPage ? Colors.white : c.gold)
                                    : (photoPage ? Colors.white54 : c.border),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      PrimaryButton(
                        width: 260,
                        label: _index == _steps - 1
                            ? 'Войти или продолжить'
                            : 'Далее',
                        icon: PhosphorIconsRegular.arrowRight,
                        onPressed: _next,
                      ),
                      if (_index == _steps - 1) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _enterGuest,
                          child: Text(
                            'Читать без аккаунта',
                            style: context.text.bodyMedium?.copyWith(
                              color: c.goldStrong,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Экран с фото на весь экран и заголовком сверху (макет, экраны 2–3).
class _PhotoStep extends StatelessWidget {
  const _PhotoStep({
    required this.image,
    required this.title,
    required this.text,
  });
  final String image;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final h = MediaQuery.sizeOf(context).height;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFDDE6EE), Color(0xFFFBEBD3), Color(0xFFF6DDB8)],
              stops: [0, 0.4, 0.6],
            ),
          ),
        ),
        // Фото — нижняя половина с мягким переходом (Unsplash, см. assets/images/CREDITS.md).
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: h * 0.6,
          child: ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black],
              stops: [0, 0.25],
            ).createShader(r),
            blendMode: BlendMode.dstIn,
            child: Photo(image, radius: 0, alignment: Alignment.center),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 90, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: t.displaySmall?.copyWith(fontSize: 36, height: 1.2),
                ),
                const SizedBox(height: 18),
                Text(
                  text,
                  style: t.bodyLarge?.copyWith(
                    fontSize: 16.5,
                    height: 1.55,
                    color: context.colors.text.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    this.subtitle,
    required this.child,
  });
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => DawnBackground(
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 70, 24, 150),
        children: [
          Text(title, style: context.text.headlineMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: context.text.bodyLarge?.copyWith(
                color: context.colors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 24),
          child,
        ],
      ),
    ),
  );
}

class _TraditionStep extends ConsumerWidget {
  const _TraditionStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(sessionProvider).tradition;
    final c = context.colors;
    return _StepScaffold(
      title: 'Ваша традиция',
      subtitle:
          'Приложение подстроит Библию, календарь, молитвослов и ответы. Изменить можно в любой момент.',
      child: FlatSection(
        children: [
          for (final t in Tradition.values)
            ListRowCard(
              onTap: () async {
                final n = ref.read(sessionProvider.notifier);
                if (t != Tradition.undecided &&
                    !ref.read(sessionProvider).specialDataConsent) {
                  final ok = await showBrandConfirm(
                    context,
                    title: 'Сохранить традицию?',
                    body:
                        'Религиозные взгляды — особая категория персональных данных. Разрешите хранить их, чтобы подстроить Библию, календарь и ответы. Отозвать разрешение можно в настройках.',
                    action: 'Разрешить',
                  );
                  if (!ok) return;
                  n.update(
                    (s) => s.copyWith(specialDataConsent: true, tradition: t),
                  );
                  return;
                }
                n.update((s) => s.copyWith(tradition: t));
              },
              padding: const EdgeInsets.symmetric(vertical: 14),
              title: t.title,
              subtitle: t.subtitle,
              trailing: Icon(
                t == selected
                    ? PhosphorIconsRegular.checkCircle
                    : PhosphorIconsRegular.circle,
                color: t == selected ? c.gold : c.border,
                size: 26,
              ),
            ),
        ],
      ),
    );
  }
}

class _RemindersConsentStep extends ConsumerWidget {
  const _RemindersConsentStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider);
    final n = ref.read(sessionProvider.notifier);
    final c = context.colors;
    final morning = TimeOfDay(hour: s.morningHour, minute: s.morningMinute);
    final evening = TimeOfDay(hour: s.eveningHour, minute: s.eveningMinute);

    Future<void> pickMorning() async {
      final t = await showTimePicker(context: context, initialTime: morning);
      if (t != null) {
        n.update(
          (x) => x.copyWith(morningHour: t.hour, morningMinute: t.minute),
        );
      }
    }

    Future<void> pickEvening() async {
      final t = await showTimePicker(context: context, initialTime: evening);
      if (t != null) {
        n.update(
          (x) => x.copyWith(eveningHour: t.hour, eveningMinute: t.minute),
        );
      }
    }

    return _StepScaffold(
      title: 'Напоминания и приватность',
      subtitle:
          'Утренние и вечерние пуши можно выключить в любой момент. Библия доступна без аккаунта.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlatSection(
            children: [
              SettingsTile(
                icon: PhosphorIconsRegular.sun,
                title: 'Утром',
                subtitle: morning.format(context),
                trailing: BrandToggle(
                  value: s.morningReminder,
                  onChanged: (v) => n.update(
                    (x) => x.copyWith(
                      morningReminder: v,
                      pushEnabled: v || x.eveningReminder,
                    ),
                  ),
                ),
                onTap: pickMorning,
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.moon,
                title: 'Вечером',
                subtitle: evening.format(context),
                trailing: BrandToggle(
                  value: s.eveningReminder,
                  onChanged: (v) => n.update(
                    (x) => x.copyWith(
                      eveningReminder: v,
                      pushEnabled: v || x.morningReminder,
                    ),
                  ),
                ),
                onTap: pickEvening,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Где вы живёте', style: context.text.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SoftChip(
                label: 'Россия и СНГ',
                selected: s.region == 'ru',
                onTap: () => n.update((x) => x.copyWith(region: 'ru')),
              ),
              SoftChip(
                label: 'Другая страна',
                selected: s.region == 'int',
                onTap: () => n.update((x) => x.copyWith(region: 'int')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FlatSection(
            children: [
              SettingsTile(
                icon: PhosphorIconsRegular.database,
                title: 'Хранить мою традицию',
                subtitle: 'Религиозные взгляды — особая категория данных.',
                trailing: BrandToggle(
                  value: s.specialDataConsent,
                  onChanged: (v) => n.update(
                    (x) => x.copyWith(
                      specialDataConsent: v,
                      tradition: v ? x.tradition : Tradition.undecided,
                    ),
                  ),
                ),
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.sparkle,
                title: 'AI и озвучка',
                subtitle:
                    'Google Gemini и ElevenLabs. При включении покажем, какие данные отправляются.',
                trailing: BrandToggle(
                  value: s.aiConsent,
                  onChanged: (v) async {
                    if (!v) {
                      n.update((x) => x.copyWith(aiConsent: false));
                      return;
                    }
                    await ensureAiConsent(context, ref);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(PhosphorIconsRegular.lock, color: c.goldStrong, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Дневник хранится в защищённом хранилище; после входа он может синхронизироваться. Список к исповеди — только на этом телефоне.',
                  style: context.text.bodyMedium?.copyWith(color: c.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
