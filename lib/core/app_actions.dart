import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/theme.dart';
import '../design/widgets.dart';
import 'local_store.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

void showSnack(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Future<void> shareText(String text, {String? subject}) async {
  final t = text.trim();
  if (t.isEmpty) return;
  await SharePlus.instance.share(ShareParams(text: t, subject: subject));
}

Future<void> copyText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showSnack(context, 'Скопировано');
}

Future<bool> openUri(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<void> callPhone(BuildContext context, String phone) async {
  final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
  final ok = await openUri(Uri.parse('tel:$digits'));
  if (!ok && context.mounted) showSnack(context, 'Не удалось открыть телефон');
}

Future<void> sendEmail(
  BuildContext context, {
  required String to,
  String subject = '',
  String body = '',
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: to,
    queryParameters: {
      if (subject.isNotEmpty) 'subject': subject,
      if (body.isNotEmpty) 'body': body,
    },
  );
  final ok = await openUri(uri);
  if (!ok && context.mounted) showSnack(context, 'Не удалось открыть почту');
}

Future<void> openStoreListing(BuildContext context) async {
  final uri = Platform.isIOS
      ? Uri.parse('https://apps.apple.com/search?term=%D0%A1%D0%BB%D0%BE%D0%B2%D0%BE')
      : Uri.parse('https://play.google.com/store/apps/details?id=dev.davinchi.slovo');
  final ok = await openUri(uri);
  if (!ok && context.mounted) showSnack(context, 'Магазин приложений недоступен');
}

Future<void> exportUserData(BuildContext context, WidgetRef ref) async {
  final store = ref.read(localStoreProvider);
  final payload = <String, Object?>{
    'exportedAt': DateTime.now().toIso8601String(),
    'session': store.readJson('session'),
    'practices': store.readJson('practices'),
    'journal': store.readJson('journal'),
    'my_prayers': store.readJson('my_prayers'),
    'reader_marks': store.readJson('reader_marks'),
  };
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/slovo_export_${DateTime.now().millisecondsSinceEpoch}.json');
  await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
  await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path, mimeType: 'application/json')],
    subject: 'Экспорт данных Слово',
  ));
  if (context.mounted) showSnack(context, 'Экспорт готов');
}

/// Прогрев STT заранее (initialize на iOS может занимать секунды).
Future<void> warmSpeechToText() => _SttHost.instance.ensureReady();

class _SttHost {
  _SttHost._();
  static final instance = _SttHost._();

  final speech = SpeechToText();
  Future<bool>? _ready;

  Future<bool> ensureReady() {
    _ready ??= speech.initialize(
      onError: (e) => debugPrint('STT: $e'),
      onStatus: (s) => debugPrint('STT status: $s'),
    );
    return _ready!;
  }
}

/// Диктовка в текстовое поле. Возвращает true, если что-то распознано.
Future<bool> dictateInto(BuildContext context, TextEditingController controller) async {
  // Сразу показываем шторку — initialize() иногда долгий.
  if (!context.mounted) return false;
  final sheetReady = Completer<BuildContext>();
  final done = Completer<void>();
  var recognized = false;

  // Параллельно с UI догреваем STT.
  final readyFuture = _SttHost.instance.ensureReady();

  unawaited(showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (sheet) {
      if (!sheetReady.isCompleted) sheetReady.complete(sheet);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsRegular.microphone, size: 40, color: sheet.colors.goldStrong),
              const SizedBox(height: 12),
              Text('Говорите…', style: sheet.text.titleLarge),
              const SizedBox(height: 8),
              Text('Нажмите «Готово», когда закончите', style: sheet.text.bodyMedium?.copyWith(color: sheet.colors.textMuted)),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Готово',
                onPressed: () {
                  if (!done.isCompleted) done.complete();
                  Navigator.pop(sheet);
                },
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(() {
    if (!done.isCompleted) done.complete();
  }));

  final sheet = await sheetReady.future;
  final available = await readyFuture;
  if (!available) {
    if (sheet.mounted) Navigator.pop(sheet);
    if (context.mounted) showSnack(context, 'Распознавание речи недоступно на этом устройстве');
    return false;
  }

  final speech = _SttHost.instance.speech;
  final stem = controller.text.trimRight();
  await speech.listen(
    listenOptions: SpeechListenOptions(
      partialResults: true,
      listenMode: ListenMode.dictation,
      localeId: 'ru_RU',
      cancelOnError: true,
    ),
    onResult: (r) {
      recognized = r.recognizedWords.trim().isNotEmpty;
      final prefix = stem.isEmpty ? '' : '$stem ';
      controller.text = '$prefix${r.recognizedWords}';
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    },
  );

  await done.future;
  await speech.stop();
  return recognized || controller.text.trim().isNotEmpty;
}
