import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import 'auth_service.dart';
import 'local_store.dart';
import 'push_service.dart';

final pushServiceProvider = Provider<PushService>((_) => PushService(FirebaseMessaging.instance));

/// Связка входа, Firestore и push: что происходит при входе, запуске и выходе.
class Account {
  Account(this._ref);
  final Ref _ref;

  LocalStore get _store => _ref.read(localStoreProvider);

  void _reloadState() {
    _ref.invalidate(sessionProvider);
    _ref.invalidate(practicesProvider);
    _ref.invalidate(journalProvider);
    _ref.invalidate(myPrayersProvider);
    _ref.invalidate(favoritePrayersProvider);
    _ref.invalidate(aiCacheProvider);
    _ref.invalidate(readerMarksProvider);
    _ref.invalidate(readingProgressProvider);
  }

  /// После входа: подтянуть данные из Firestore и обновить профиль.
  Future<void> onSignedIn(User user) async {
    await _store.attachCloud(user.uid);
    _reloadState();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': user.displayName,
      'email': user.email,
      'providers': [for (final p in user.providerData) p.providerId],
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _ref.read(pushServiceProvider).saveToken();
  }

  /// При запуске: если человек уже вошёл — подключить облако и уведомления.
  Future<void> restore() async {
    var session = _ref.read(sessionProvider);
    final user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null && session.signedIn) {
        await _store.attachCloud(user.uid);
        _reloadState();
        session = _ref.read(sessionProvider);
      }
    } catch (e) {
      debugPrint('Firestore: $e');
    }
    if (session.onboarded && session.pushEnabled) {
      await _ref.read(pushServiceProvider).init(session: session);
    }
  }

  Future<void> signOut() async {
    await _ref.read(pushServiceProvider).reset();
    await _ref.read(authServiceProvider).signOut();
    _store.detachCloud();
    await _ref.read(sessionProvider.notifier).signOut();
  }

  /// Удаление аккаунта и всех данных в Firestore (App Store 5.1.1(v)).
  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _store.deleteCloudData(user.uid);
      await _ref.read(authServiceProvider).deleteAccount();
    }
    await _ref.read(pushServiceProvider).reset();
    _store.detachCloud();
    await _ref.read(sessionProvider.notifier).signOut();
  }
}

final accountProvider = Provider<Account>(Account.new);
