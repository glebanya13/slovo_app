import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ask/ask_screen.dart';
import '../features/ask/chat_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/bible/bible_screen.dart';
import '../features/bible/chapters_screen.dart';
import '../features/bible/reader_screen.dart';
import '../features/confession/confession_screens.dart';
import '../features/more/about_screen.dart';
import '../features/more/history_screen.dart';
import '../features/more/journal_screens.dart';
import '../features/more/legal_screens.dart';
import '../features/more/more_screen.dart';
import '../features/more/notifications_screen.dart';
import '../features/more/settings_screen.dart';
import '../features/more/support_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/prayer/create_prayer_screen.dart';
import '../features/prayer/prayer_screen.dart';
import '../features/prayer/pray_screen.dart';
import '../core/biometric_service.dart';
import '../features/system/crisis_screen.dart';
import '../features/system/lock_screen.dart';
import '../features/today/review_screen.dart';
import '../features/today/today_screen.dart';
import '../state/app_state.dart';
import 'shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _rootKey = rootNavigatorKey;

class _RouterRefresh extends ChangeNotifier {
  void bump() => notifyListeners();
}

/// Маршруты соответствуют коду экрана в «Карте экранов (Flutter)».
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh();
  ref.listen(sessionProvider, (_, _) => refresh.bump());
  ref.listen(appUnlockedProvider, (_, _) => refresh.bump());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      // Кризисный экран и сплэш доступны всегда.
      if (loc == '/help-now' || loc == '/') return null;
      final session = ref.read(sessionProvider);
      final unlocked = ref.read(appUnlockedProvider);
      final open = loc.startsWith('/onboarding') || loc.startsWith('/auth');
      if (!session.onboarded && !open) return '/onboarding';
      if (session.onboarded && session.appLock && !unlocked && loc != '/lock') return '/lock';
      if (loc == '/lock' && (!session.appLock || unlocked)) return '/today';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()), // ONB-01
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()), // ONB-02..06
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()), // AUTH-01
      GoRoute(path: '/lock', builder: (_, _) => const LockScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/today', builder: (_, _) => const TodayScreen()), // HOME-01
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/bible', // BIB-01
              builder: (_, _) => const BibleScreen(),
              routes: [
                GoRoute(path: ':book', builder: (_, s) => ChaptersScreen(bookId: s.pathParameters['book']!)), // BIB-02
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/prayer', builder: (_, _) => const PrayerScreen()), // PR-01
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/ask', builder: (_, _) => const AskScreen()), // AI-01
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/more', // MORE-01
              builder: (_, _) => const MoreScreen(),
              routes: [
                GoRoute(path: 'journal', builder: (_, _) => const JournalScreen()), // JRN-01
                GoRoute(path: 'history', builder: (_, _) => const HistoryScreen()), // HIST-01
                GoRoute(path: 'settings', builder: (_, _) => const SettingsScreen()), // SET-01
                GoRoute(path: 'about', builder: (_, _) => const AboutScreen()),
                GoRoute(path: 'support', builder: (_, _) => const SupportScreen()),
              ],
            ),
          ]),
        ],
      ),
      // Полноэкранные маршруты поверх таббара.
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/read/:book/:ch', // BIB-03
        builder: (_, s) => ReaderScreen(
          bookId: s.pathParameters['book']!,
          chapter: int.parse(s.pathParameters['ch']!),
          verse: int.tryParse(s.uri.queryParameters['v'] ?? ''),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/pray/:id', // PR-03
        builder: (_, s) => PrayScreen(prayerId: s.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/prayer-create', // PR-05
        builder: (_, _) => const CreatePrayerScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/chat', // AI-02
        builder: (_, s) => ChatScreen(initialQuestion: s.uri.queryParameters['q']),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/confession', // CONF-01
        builder: (_, _) => const ConfessionIntroScreen(),
        routes: [
          GoRoute(path: 'examine', builder: (_, _) => const ExamineScreen()), // CONF-02
          GoRoute(path: 'list', builder: (_, _) => const ConfessionListScreen()), // CONF-05
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/review', // HOME-02
        builder: (_, _) => const ReviewScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/journal-entry', // JRN-02
        pageBuilder: (_, _) => const MaterialPage(fullscreenDialog: true, child: JournalEntryScreen()),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/notifications', // NOTIF-01
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/help-now', // SYS-01
        builder: (_, _) => const CrisisScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/legal/privacy',
        builder: (_, _) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/legal/terms',
        builder: (_, _) => const TermsScreen(),
      ),
    ],
  );
});
