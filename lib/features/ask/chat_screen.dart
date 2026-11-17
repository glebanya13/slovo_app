import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/ai_gate.dart';
import '../../core/app_actions.dart';
import '../../core/connectivity.dart';
import '../../core/gemini_service.dart';
import '../../core/smooth_stream.dart';
import '../../design/listen_sheet.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class _Msg {
  _Msg.user(this.text) : fromUser = true, at = DateTime.now();
  _Msg.ai() : fromUser = false, text = '', at = DateTime.now();
  _Msg.fromStored(StoredChatMessage m)
    : fromUser = m.fromUser,
      text = m.text,
      at = m.at,
      failed = m.failed,
      done = true;
  final bool fromUser;
  String text;
  DateTime at;

  final List<String> sources = const [];
  bool done = false;
  bool failed = false;
  bool streaming = false;
  int? rating;

  StoredChatMessage toStored() =>
      StoredChatMessage(fromUser: fromUser, text: text, at: at, failed: failed);
}

const _crisisWords = [
  'покончить',
  'не хочу жить',
  'убить себя',
  'суицид',
  'причинить себе',
];

/// AI-02 — чат с сохранением истории на устройстве.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.initialQuestion});
  final String? initialQuestion;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgs = <_Msg>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  StreamSubscription<String>? _sub;
  SmoothStreamBuffer? _reveal;
  var _restored = false;

  @override
  void initState() {
    super.initState();
    unawaited(warmSpeechToText());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restore();
      final q = widget.initialQuestion;
      if (q != null && q.isNotEmpty) _send(q);
    });
  }

  void _restore() {
    if (_restored) return;
    _restored = true;
    final private = ref.read(sessionProvider).privateAi;
    if (private) return;
    final stored = ref.read(chatHistoryProvider);
    if (stored.isEmpty) return;
    setState(() {
      _msgs
        ..clear()
        ..addAll([for (final m in stored) _Msg.fromStored(m)]);
    });
    _scrollDown();
  }

  void _persist() {
    final private = ref.read(sessionProvider).privateAi;
    if (private) {
      ref.read(chatHistoryProvider.notifier).clear();
      return;
    }
    final ready = [
      for (final m in _msgs)
        if (m.text.trim().isNotEmpty && (m.done || m.fromUser) && !m.streaming)
          m.toStored(),
    ];
    ref.read(chatHistoryProvider.notifier).saveAll(ready);
  }

  Future<void> _send(String q) async {
    q = q.trim();
    if (q.isEmpty || _sub != null || _reveal != null) return;
    if (!await ensureAiConsent(context, ref)) return;
    if (!mounted) return;
    _input.clear();
    if (_crisisWords.any(q.toLowerCase().contains)) {
      context.push('/help-now');
      return;
    }
    final session = ref.read(sessionProvider);
    final tradition = session.specialDataConsent
        ? session.tradition
        : Tradition.undecided;
    final online = ref.read(isOnlineProvider);
    final cached = ref.read(aiCacheProvider.notifier).get(q, tradition);

    if (!online) {
      if (cached != null) {
        setState(
          () => _msgs.addAll([
            _Msg.user(q),
            _Msg.ai()
              ..text = '${cached.answer}\n\n(ответ из офлайн-кэша — нет сети)'
              ..done = true,
          ]),
        );
        _persist();
        _scrollDown();
        return;
      }
      setState(
        () => _msgs.addAll([
          _Msg.user(q),
          _Msg.ai()
            ..failed = true
            ..done = true
            ..text =
                'Нет соединения с интернетом. Вы можете читать Библию и молитвы офлайн; AI снова ответит, когда появится сеть.',
        ]),
      );
      _persist();
      _scrollDown();
      return;
    }

    final history = [
      for (final m in _msgs)
        if (!m.failed && m.text.isNotEmpty)
          ChatTurn(fromUser: m.fromUser, text: m.text),
      ChatTurn(fromUser: true, text: q),
    ];
    final ai = _Msg.ai()..streaming = true;
    setState(() => _msgs.addAll([_Msg.user(q), ai]));
    _persist();

    _reveal = SmoothStreamBuffer(
      onUpdate: () {
        if (!mounted) return;
        setState(() => ai.text = _reveal!.visible);
        _scrollDown();
      },
      onCaughtUp: () {
        if (!mounted) return;
        setState(() {
          ai.streaming = false;
          ai.done = true;
          _reveal?.dispose();
          _reveal = null;
        });
        if (!ai.failed && ai.text.trim().isNotEmpty) {
          ref
              .read(aiCacheProvider.notifier)
              .put(question: q, answer: ai.text, tradition: tradition);
        }
        _persist();
        _scrollDown();
      },
    );

    final stream = ref
        .read(geminiServiceProvider)
        .streamReply(history: history, tradition: tradition);
    _sub = stream.listen(
      (chunk) => _reveal?.add(chunk),
      onError: (Object e) {
        _reveal?.dispose();
        _reveal = null;
        final offlineFallback = cached;
        setState(() {
          ai.failed = offlineFallback == null;
          ai.done = true;
          ai.streaming = false;
          ai.text = offlineFallback != null
              ? '${offlineFallback.answer}\n\n(показан сохранённый ответ — сеть недоступна)'
              : (e is GeminiException
                    ? e.message
                    : 'Сейчас AI временно недоступен. Вы можете продолжить чтение молитв и Библии.');
          _sub = null;
        });
        _persist();
      },
      onDone: () {
        _sub = null;
        _reveal?.markStreamDone();
      },
      cancelOnError: true,
    );
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _clearHistory() async {
    final ok = await showBrandConfirm(
      context,
      title: 'Очистить беседу?',
      body: 'История вопросов и ответов будет удалена с этого телефона.',
      action: 'Очистить',
      danger: true,
    );
    if (!ok || !mounted) return;
    _sub?.cancel();
    _reveal?.dispose();
    _reveal = null;
    _sub = null;
    setState(() => _msgs.clear());
    ref.read(chatHistoryProvider.notifier).clear();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _reveal?.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final private = ref.watch(sessionProvider).privateAi;
    final online = ref.watch(isOnlineProvider);
    return Scaffold(
      appBar: appHeader(
        context,
        'Беседа',
        actions: [
          if (!online)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: c.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIconsRegular.wifiSlash,
                      size: 16,
                      color: c.danger,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Нет сети',
                      style: context.text.bodySmall?.copyWith(
                        color: c.danger,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_msgs.isNotEmpty && !private)
            IconButton(
              tooltip: 'Очистить беседу',
              onPressed: _clearHistory,
              icon: const Icon(PhosphorIconsRegular.trash, size: 20),
            ),
          if (private)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(PhosphorIconsRegular.lock, color: c.goldStrong),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (private)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  'Приватный режим: эта беседа не сохранится после выхода',
                  style: context.text.bodySmall?.copyWith(color: c.goldStrong),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: _msgs.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Задайте вопрос о вере, Писании или молитве',
                          textAlign: TextAlign.center,
                          style: context.text.bodyLarge?.copyWith(
                            color: c.textMuted,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _msgs.length,
                      itemBuilder: (context, i) {
                        final m = _msgs[i];
                        return m.fromUser
                            ? _UserBubble(m.text)
                            : _AiBubble(
                                msg: m,
                                onFollowUp: _send,
                                onRate: (r) => setState(() => m.rating = r),
                                onSpeak: () => showListenSheet(
                                  context,
                                  ref,
                                  title: 'Ответ помощника',
                                  text: m.text,
                                ),
                                onSave: () {
                                  if (m.text.trim().isEmpty) return;
                                  ref
                                      .read(myPrayersProvider.notifier)
                                      .add(
                                        MyPrayer(
                                          title: 'Ответ AI',
                                          text: m.text.trim(),
                                          aiGenerated: true,
                                        ),
                                      );
                                  showSnack(
                                    context,
                                    'Сохранено в «Мои молитвы»',
                                  );
                                },
                              );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: ChatInput(
                controller: _input,
                onSend: () => _send(_input.text),
                onMic: () async {
                  if (await dictateInto(context, _input) && mounted) {
                    _send(_input.text);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingCaret extends StatefulWidget {
  const _TypingCaret({required this.color});
  final Color color;

  @override
  State<_TypingCaret> createState() => _TypingCaretState();
}

class _TypingCaretState extends State<_TypingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.2, end: 1.0).animate(_c),
    child: Container(
      width: 2,
      height: 16,
      margin: const EdgeInsets.only(left: 2),
      color: widget.color,
    ),
  );
}

class _UserBubble extends StatelessWidget {
  const _UserBubble(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.colors.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: context.text.bodyLarge),
    ),
  );
}

class _AiBubble extends StatelessWidget {
  const _AiBubble({
    required this.msg,
    required this.onFollowUp,
    required this.onRate,
    required this.onSpeak,
    required this.onSave,
  });
  final _Msg msg;
  final ValueChanged<String> onFollowUp;
  final ValueChanged<int> onRate;
  final VoidCallback onSpeak;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AiBadge(label: 'AI-помощник'),
              const Spacer(),
              if (msg.streaming)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.gold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: Alignment.topLeft,
            child: Text.rich(
              TextSpan(
                style: t.bodyLarge?.copyWith(
                  color: msg.failed ? c.textMuted : null,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: msg.text.isEmpty && msg.streaming
                        ? ''
                        : (msg.text.isEmpty ? '…' : msg.text),
                  ),
                  if (msg.streaming)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: _TypingCaret(color: c.goldStrong),
                    ),
                ],
              ),
            ),
          ),
          if (msg.done && !msg.failed) ...[
            const SizedBox(height: 8),
            Text(
              'AI может ошибаться. Проверяйте важное по Писанию и у священника.',
              style: t.bodySmall?.copyWith(color: c.textMuted, fontSize: 11.5),
            ),
            if (msg.sources.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showSources(context),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.bookOpen,
                      size: 18,
                      color: c.goldStrong,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Показать источники (${msg.sources.length})',
                      style: t.bodyMedium?.copyWith(
                        color: c.goldStrong,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final f in const [
                        'Объясни проще',
                        'Что говорит Библия?',
                        'Традиция',
                        'Как применить в жизни?',
                      ])
                        SoftChip(label: f, onTap: () => onFollowUp(f)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Полезно',
                        onPressed: () => onRate(1),
                        icon: Icon(
                          msg.rating == 1
                              ? PhosphorIconsRegular.thumbsUp
                              : PhosphorIconsRegular.thumbsUp,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Не помогло',
                        onPressed: () => onRate(-1),
                        icon: Icon(
                          msg.rating == -1
                              ? PhosphorIconsRegular.thumbsDown
                              : PhosphorIconsRegular.thumbsDown,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Озвучить',
                        onPressed: onSpeak,
                        icon: const Icon(
                          PhosphorIconsRegular.speakerHigh,
                          size: 20,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Сохранить',
                        onPressed: onSave,
                        icon: const Icon(
                          PhosphorIconsRegular.bookmarkSimple,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSources(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Источники', style: sheet.text.titleLarge),
            const SizedBox(height: 10),
            for (final s in msg.sources)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  s.contains('подтверждено')
                      ? PhosphorIconsRegular.sealCheck
                      : PhosphorIconsRegular.question,
                  color: s.contains('подтверждено')
                      ? sheet.colors.success
                      : sheet.colors.textMuted,
                ),
                title: Text(s),
              ),
            const SizedBox(height: 4),
            Text(
              'Цитаты сверяются с базой источников. Непроверенное помечается.',
              style: sheet.text.bodySmall?.copyWith(
                color: sheet.colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
