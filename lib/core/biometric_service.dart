import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Face ID / Touch ID / отпечаток пальца.
class BiometricService {
  BiometricService({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();
  final LocalAuthentication _auth;

  Future<bool> get isAvailable async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String> get label async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return 'Face ID';
      if (types.contains(BiometricType.fingerprint)) return 'Отпечаток';
      if (types.contains(BiometricType.iris)) return 'Радужная оболочка';
    } catch (_) {}
    return 'Биометрия';
  }

  /// Запрос разблокировки. true — успех.
  Future<bool> authenticate({String reason = 'Подтвердите вход в Слово'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>((_) => BiometricService());

/// Разблокировано ли приложение в текущем запуске (не пишется на диск).
class AppUnlockedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void unlock() => state = true;
  void lock() => state = false;
}

final appUnlockedProvider = NotifierProvider<AppUnlockedNotifier, bool>(AppUnlockedNotifier.new);
