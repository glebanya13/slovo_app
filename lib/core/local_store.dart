import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Хранилище данных пользователя.
///
/// Локально: SharedPreferences, чувствительное (дневник, исповедь) — в Keychain /
/// Android Keystore. Для вошедшего пользователя каждое изменение дублируется
/// в Firestore: `users/{uid}/data/{key}` → `{value, updatedAt}`.
/// Локальная копия служит офлайн-кэшем и хранилищем для гостя.
class LocalStore {
  LocalStore._(this._prefs, this._secure, this._secureCache);

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secure;
  final Map<String, String> _secureCache;

  static const _secureOptions = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  /// Ключи защищённых данных — читаются один раз при запуске.
  static const secureKeys = ['journal', 'confession_list'];

  /// Все ключи данных пользователя, которые синхронизируются с Firestore.
  static const syncedKeys = ['session', 'practices', 'journal', 'my_prayers', 'reader_marks', 'reading_progress', 'favorite_prayers'];

  /// Только на устройстве, в облако не отправляется (раздел 8.4 ТЗ).
  static const localOnlyKeys = ['confession_list'];

  String? _uid;
  String? get uid => _uid;

  static Future<LocalStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    final cache = <String, String>{};
    for (final k in secureKeys) {
      try {
        final v = await _secureOptions.read(key: k);
        if (v != null) cache[k] = v;
      } catch (_) {
        // Хранилище недоступно (например, после переустановки) — начинаем с пустого.
      }
    }
    return LocalStore._(prefs, _secureOptions, cache);
  }

  CollectionReference<Map<String, dynamic>> _cloud(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('data');

  Object? readJson(String key) {
    final raw = secureKeys.contains(key) ? _secureCache[key] : _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLocal(String key, Object? value) async {
    final raw = jsonEncode(value);
    if (secureKeys.contains(key)) {
      _secureCache[key] = raw;
      await _secure.write(key: key, value: raw);
    } else {
      await _prefs.setString(key, raw);
    }
  }

  Future<void> writeJson(String key, Object? value) async {
    await _writeLocal(key, value);
    final uid = _uid;
    if (uid == null || localOnlyKeys.contains(key)) return;
    // Firestore сам ставит запись в очередь, если сети нет.
    _cloud(uid).doc(key).set({'value': value, 'updatedAt': FieldValue.serverTimestamp()}).catchError((Object e) {
      debugPrint('Firestore: не удалось сохранить $key: $e');
    });
  }

  /// Подключение облака после входа.
  /// Если в облаке уже есть данные — они заменяют локальные (другой телефон).
  /// Если облако пустое — туда загружаются локальные данные гостя.
  Future<void> attachCloud(String uid) async {
    _uid = uid;
    final snap = await _cloud(uid).get();
    if (snap.docs.isEmpty) {
      for (final key in syncedKeys) {
        final v = readJson(key);
        if (v != null) await writeJson(key, v);
      }
      return;
    }
    for (final doc in snap.docs) {
      if (syncedKeys.contains(doc.id)) await _writeLocal(doc.id, doc.data()['value']);
    }
  }

  void detachCloud() => _uid = null;

  /// Удаление данных пользователя из Firestore (удаление аккаунта).
  Future<void> deleteCloudData(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in (await _cloud(uid).get()).docs) {
      batch.delete(doc.reference);
    }
    batch.delete(FirebaseFirestore.instance.collection('users').doc(uid));
    await batch.commit();
  }

  Future<void> clearAll() async {
    await _prefs.clear();
    _secureCache.clear();
    for (final k in secureKeys) {
      await _secure.delete(key: k);
    }
  }
}

final localStoreProvider = Provider<LocalStore>((_) => throw UnimplementedError('LocalStore не инициализирован'));
