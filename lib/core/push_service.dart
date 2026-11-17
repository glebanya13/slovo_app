import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../state/app_state.dart';

/// Push-уведомления через Firebase Cloud Messaging.
///
/// Рассылки отправляются из консоли Firebase (Messaging → «Новая кампания»)
/// по темам:
///   `all`                 — все пользователи;
///   `ru` / `int`          — по региону;
///   `orthodox` / `catholic` / `exploring` — по традиции.
/// Чтобы по нажатию открыть экран, в «Доп. параметрах» добавьте ключ
/// `route` со значением, например, `/read/matt/5` или `/review`.
class PushService {
  PushService(this._messaging);
  final FirebaseMessaging _messaging;

  final Set<String> _topics = {};
  StreamSubscription<String>? _tokenSub;

  /// Куда перейти при нажатии на уведомление.
  void Function(String route)? onOpenRoute;

  static const _allTraditionTopics = [
    'orthodox',
    'catholic',
    'exploring',
    'undecided',
  ];
  static const _allRegionTopics = ['ru', 'int'];

  /// Запрос разрешения и подписка на темы. Безопасно вызывать повторно.
  Future<void> init({required Session session}) async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // На iOS токен FCM появляется только после регистрации APNs.
      if (Platform.isIOS && await _waitForApns() == null) {
        debugPrint(
          'Push: APNs-токен не получен (симулятор или нет ключа APNs в Firebase)',
        );
        return;
      }

      await _syncTopics(session);

      final token = await _messaging.getToken();
      if (token != null) await saveToken(token);
      _tokenSub ??= _messaging.onTokenRefresh.listen(saveToken);

      FirebaseMessaging.onMessageOpenedApp.listen(_open);
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _open(initial);
    } catch (e) {
      debugPrint('Push: $e');
    }
  }

  Future<String?> _waitForApns() async {
    for (var i = 0; i < 10; i++) {
      final t = await _messaging.getAPNSToken();
      if (t != null) return t;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  /// Подписка на темы по региону и традиции; старые темы снимаются.
  Future<void> syncTopics(Session session) async {
    try {
      await _syncTopics(session);
    } catch (e) {
      debugPrint('Push: $e');
    }
  }

  Future<void> _syncTopics(Session session) async {
    final traditionTopic = session.specialDataConsent
        ? session.tradition.name
        : Tradition.undecided.name;
    final want = {'all', session.region, traditionTopic};
    for (final t in [..._allRegionTopics, ..._allTraditionTopics]) {
      if (!want.contains(t) && _topics.contains(t)) {
        await _messaging.unsubscribeFromTopic(t);
        _topics.remove(t);
      }
    }
    for (final t in want) {
      if (_topics.add(t)) await _messaging.subscribeToTopic(t);
    }
  }

  /// Токен сохраняется в профиле, чтобы можно было писать конкретному человеку.
  Future<void> saveToken([String? token]) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      if (Platform.isIOS && await _messaging.getAPNSToken() == null) return;
      token ??= await _messaging.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'platform': Platform.operatingSystem,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Push: $e');
    }
  }

  void _open(RemoteMessage m) {
    final route = m.data['route'];
    if (route is String && route.startsWith('/')) onOpenRoute?.call(route);
  }

  /// При выходе: токен удаляется, чтобы уведомления не приходили чужому аккаунту.
  Future<void> reset() async {
    try {
      for (final t in _topics) {
        await _messaging.unsubscribeFromTopic(t);
      }
      _topics.clear();
      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('Push: $e');
    }
  }
}
