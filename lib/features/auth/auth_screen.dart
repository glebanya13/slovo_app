import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/account.dart';
import '../../core/auth_service.dart';
import '../../core/brand.dart';
import '../../core/local_reminders.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// AUTH-01 — вход: гостевое чтение первым, синхронизация — вторично.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _busy; // 'email' | 'register' | 'apple' | 'google'
  bool _showSignIn = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _finish(User? user) async {
    final account = ref.read(accountProvider);
    if (user != null) await account.onSignedIn(user);
    final n = ref.read(sessionProvider.notifier);
    final name = user?.displayName?.trim().split(' ').first ?? '';
    n.update((s) => s.copyWith(name: s.name.isEmpty ? name : s.name));
    n.finishOnboarding(signedIn: user != null);
    await rescheduleReminders(
      session: ref.read(sessionProvider),
      reminders: ref.read(localReminderProvider),
      push: ref.read(pushServiceProvider),
    );
    if (mounted) context.go('/today');
  }

  Future<void> _run(String what, Future<User?> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = what);
    try {
      final user = await action();
      if (user != null) await _finish(user);
    } on AuthCancelled {
      // Пользователь закрыл окно входа.
    } catch (e) {
      if (mounted) _snack(authErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  bool _validEmail() {
    if (!_email.text.contains('@')) {
      _snack('Введите email');
      return false;
    }
    if (_password.text.length < 6) {
      _snack('Пароль — минимум 6 символов');
      return false;
    }
    return true;
  }

  Future<void> _reset() async {
    if (!_email.text.contains('@')) return _snack('Введите email, и мы пришлём ссылку для сброса пароля');
    try {
      await ref.read(authServiceProvider).resetPassword(_email.text);
      _snack('Ссылка для сброса пароля отправлена на ${_email.text.trim()}');
    } catch (e) {
      _snack(authErrorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final auth = ref.read(authServiceProvider);
    final idle = _busy == null;

    Widget spinner([Color? color]) =>
        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: color ?? c.gold));

    Widget field(
      TextEditingController ctrl,
      String hint,
      IconData icon, {
      bool obscure = false,
      TextInputType? type,
      List<String>? hints,
    }) =>
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: type,
          autofillHints: hints,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: c.textMuted, size: 21),
          ),
        );

    return Scaffold(
      body: DawnBackground(
        child: SafeArea(
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.xxl, 48, AppSpace.xxl, AppSpace.xxl),
              children: [
                const Center(child: CrossMark(size: 58)),
                const SizedBox(height: AppSpace.lg),
                Center(child: Text(AppBrand.name, style: t.headlineMedium?.copyWith(fontSize: 34))),
                const SizedBox(height: AppSpace.sm),
                Center(
                  child: Text(
                    'Библия, молитвы и спокойные ответы на вопросы веры',
                    textAlign: TextAlign.center,
                    style: t.bodyMedium?.copyWith(color: c.textMuted, height: 1.4),
                  ),
                ),
                const SizedBox(height: 36),
                PrimaryButton(
                  label: 'Читать Библию без аккаунта',
                  onPressed: idle ? () => _finish(null) : null,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Аккаунт нужен только для синхронизации между устройствами',
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: c.textMuted),
                ),
                const SizedBox(height: AppSpace.xxl),
                if (!_showSignIn)
                  TextButton(
                    onPressed: idle ? () => setState(() => _showSignIn = true) : null,
                    child: Text(
                      'Войти или создать аккаунт',
                      style: t.bodyMedium?.copyWith(color: c.goldStrong, fontWeight: FontWeight.w600),
                    ),
                  )
                else ...[
                  Text('Синхронизация', style: t.titleMedium?.copyWith(color: c.textMuted)),
                  const SizedBox(height: AppSpace.md),
                  field(_email, 'Email', PhosphorIconsRegular.at, type: TextInputType.emailAddress, hints: const [AutofillHints.email]),
                  const SizedBox(height: AppSpace.md),
                  field(_password, 'Пароль', PhosphorIconsRegular.lock, obscure: true, hints: const [AutofillHints.password]),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: idle ? _reset : null,
                      child: Text('Забыли пароль?', style: t.bodySmall?.copyWith(decoration: TextDecoration.underline, color: c.textMuted)),
                    ),
                  ),
                  PrimaryButton(
                    label: _busy == 'email' ? 'Входим…' : 'Войти',
                    onPressed: idle
                        ? () => _validEmail() ? _run('email', () => auth.signInWithEmail(_email.text, _password.text)) : null
                        : null,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Row(children: [
                    Expanded(child: Divider(color: c.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('или', style: t.bodySmall?.copyWith(color: c.textMuted)),
                    ),
                    Expanded(child: Divider(color: c.border)),
                  ]),
                  const SizedBox(height: AppSpace.lg),
                  if (Platform.isIOS) ...[
                    SecondaryButton(
                      label: 'Продолжить с Apple',
                      leading: _busy == 'apple' ? spinner() : const Icon(Icons.apple, size: 22),
                      onPressed: idle ? () => _run('apple', auth.signInWithApple) : null,
                    ),
                    const SizedBox(height: AppSpace.md),
                  ],
                  SecondaryButton(
                    label: 'Продолжить с Google',
                    leading: _busy == 'google'
                        ? spinner()
                        : Text('G', style: t.titleMedium?.copyWith(color: const Color(0xFF4285F4), fontWeight: FontWeight.w800, fontSize: 18)),
                    onPressed: idle ? () => _run('google', auth.signInWithGoogle) : null,
                  ),
                  const SizedBox(height: AppSpace.md),
                  SecondaryButton(
                    label: 'Зарегистрироваться',
                    leading: _busy == 'register' ? spinner() : null,
                    onPressed: idle
                        ? () => _validEmail() ? _run('register', () => auth.registerWithEmail(_email.text, _password.text)) : null
                        : null,
                  ),
                ],
                const SizedBox(height: AppSpace.lg),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => context.push('/legal/privacy'),
                      child: Text('Конфиденциальность', style: t.bodySmall?.copyWith(decoration: TextDecoration.underline, color: c.textMuted)),
                    ),
                    Text('·', style: t.bodySmall?.copyWith(color: c.textMuted)),
                    TextButton(
                      onPressed: () => context.push('/legal/terms'),
                      child: Text('Условия', style: t.bodySmall?.copyWith(decoration: TextDecoration.underline, color: c.textMuted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
