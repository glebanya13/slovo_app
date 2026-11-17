import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/theme.dart';
import 'core/account.dart';
import 'core/biometric_service.dart';
import 'core/local_reminders.dart';
import 'core/local_store.dart';
import 'data/bible.dart';
import 'debug/screenshot_walk.dart';
import 'firebase_options.dart';
import 'router/router.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

  final (store, _) = await (LocalStore.open(), Bible.load()).wait;
  runApp(ProviderScope(
    overrides: [localStoreProvider.overrideWithValue(store)],
    child: const SlovoApp(),
  ));
}

class SlovoApp extends ConsumerStatefulWidget {
  const SlovoApp({super.key});

  @override
  ConsumerState<SlovoApp> createState() => _SlovoAppState();
}

class _SlovoAppState extends ConsumerState<SlovoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Нажатие на push открывает экран из поля `route`.
    ref.read(pushServiceProvider).onOpenRoute = (route) {
      if (ref.read(sessionProvider).appLock && !ref.read(appUnlockedProvider)) {
        ref.read(routerProvider).go('/lock');
        return;
      }
      ref.read(routerProvider).push(route);
    };
    ref.read(localReminderProvider).onOpenRoute = (route) {
      if (ref.read(sessionProvider).appLock && !ref.read(appUnlockedProvider)) {
        ref.read(routerProvider).go('/lock');
        return;
      }
      ref.read(routerProvider).push(route);
    };
    ref.read(accountProvider).restore().then((_) async {
      final session = ref.read(sessionProvider);
      if (session.onboarded && session.pushEnabled) {
        await rescheduleReminders(
          session: session,
          reminders: ref.read(localReminderProvider),
          push: ref.read(pushServiceProvider),
        );
      }
      if (kScreenshotWalk) {
        // ignore: avoid_print
        print('WALK: restore done, calling walk');
        await runScreenshotWalk(ref);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Только paused: inactive срабатывает и при системном Face ID-диалоге.
    if (state == AppLifecycleState.paused) {
      if (ref.read(sessionProvider).appLock) {
        ref.read(appUnlockedProvider.notifier).lock();
      }
    } else if (state == AppLifecycleState.resumed) {
      final session = ref.read(sessionProvider);
      if (session.onboarded && session.appLock && !ref.read(appUnlockedProvider)) {
        final router = ref.read(routerProvider);
        if (router.state.matchedLocation != '/lock' && router.state.matchedLocation != '/help-now') {
          router.go('/lock');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(sessionProvider.select((s) => s.materialThemeMode));
    return MaterialApp.router(
      title: 'Слово',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
