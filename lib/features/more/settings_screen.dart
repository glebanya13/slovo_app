import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../app/theme.dart';
import '../../core/account.dart';
import '../../core/ai_gate.dart';
import '../../core/app_actions.dart';
import '../../core/auth_service.dart';
import '../../core/biometric_service.dart';
import '../../core/brand.dart';
import '../../core/local_reminders.dart';
import '../../core/tts_service.dart';
import '../../design/listen_sheet.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// SET-01 — настройки.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final s = ref.watch(sessionProvider);
    final n = ref.read(sessionProvider.notifier);

    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 22, 0, 8),
      child: Text(
        text,
        style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    return Scaffold(
      appBar: appHeader(context, 'Настройки'),
      body: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, 28),
        children: [
          header('Основные'),
          FlatSection(
            children: [
              SettingsTile(
                icon: PhosphorIconsRegular.sunDim,
                title: 'Тема оформления',
                value: _themeLabel(s.themeMode),
                onTap: () => _pickTheme(context, ref),
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.translate,
                title: 'Язык',
                value: 'Русский',
                onTap: () =>
                    showSnack(context, 'Пока доступен только русский язык'),
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.church,
                title: 'Традиция',
                value: _short(s.tradition),
                onTap: () => _pickTradition(context, ref),
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.bell,
                title: 'Уведомления',
                value: s.pushEnabled ? 'Вкл.' : 'Выкл.',
                onTap: () => _pickNotifications(context, ref),
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.userSound,
                title: 'Голос озвучки',
                value:
                    (TtsVoice.values.asNameMap()[s.voice] ?? TtsVoice.primary)
                        .title,
                onTap: () => _pickVoice(context, ref),
              ),
            ],
          ),
          header('Конфиденциальность'),
          FlatSection(
            children: [
              SettingsTile(
                icon: PhosphorIconsRegular.lock,
                title: 'Приватный AI',
                subtitle: 'Беседы не сохраняются',
                trailing: BrandToggle(
                  value: s.privateAi,
                  onChanged: (v) {
                    n.update((x) => x.copyWith(privateAi: v));
                    if (v) ref.read(chatHistoryProvider.notifier).clear();
                  },
                ),
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.database,
                title: 'Хранить традицию',
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
                    'Google Gemini и ElevenLabs. Подробнее при включении.',
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
              SettingsTile(
                icon: PhosphorIconsRegular.fingerprint,
                title: 'Face ID и отпечаток',
                subtitle: s.appLock ? 'Включено' : 'Выключено',
                trailing: BrandToggle(
                  value: s.appLock,
                  onChanged: (v) => _toggleAppLock(context, ref, v),
                ),
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.eyeSlash,
                title: 'Скрывать текст уведомлений',
                trailing: BrandToggle(
                  value: s.hideNotificationBody,
                  onChanged: (v) =>
                      n.update((x) => x.copyWith(hideNotificationBody: v)),
                ),
              ),
            ],
          ),
          header('Аккаунт'),
          FlatSection(
            children: [
              SettingsTile(
                icon: PhosphorIconsRegular.downloadSimple,
                title: 'Экспорт моих данных',
                onTap: () => exportUserData(context, ref),
              ),
              if (!s.isGuest)
                SettingsTile(
                  icon: PhosphorIconsRegular.signOut,
                  title: 'Выйти',
                  onTap: () => _signOut(context, ref),
                ),
              SettingsTile(
                icon: PhosphorIconsRegular.trash,
                iconColor: c.danger,
                title: s.isGuest ? 'Удалить мои данные' : 'Удалить аккаунт',
                onTap: () => _deleteAccount(context, ref),
              ),
            ],
          ),
          header('Приложение'),
          FlatSection(
            children: [
              SettingsTile(
                icon: PhosphorIconsRegular.star,
                title: 'Оценить приложение',
                onTap: () => openStoreListing(context),
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.shareNetwork,
                title: 'Поделиться с друзьями',
                onTap: () => shareText(
                  '${AppBrand.name} — чтение Библии, молитвы и спокойные ответы на вопросы веры.',
                  subject: AppBrand.name,
                ),
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.chatTeardropText,
                title: 'Обратная связь',
                onTap: () => sendEmail(
                  context,
                  to: AppBrand.supportEmail,
                  subject: '${AppBrand.name}: обратная связь',
                ),
              ),
              SettingsTile(
                icon: PhosphorIconsRegular.info,
                title: 'О приложении',
                onTap: () => context.push('/more/about'),
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
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Делай мир светлее!',
                style: scriptStyle(size: 30, color: c.goldStrong),
              ),
              const SizedBox(width: 6),
              Icon(PhosphorIconsRegular.heart, color: c.gold, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (_, snap) => Text(
                'Версия ${snap.data?.version ?? '…'}',
                style: t.bodySmall?.copyWith(color: c.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _themeLabel(String mode) => switch (mode) {
    'dark' => 'Тёмная',
    'system' => 'Как в системе',
    _ => 'Светлая',
  };

  Future<void> _toggleAppLock(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    final bio = ref.read(biometricServiceProvider);
    if (enable) {
      if (!await bio.isAvailable) {
        if (context.mounted) {
          showSnack(context, 'Биометрия недоступна на этом устройстве');
        }
        return;
      }
      final ok = await bio.authenticate(
        reason: 'Подтвердите, чтобы включить защиту приложения',
      );
      if (!ok) {
        if (context.mounted) {
          showSnack(context, 'Не удалось подтвердить биометрию');
        }
        return;
      }
      ref
          .read(sessionProvider.notifier)
          .update((s) => s.copyWith(appLock: true));
      ref.read(appUnlockedProvider.notifier).unlock();
      if (context.mounted) showSnack(context, 'Защита включена');
    } else {
      final ok = await bio.authenticate(
        reason: 'Подтвердите, чтобы выключить защиту',
      );
      if (!ok) {
        if (context.mounted) {
          showSnack(context, 'Не удалось подтвердить биометрию');
        }
        return;
      }
      ref
          .read(sessionProvider.notifier)
          .update((s) => s.copyWith(appLock: false));
      ref.read(appUnlockedProvider.notifier).unlock();
      if (context.mounted) showSnack(context, 'Защита выключена');
    }
  }

  void _pickTheme(BuildContext context, WidgetRef ref) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: context.colors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        builder: (sheet) => SafeArea(
          child: FlatSection(
            children: [
              for (final (id, title) in const [
                ('light', 'Светлая'),
                ('dark', 'Тёмная'),
                ('system', 'Как в системе'),
              ])
                SettingsTile(
                  icon: PhosphorIconsRegular.circle,
                  title: title,
                  trailing: ref.read(sessionProvider).themeMode == id
                      ? Icon(
                          PhosphorIconsRegular.check,
                          color: sheet.colors.goldStrong,
                        )
                      : const SizedBox.shrink(),
                  onTap: () {
                    ref
                        .read(sessionProvider.notifier)
                        .update((s) => s.copyWith(themeMode: id));
                    Navigator.pop(sheet);
                  },
                ),
            ],
          ),
        ),
      );

  void _pickNotifications(
    BuildContext context,
    WidgetRef ref,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (sheet) {
      return SafeArea(
        child: Consumer(
          builder: (context, ref, _) {
            final s = ref.watch(sessionProvider);
            final n = ref.read(sessionProvider.notifier);
            final morning = TimeOfDay(
              hour: s.morningHour,
              minute: s.morningMinute,
            );
            final evening = TimeOfDay(
              hour: s.eveningHour,
              minute: s.eveningMinute,
            );

            Future<void> reschedule() => rescheduleReminders(
              session: ref.read(sessionProvider),
              reminders: ref.read(localReminderProvider),
              push: ref.read(pushServiceProvider),
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.sm,
                AppSpace.page,
                AppSpace.lg,
              ),
              child: FlatSection(
                children: [
                  SettingsTile(
                    icon: PhosphorIconsRegular.bell,
                    title: 'Уведомления',
                    subtitle: 'Напоминания утром и вечером',
                    trailing: BrandToggle(
                      value: s.pushEnabled,
                      onChanged: (v) async {
                        n.update((x) => x.copyWith(pushEnabled: v));
                        await reschedule();
                      },
                    ),
                  ),
                  SettingsTile(
                    icon: PhosphorIconsRegular.sun,
                    title: 'Утром',
                    subtitle: morning.format(context),
                    trailing: BrandToggle(
                      value: s.morningReminder,
                      onChanged: s.pushEnabled
                          ? (v) async {
                              n.update((x) => x.copyWith(morningReminder: v));
                              await reschedule();
                            }
                          : null,
                    ),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: morning,
                      );
                      if (t != null) {
                        n.update(
                          (x) => x.copyWith(
                            morningHour: t.hour,
                            morningMinute: t.minute,
                          ),
                        );
                        await reschedule();
                      }
                    },
                  ),
                  SettingsTile(
                    icon: PhosphorIconsRegular.moon,
                    title: 'Вечером',
                    subtitle: evening.format(context),
                    trailing: BrandToggle(
                      value: s.eveningReminder,
                      onChanged: s.pushEnabled
                          ? (v) async {
                              n.update((x) => x.copyWith(eveningReminder: v));
                              await reschedule();
                            }
                          : null,
                    ),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: evening,
                      );
                      if (t != null) {
                        n.update(
                          (x) => x.copyWith(
                            eveningHour: t.hour,
                            eveningMinute: t.minute,
                          ),
                        );
                        await reschedule();
                      }
                    },
                  ),
                  SettingsTile(
                    icon: PhosphorIconsRegular.listBullets,
                    title: 'Открыть список уведомлений',
                    onTap: () {
                      Navigator.pop(sheet);
                      context.push('/notifications');
                    },
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );

  static String _short(Tradition t) => switch (t) {
    Tradition.orthodox => 'Православие',
    Tradition.catholic => 'Католицизм',
    Tradition.exploring => 'Изучаю',
    Tradition.undecided => 'Не выбрана',
  };

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    if (!await showBrandConfirm(
      context,
      title: 'Выйти?',
      body:
          'Все ваши записи, молитвы и список к исповеди будут удалены с этого телефона.',
      action: 'Выйти',
      danger: true,
    )) {
      return;
    }
    await ref.read(accountProvider).signOut();
    if (context.mounted) context.go('/');
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final guest = ref.read(sessionProvider).isGuest;
    if (!await showBrandConfirm(
      context,
      title: guest ? 'Удалить мои данные?' : 'Удалить аккаунт?',
      body: guest
          ? 'Все записи, молитвы и настройки будут удалены с этого телефона без возможности восстановления.'
          : 'Аккаунт и все данные будут удалены без возможности восстановления. Возможно, потребуется ещё раз подтвердить вход.',
      action: 'Удалить',
      danger: true,
    )) {
      return;
    }
    try {
      await ref.read(accountProvider).deleteAccount();
      if (context.mounted) context.go('/');
    } on AuthCancelled {
      // Пользователь отменил подтверждение входа.
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Не удалось удалить аккаунт: ${authErrorText(e)}'),
          ),
        );
      }
    }
  }

  void _pickVoice(
    BuildContext context,
    WidgetRef ref,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (sheet) => SafeArea(
      child: FlatSection(
        children: [
          for (final v in TtsVoice.values)
            SettingsTile(
              icon: PhosphorIconsRegular.userSound,
              title: v.title,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Прослушать',
                    icon: const Icon(PhosphorIconsRegular.playCircle),
                    onPressed: () {
                      ref
                          .read(sessionProvider.notifier)
                          .update((s) => s.copyWith(voice: v.name));
                      showListenSheet(
                        context,
                        ref,
                        title: v.title,
                        text:
                            'Господи Иисусе Христе, Сыне Божий, помилуй меня.',
                      );
                    },
                  ),
                  if (ref.read(sessionProvider).voice == v.name)
                    Icon(
                      PhosphorIconsRegular.check,
                      color: sheet.colors.goldStrong,
                    ),
                ],
              ),
              onTap: () {
                ref
                    .read(sessionProvider.notifier)
                    .update((s) => s.copyWith(voice: v.name));
                Navigator.pop(sheet);
              },
            ),
        ],
      ),
    ),
  );

  void _pickTradition(
    BuildContext context,
    WidgetRef ref,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
    ),
    builder: (sheet) => SafeArea(
      child: FlatSection(
        children: [
          for (final t in Tradition.values)
            SettingsTile(
              icon: PhosphorIconsRegular.church,
              title: t.title,
              subtitle: t.subtitle,
              trailing: ref.read(sessionProvider).tradition == t
                  ? Icon(
                      PhosphorIconsRegular.check,
                      color: sheet.colors.goldStrong,
                    )
                  : const SizedBox.shrink(),
              onTap: () async {
                Navigator.pop(sheet);
                final n = ref.read(sessionProvider.notifier);
                if (t != Tradition.undecided &&
                    !ref.read(sessionProvider).specialDataConsent) {
                  final ok = await showBrandConfirm(
                    context,
                    title: 'Сохранить традицию?',
                    body:
                        'Религиозные взгляды — особая категория персональных данных. Разрешите хранить их, чтобы подстроить приложение.',
                    action: 'Разрешить',
                  );
                  if (!ok) return;
                  n.update((s) => s.copyWith(specialDataConsent: true));
                }
                n.update((s) => s.copyWith(tradition: t));
                ref
                    .read(pushServiceProvider)
                    .syncTopics(ref.read(sessionProvider));
              },
            ),
        ],
      ),
    ),
  );
}
