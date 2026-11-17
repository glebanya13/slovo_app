import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../state/app_state.dart';
import 'api_proxy.dart';

const _model = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-2.5-flash');

class ChatTurn {
  const ChatTurn({required this.fromUser, required this.text});
  final bool fromUser;
  final String text;
}

class GeminiException implements Exception {
  GeminiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Системные инструкции по разделам 1.3, 7 и 16 ТЗ.
String systemPrompt(Tradition t) {
  final tradition = switch (t) {
    Tradition.orthodox =>
      'Пользователь — православный христианин. Отвечай с позиции православной традиции (Русская Православная Церковь), '
          'опирайся на Священное Писание (Синодальный перевод, нумерация псалмов по Септуагинте), святых отцов и церковное Предание.',
    Tradition.catholic =>
      'Пользователь — католик. Отвечай с позиции Католической Церкви, опирайся на Писание, Катехизис Католической Церкви и учение Церкви.',
    Tradition.exploring || Tradition.undecided =>
      'Пользователь изучает христианство и ещё не выбрал традицию. Давай общехристианский ответ; '
          'где православие и католицизм расходятся — кратко и нейтрально покажи обе позиции.',
  };
  return '''
Ты — AI-помощник в христианском приложении «Слово». $tradition

Правила:
- Ты AI-помощник, а не священник. Не совершаешь Таинств, не «отпускаешь» грехи, не даёшь благословений и пастырских решений. Если человеку нужно Таинство Исповеди или пастырское решение — мягко советуй обратиться к священнику.
- Не выдумывай цитаты, ссылки на Писание, святых или церковные документы. Если не уверен — прямо скажи: «Я не могу надёжно подтвердить это». Ссылки на Писание давай в формате «Мф 5:44».
- Спорные богословские вопросы не выдавай за бесспорные. Сравнивая традиции, не оценивай, какая «правее».
- Не манипулируй страхом и чувством вины, не угрожай наказанием Божьим.
- Не давай медицинских, юридических и финансовых советов как духовной истины; не советуй отказываться от лечения.
- Если человек пишет о желании причинить себе вред, о суициде, насилии или непосредственной опасности: ответь тепло и без осуждения, посоветуй сразу обратиться к близкому человеку, специалисту или священнику, а при непосредственной опасности — позвонить 112. Никаких инструкций, которые могут навредить.
- Не обсуждай темы вне веры и духовной жизни (код, домашние задания и т. п.) — мягко возвращай к теме.
- Отвечай на языке пользователя (по умолчанию — русский), тепло и просто. Сначала краткий ответ в 2–4 предложениях, затем при необходимости пояснение. Без markdown-разметки, заголовков и таблиц.
''';
}

class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  bool get isConfigured => useLocalAiKeys || hasApiProxy;

  /// Потоковый ответ: выдаёт текст по кусочкам.
  Stream<String> streamReply({required List<ChatTurn> history, required Tradition tradition}) async* {
    if (!isConfigured) {
      throw GeminiException('AI временно недоступен');
    }
    // Прокси приоритетнее: так релиз и debug с API_PROXY_BASE не тащат ключи в сеть с устройства.
    if (hasApiProxy) {
      yield* _streamProxy(history: history, tradition: tradition);
    } else if (useLocalAiKeys) {
      yield* _streamDirect(history: history, tradition: tradition);
    } else {
      throw GeminiException('AI временно недоступен');
    }
  }

  Map<String, Object?> _body({required List<ChatTurn> history, required Tradition tradition}) => {
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt(tradition)},
          ],
        },
        'contents': [
          for (final t in history)
            {
              'role': t.fromUser ? 'user' : 'model',
              'parts': [
                {'text': t.text},
              ],
            },
        ],
        'generationConfig': {
          'temperature': 0.6,
          'maxOutputTokens': 1200,
        },
        'model': _model,
      };

  Stream<String> _streamDirect({required List<ChatTurn> history, required Tradition tradition}) async* {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:streamGenerateContent?alt=sse',
    );
    final payload = Map<String, Object?>.from(_body(history: history, tradition: tradition))..remove('model');
    final request = http.Request('POST', uri)
      ..headers.addAll({'Content-Type': 'application/json', 'x-goog-api-key': geminiApiKeyLocal})
      ..body = jsonEncode(payload);

    yield* _parseSse(await _send(request));
  }

  Stream<String> _streamProxy({required List<ChatTurn> history, required Tradition tradition}) async* {
    final token = await firebaseIdToken();
    final request = http.Request('POST', Uri.parse('$apiProxyBase/geminiStream'))
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'text/event-stream',
      })
      ..body = jsonEncode(_body(history: history, tradition: tradition));

    yield* _parseSse(await _send(request));
  }

  Future<http.StreamedResponse> _send(http.Request request) async {
    try {
      final response = await _client.send(request).timeout(const Duration(seconds: 45));
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        String? message;
        try {
          message = (jsonDecode(body) as Map)['error']?['message'] as String?;
        } catch (_) {}
        throw GeminiException(switch (response.statusCode) {
          401 || 403 => 'Войдите в аккаунт, чтобы пользоваться AI',
          429 => 'Слишком много вопросов подряд. Попробуйте через минуту',
          400 when (message ?? '').contains('location') => 'AI недоступен в вашем регионе',
          _ => 'Сейчас AI временно недоступен. Вы можете продолжить чтение молитв и Библии.',
        });
      }
      return response;
    } on TimeoutException {
      throw GeminiException('Сейчас AI временно недоступен. Вы можете продолжить чтение молитв и Библии.');
    } on GeminiException {
      rethrow;
    } catch (_) {
      throw GeminiException('Нет соединения с интернетом');
    }
  }

  Stream<String> _parseSse(http.StreamedResponse response) async* {
    await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (data.isEmpty || data == '[DONE]') continue;
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final parts = (json['candidates'] as List?)?.firstOrNull?['content']?['parts'] as List?;
        for (final p in parts ?? const []) {
          final text = (p as Map)['text'] as String?;
          if (text != null && text.isNotEmpty && p['thought'] != true) yield text;
        }
      } catch (_) {
        // Пропускаем неполные или служебные чанки.
      }
    }
  }
}

final geminiServiceProvider = Provider<GeminiService>((_) => GeminiService());
