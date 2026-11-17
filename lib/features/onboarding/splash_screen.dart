import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/biometric_service.dart';
import '../../core/brand.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';

/// ONB-01 — заставка: небо, крест, «Слово», пейзаж.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
  late final Animation<Offset> _rise = Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(_fade);

  @override
  void initState() {
    super.initState();
    _enter.forward();
    _timer = Timer(const Duration(milliseconds: 2000), _next);
  }

  void _next() {
    if (!mounted) return;
    final session = ref.read(sessionProvider);
    if (!session.onboarded) {
      context.go('/onboarding');
      return;
    }
    if (session.appLock && !ref.read(appUnlockedProvider)) {
      context.go('/lock');
      return;
    }
    context.go('/today');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = context.colors;
    final h = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: c.surfaceWarm,
      body: GestureDetector(
        onTap: _next,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.lerp(c.surfaceWarm, const Color(0xFFB8C4D4), 0.55)!,
                    c.surfaceWarm,
                    Color.lerp(c.background, c.gold, 0.08)!,
                  ],
                  stops: const [0, 0.38, 0.58],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: h * 0.56,
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0, 0.18],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: const Photo('splash_landscape', radius: 0, alignment: Alignment.topCenter),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC12161C)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _rise,
                  child: Column(
                    children: [
                      SizedBox(height: h * 0.1),
                      CrossMark(size: 76, color: c.gold),
                      const SizedBox(height: 22),
                      Text(AppBrand.name, style: t.displaySmall?.copyWith(fontSize: 44, color: c.text)),
                      const SizedBox(height: 12),
                      Text(
                        'Библия, молитвы и спокойные\nответы на вопросы веры.',
                        textAlign: TextAlign.center,
                        style: t.bodyLarge?.copyWith(fontSize: 17, color: c.textMuted, height: 1.5),
                      ),
                      const Spacer(),
                      Text(
                        'Путь к лучшему дню начинается здесь',
                        textAlign: TextAlign.center,
                        style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.92), height: 1.45),
                      ),
                      const SizedBox(height: 10),
                      CrossMark(size: 18, color: c.gold),
                      const SizedBox(height: 26),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
