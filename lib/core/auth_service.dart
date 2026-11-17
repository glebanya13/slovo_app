import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Пользователь отменил вход — это не ошибка, сообщение не показываем.
class AuthCancelled implements Exception {}

/// Вход через Firebase Authentication: Apple и Google (раздел 3 ТЗ).
class AuthService {
  AuthService(this._auth);
  final FirebaseAuth _auth;
  bool _googleReady = false;

  User? get currentUser => _auth.currentUser;

  /// Имя для приветствия: из профиля Apple/Google, иначе null.
  String? get displayName {
    final n = _auth.currentUser?.displayName?.trim();
    if (n == null || n.isEmpty) return null;
    return n.split(' ').first;
  }

  static String _nonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<(AuthCredential, String?)> _appleCredential() async {
    final rawNonce = _nonce();
    final hashed = sha256.convert(utf8.encode(rawNonce)).toString();
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashed,
      );
      final credential = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        rawNonce: rawNonce,
        accessToken: apple.authorizationCode,
      );
      final name = [apple.givenName, apple.familyName].whereType<String>().join(' ').trim();
      return (credential, name.isEmpty ? null : name);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw AuthCancelled();
      rethrow;
    }
  }

  Future<User?> signInWithApple() async {
    final (credential, name) = await _appleCredential();
    final result = await _auth.signInWithCredential(credential);
    // Apple отдаёт имя только при первом входе — сохраняем его в профиль.
    if (name != null && (result.user?.displayName ?? '').isEmpty) {
      await result.user?.updateDisplayName(name);
    }
    return result.user;
  }

  Future<GoogleSignIn> _google() async {
    if (!_googleReady) {
      await GoogleSignIn.instance.initialize();
      _googleReady = true;
    }
    return GoogleSignIn.instance;
  }

  Future<AuthCredential> _googleCredential() async {
    final google = await _google();
    try {
      final account = await google.authenticate();
      return GoogleAuthProvider.credential(idToken: account.authentication.idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw AuthCancelled();
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async => (await _auth.signInWithCredential(await _googleCredential())).user;

  Future<User?> signInWithEmail(String email, String password) async =>
      (await _auth.signInWithEmailAndPassword(email: email.trim(), password: password)).user;

  Future<User?> registerWithEmail(String email, String password) async {
    final user = (await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password)).user;
    await user?.sendEmailVerification();
    return user;
  }

  Future<void> resetPassword(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() async {
    if (_googleReady) await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  /// Полное удаление аккаунта (требование App Store 5.1.1(v)).
  /// Для Apple дополнительно отзываем токен, как требует Apple.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final providers = user.providerData.map((p) => p.providerId).toSet();
    if (providers.contains('apple.com')) {
      final rawNonce = _nonce();
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: const [],
        nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      await user.reauthenticateWithCredential(
        OAuthProvider('apple.com').credential(idToken: apple.identityToken, rawNonce: rawNonce, accessToken: apple.authorizationCode),
      );
      await _auth.revokeTokenWithAuthorizationCode(apple.authorizationCode);
    } else if (providers.contains('google.com')) {
      await user.reauthenticateWithCredential(await _googleCredential());
    }
    // Для входа по email Firebase может попросить недавний вход — см. authErrorText.
    await user.delete();
    if (_googleReady) await GoogleSignIn.instance.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((_) => AuthService(FirebaseAuth.instance));

/// Понятное сообщение об ошибке входа.
String authErrorText(Object e) {
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'network-request-failed' => 'Нет соединения с интернетом',
      'operation-not-allowed' => 'Этот способ входа пока не включён',
      'user-disabled' => 'Аккаунт заблокирован',
      'invalid-email' => 'Неверный формат email',
      'invalid-credential' || 'wrong-password' || 'user-not-found' => 'Неверный email или пароль',
      'email-already-in-use' => 'Этот email уже зарегистрирован — войдите',
      'weak-password' => 'Пароль слишком простой: минимум 6 символов',
      'too-many-requests' => 'Слишком много попыток. Попробуйте позже',
      'requires-recent-login' => 'Для этого действия войдите заново',
      _ => 'Не удалось войти (${e.code})',
    };
  }
  return 'Не удалось войти. Попробуйте ещё раз';
}
