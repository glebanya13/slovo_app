import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/biometric_service.dart';
import '../../core/brand.dart';
import '../../design/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Экран разблокировки Face ID / отпечатком.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await ref.read(biometricServiceProvider).authenticate();
    if (!mounted) return;
    if (ok) {
      ref.read(appUnlockedProvider.notifier).unlock();
      context.go('/today');
    } else {
      setState(() {
        _busy = false;
        _error = 'Не удалось подтвердить. Попробуйте ещё раз.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
          child: Column(
            children: [
              const Spacer(),
              const CrossMark(size: 56),
              const SizedBox(height: 20),
              Text(AppBrand.name, style: t.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Приложение защищено биометрией',
                textAlign: TextAlign.center,
                style: t.bodyLarge?.copyWith(color: c.textMuted),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.danger)),
              ],
              const Spacer(),
              PrimaryButton(
                label: _busy ? 'Проверка…' : 'Разблокировать',
                icon: PhosphorIconsRegular.fingerprint,
                onPressed: _busy ? null : _unlock,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/help-now'),
                child: Text('Мне нужна помощь сейчас', style: TextStyle(color: c.danger)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
