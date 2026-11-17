import 'package:firebase_auth/firebase_auth.dart';

/// База Cloudflare Worker (бесплатно, без Blaze).
/// Задаётся при сборке: `--dart-define=API_PROXY_BASE=https://slovo-api.<subdomain>.workers.dev`
/// или в secrets.json для локальной разработки.
const apiProxyBase = String.fromEnvironment('API_PROXY_BASE');

/// Локальный обход: `--dart-define-from-file=secrets.json` с ключами.
/// В стор-релизе ключи не передаём — только API_PROXY_BASE.
const geminiApiKeyLocal = String.fromEnvironment('GEMINI_API_KEY');
const elevenLabsApiKeyLocal = String.fromEnvironment('ELEVENLABS_API_KEY');

bool get useLocalAiKeys => geminiApiKeyLocal.isNotEmpty;
bool get useLocalTtsKeys => elevenLabsApiKeyLocal.isNotEmpty;
bool get hasApiProxy => apiProxyBase.isNotEmpty;

/// Токен Firebase для вызова прокси. Анонимный вход, если пользователь ещё не вошёл.
/// Anonymous Auth бесплатен на Spark — Blaze не нужен.
Future<String> firebaseIdToken() async {
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
  if (user == null) {
    throw StateError('Не удалось получить сессию Firebase');
  }
  final token = await user.getIdToken();
  if (token == null || token.isEmpty) {
    throw StateError('Пустой ID-токен Firebase');
  }
  return token;
}
