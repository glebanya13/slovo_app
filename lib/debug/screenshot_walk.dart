import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_data.dart';
import '../design/listen_sheet.dart';
import '../router/router.dart';
import '../state/app_state.dart';

/// Автообход экранов для App Store скриншотов.
/// Запуск: `flutter run --dart-define=SCREENSHOTS=1 ...`
const kScreenshotWalk = bool.fromEnvironment('SCREENSHOTS');

void markShot(String name) {
  // ignore: avoid_print
  print('<<<SHOT:$name>>>');
}

Future<void> runScreenshotWalk(WidgetRef ref) async {
  if (!kScreenshotWalk) return;
  try {
    // После сплэша и restore сессии.
    await Future<void>.delayed(const Duration(milliseconds: 3500));

    ref.read(sessionProvider.notifier).update(
          (s) => s.copyWith(
            onboarded: true,
            signedIn: false,
            aiConsent: true,
            specialDataConsent: true,
            tradition: Tradition.orthodox,
            appLock: false,
          ),
        );
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final router = ref.read(routerProvider);
    Future<void> go(String loc, String shot, {int holdMs = 1400}) async {
      router.go(loc);
      await Future<void>.delayed(Duration(milliseconds: holdMs));
      markShot(shot);
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }

    await go('/today', '01_today');
    await go('/bible', '02_bible');
    await go('/bible/matt', '03_chapters');
    await go('/read/matt/5', '04_reader', holdMs: 1600);

    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      final verses = chapterText('matt', 5, Tradition.orthodox) ?? const [];
      final text = verses.map((v) => v.text).join(' ');
      unawaited(showListenSheet(ctx, ref, title: 'От Матфея, глава 5', text: text));
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      markShot('05_listen_loading');
      await Future<void>.delayed(const Duration(milliseconds: 5000));
      markShot('06_listen_ready');
      if (ctx.mounted) Navigator.of(ctx, rootNavigator: true).maybePop();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (ctx.mounted) Navigator.of(ctx).maybePop();
    } else {
      // ignore: avoid_print
      print('<<<SHOT:ERR_no_context>>>');
    }

    await go('/prayer', '07_prayer');
    final prayerId = prayerBook(Tradition.orthodox).first.prayers.first.id;
    await go('/pray/$prayerId', '08_pray', holdMs: 1600);
    await go('/ask', '09_ask');
    await go('/more', '10_profile');
    await go('/today', '01b_today');
    markShot('DONE');
  } catch (e, st) {
    // ignore: avoid_print
    print('<<<SHOT:ERR>>> $e\n$st');
  }
}
