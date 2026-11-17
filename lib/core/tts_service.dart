import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'api_proxy.dart';
import 'gemini_service.dart' show GeminiException;

const _voiceId = String.fromEnvironment('ELEVENLABS_VOICE_ID', defaultValue: 'OmiN5OoGtndz0F9qqRP1');
/// Flash — низкая задержка (~75 ms), подходит для русского.
const _model = String.fromEnvironment('ELEVENLABS_MODEL', defaultValue: 'eleven_flash_v2_5');

/// Голоса озвучки. Сейчас один основной голос.
enum TtsVoice {
  primary('OmiN5OoGtndz0F9qqRP1', 'Спокойный');

  const TtsVoice(this.apiName, this.title);
  final String apiName;
  final String title;
}

/// Озвучка через облачный TTS. Готовое аудио кэшируется на устройстве.
class TtsService {
  TtsService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  final _inflight = <String, Future<File>>{};

  /// Лимит на один запрос; длинные тексты режем на куски снаружи.
  static const maxChars = 2200;

  /// Цель размера куска: маленький первый кусок → быстрый старт плеера.
  static const chunkTarget = 380;

  /// Разбить текст на куски по предложениям (для прогрессивного воспроизведения).
  static List<String> chunkText(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return const [];
    if (clean.length <= chunkTarget) return [clean.length > maxChars ? '${clean.substring(0, maxChars)}…' : clean];

    final sentences = clean.split(RegExp(r'(?<=[.!?…;:])\s+'));
    final parts = <String>[];
    final buf = StringBuffer();

    void flush() {
      final s = buf.toString().trim();
      if (s.isNotEmpty) parts.add(s);
      buf.clear();
    }

    for (final raw in sentences) {
      final s = raw.trim();
      if (s.isEmpty) continue;
      if (s.length > maxChars) {
        flush();
        for (var i = 0; i < s.length; i += maxChars) {
          final end = (i + maxChars < s.length) ? i + maxChars : s.length;
          parts.add(s.substring(i, end));
        }
        continue;
      }
      if (buf.isEmpty) {
        buf.write(s);
      } else if (buf.length + 1 + s.length <= chunkTarget) {
        buf.write(' $s');
      } else {
        flush();
        buf.write(s);
      }
    }
    flush();
    return parts.isEmpty ? [clean.substring(0, clean.length.clamp(0, maxChars))] : parts;
  }

  Future<File> synthesize(String text, TtsVoice voice) async {
    final clean = text.trim();
    if (clean.isEmpty) throw GeminiException('Нечего озвучивать');
    final input = clean.length > maxChars ? '${clean.substring(0, maxChars)}…' : clean;

    final voiceId = voice.apiName.isNotEmpty ? voice.apiName : _voiceId;
    final dir = Directory('${(await getApplicationCacheDirectory()).path}/tts');
    await dir.create(recursive: true);
    final name = sha1.convert(utf8.encode('eleven|$voiceId|$_model|22050|flash|$input')).toString();
    final file = File('${dir.path}/$name.mp3');
    if (await file.exists() && await file.length() > 0) return file;

    final existing = _inflight[name];
    if (existing != null) return existing;

    final future = _fetch(file, input, voiceId);
    _inflight[name] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(name);
    }
  }

  Future<File> _fetch(File file, String input, String voiceId) async {
    if (!useLocalTtsKeys && !hasApiProxy) {
      throw GeminiException('Озвучка временно недоступна');
    }

    final http.Request req;
    if (hasApiProxy) {
      final token = await firebaseIdToken();
      req = http.Request('POST', Uri.parse('$apiProxyBase/tts'))
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept': 'audio/mpeg',
        })
        ..body = jsonEncode({
          'text': input,
          'voiceId': voiceId,
          'modelId': _model,
        });
    } else if (useLocalTtsKeys) {
      req = http.Request(
        'POST',
        Uri.parse(
          'https://api.elevenlabs.io/v1/text-to-speech/$voiceId/stream'
          '?output_format=mp3_22050_32&optimize_streaming_latency=4',
        ),
      )
        ..headers.addAll({
          'Content-Type': 'application/json',
          'xi-api-key': elevenLabsApiKeyLocal,
          'Accept': 'audio/mpeg',
        })
        ..body = jsonEncode({
          'text': input,
          'model_id': _model,
          'voice_settings': {'stability': 0.4, 'similarity_boost': 0.7},
        });
    } else {
      throw GeminiException('Озвучка временно недоступна');
    }

    final http.StreamedResponse streamed;
    try {
      streamed = await _client.send(req).timeout(const Duration(seconds: 45));
    } catch (_) {
      throw GeminiException('Не удалось создать аудио. Проверьте интернет и попробуйте ещё раз.');
    }

    if (streamed.statusCode != 200) {
      throw GeminiException(switch (streamed.statusCode) {
        401 || 403 => 'Войдите в аккаунт, чтобы пользоваться озвучкой',
        429 => 'Слишком много запросов на озвучку. Попробуйте через минуту',
        _ => 'Не удалось создать аудио. Попробуйте ещё раз.',
      });
    }

    final sink = file.openWrite();
    try {
      await streamed.stream.forEach(sink.add);
      await sink.flush();
      await sink.close();
    } catch (_) {
      try {
        await sink.close();
      } catch (_) {}
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
      throw GeminiException('Не удалось создать аудио. Проверьте интернет и попробуйте ещё раз.');
    }

    if (await file.length() == 0) {
      throw GeminiException('Не удалось создать аудио. Попробуйте ещё раз.');
    }
    return file;
  }
}

final ttsServiceProvider = Provider<TtsService>((_) => TtsService());
