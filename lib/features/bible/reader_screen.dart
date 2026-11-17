import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/ai_gate.dart';
import '../../core/app_actions.dart';
import '../../core/gemini_service.dart';
import '../../core/smooth_stream.dart';
import '../../data/mock_data.dart';
import '../../design/listen_sheet.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// BIB-03 — чтение (макет, экран 7). Нумерация псалмов — по традиции.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.bookId,
    required this.chapter,
    this.verse,
  });
  final String bookId;
  final int chapter;

  /// Стих, к которому прокрутить (из поиска).
  final int? verse;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  double _scale = 1;
  final _scroll = ScrollController();
  final _verseKeys = <int, GlobalKey>{};
  int _lastVerse = 1;
  Timer? _saveDebounce;
  Offset? _swipeStart;

  @override
  void initState() {
    super.initState();
    _lastVerse = widget.verse ?? 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveProgress(_lastVerse);
      final target = widget.verse;
      if (target != null) {
        final ctx = _verseKeys[target]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.2,
            duration: const Duration(milliseconds: 300),
          );
        }
      }
    });
  }

  String get _key => '${widget.bookId}:${widget.chapter}';

  void _edit(ChapterMarks Function(ChapterMarks m) fn) =>
      ref.read(readerMarksProvider.notifier).edit(_key, fn);

  void _saveProgress(int verse, {bool immediate = false}) {
    _lastVerse = verse;
    void flush() {
      ref
          .read(readingProgressProvider.notifier)
          .save(bookId: widget.bookId, chapter: widget.chapter, verse: verse);
    }

    if (immediate) {
      _saveDebounce?.cancel();
      flush();
      return;
    }
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 350), flush);
  }

  void _onScroll() {
    if (!_scroll.hasClients || !mounted) return;
    final threshold = MediaQuery.paddingOf(context).top + 120;
    var current = _lastVerse;
    for (final e in _verseKeys.entries) {
      final ctx = e.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) continue;
      if (box.localToGlobal(Offset.zero).dy <= threshold) current = e.key;
    }
    if (current != _lastVerse) _saveProgress(current);
  }

  void _goChapter(int ch) {
    final book = bookById(widget.bookId);
    if (ch < 1 || ch > book.chapters) return;
    _saveProgress(_lastVerse, immediate: true);
    context.pushReplacement('/read/${widget.bookId}/$ch');
  }

  void _onPointerDown(PointerDownEvent e) => _swipeStart = e.position;

  void _onPointerUp(PointerUpEvent e) {
    final start = _swipeStart;
    _swipeStart = null;
    if (start == null) return;
    final d = e.position - start;
    // Только явный горизонтальный свайп — вертикальный скролл не трогаем.
    if (d.dx.abs() < 72 || d.dx.abs() < d.dy.abs() * 1.6) return;
    if (d.dx < 0) {
      _goChapter(widget.chapter + 1);
    } else {
      _goChapter(widget.chapter - 1);
    }
  }

  void _onPointerCancel(PointerCancelEvent e) => _swipeStart = null;

  @override
  void dispose() {
    _saveDebounce?.cancel();
    // Синхронно сохраняем позицию при уходе с экрана.
    ref
        .read(readingProgressProvider.notifier)
        .save(
          bookId: widget.bookId,
          chapter: widget.chapter,
          verse: _lastVerse,
        );
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final tradition = ref.watch(sessionProvider).tradition;
    final marks = ref.watch(readerMarksProvider)[_key] ?? const ChapterMarks();
    final book = bookById(widget.bookId);
    final verses = chapterText(widget.bookId, widget.chapter, tradition);
    final title = chapterTitle(book, widget.chapter, tradition);

    return Scaffold(
      appBar: appHeader(
        context,
        title,
        serif: false,
        actions: [
          IconButton(
            tooltip: 'Размер текста',
            onPressed: _showTextSettings,
            icon: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'A ',
                    style: t.bodySmall?.copyWith(fontSize: 12),
                  ),
                  TextSpan(
                    text: 'A',
                    style: t.bodyLarge?.copyWith(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Слушать главу',
            onPressed: () {
              final vs = chapterText(widget.bookId, widget.chapter, tradition);
              if (vs != null) {
                showListenSheet(
                  context,
                  ref,
                  title: title,
                  text: vs.map((v) => v.text).join(' '),
                );
              }
            },
            icon: const Icon(PhosphorIconsRegular.speakerHigh),
          ),
        ],
      ),
      body: Listener(
        // Listener не участвует в gesture arena — в отличие от GestureDetector
        // не блокирует вертикальный скролл ListView.
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: verses == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Не удалось открыть главу. Попробуйте выбрать её из списка книг.',
                    textAlign: TextAlign.center,
                    style: t.bodyLarge?.copyWith(color: c.textMuted),
                  ),
                ),
              )
            : NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollUpdateNotification ||
                      n is ScrollEndNotification) {
                    _onScroll();
                  }
                  return false;
                },
                child: ListView.builder(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  itemCount: verses.length,
                  itemBuilder: (context, i) {
                    final v = verses[i];
                    return GestureDetector(
                      key: _verseKeys.putIfAbsent(v.n, GlobalKey.new),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showVerseMenu(v, title),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: marks.highlights.contains(v.n)
                              ? const Color(0xFFF6E3B5)
                              : (v.n == widget.verse
                                    ? c.gold.withValues(alpha: 0.12)
                                    : null),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${v.n} ${v.text}',
                          style: t.bodyLarge?.copyWith(
                            fontFamily: t.titleLarge?.fontFamily,
                            fontSize: 19 * _scale,
                            height: 1.5,
                            color: c.text,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Нравится',
                onPressed: () => _edit((m) => m.copyWith(liked: !m.liked)),
                icon: Icon(
                  marks.liked
                      ? PhosphorIconsFill.heart
                      : PhosphorIconsRegular.heart,
                  color: marks.liked
                      ? c.danger
                      : c.text.withValues(alpha: 0.75),
                  size: 27,
                ),
              ),
              IconButton(
                tooltip: 'Закладка',
                onPressed: () =>
                    _edit((m) => m.copyWith(bookmarked: !m.bookmarked)),
                icon: Icon(
                  marks.bookmarked
                      ? PhosphorIconsFill.bookmarkSimple
                      : PhosphorIconsRegular.bookmarkSimple,
                  color: marks.bookmarked
                      ? c.gold
                      : c.text.withValues(alpha: 0.75),
                  size: 26,
                ),
              ),
              IconButton(
                tooltip: 'Спросить AI о главе',
                onPressed: () => context.push(
                  '/chat?q=${Uri.encodeComponent('Объясни: $title')}',
                ),
                icon: Icon(
                  PhosphorIconsRegular.sparkle,
                  color: c.text.withValues(alpha: 0.75),
                  size: 25,
                ),
              ),
              IconButton(
                tooltip: 'Поделиться',
                onPressed: () {
                  final vs = chapterText(
                    widget.bookId,
                    widget.chapter,
                    tradition,
                  );
                  if (vs == null) return;
                  shareText(
                    '$title\n\n${vs.map((v) => '${v.n}. ${v.text}').join('\n')}',
                    subject: title,
                  );
                },
                icon: Icon(
                  PhosphorIconsRegular.shareNetwork,
                  color: c.text.withValues(alpha: 0.75),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTextSettings() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Размер текста', style: context.text.titleLarge),
              Slider(
                value: _scale,
                min: 0.85,
                max: 1.6,
                divisions: 6,
                activeColor: context.colors.goldStrong,
                onChanged: (v) {
                  setSheet(() {});
                  setState(() => _scale = v);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _showVerseMenu(Verse v, String title) {
    final host = context;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$title, стих ${v.n}', style: sheet.text.titleMedium),
              const SizedBox(height: 6),
              Text(
                v.text,
                style: sheet.text.bodyMedium?.copyWith(
                  color: sheet.colors.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Объяснить с AI',
                icon: PhosphorIconsRegular.sparkle,
                onPressed: () {
                  Navigator.pop(sheet);
                  _showExplain(v, title);
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SoftChip(
                    icon: PhosphorIconsRegular.paintBrush,
                    label:
                        (ref
                                .read(readerMarksProvider)[_key]
                                ?.highlights
                                .contains(v.n) ??
                            false)
                        ? 'Снять выделение'
                        : 'Выделить',
                    onTap: () {
                      _edit(
                        (m) => m.copyWith(
                          highlights: m.highlights.contains(v.n)
                              ? ({...m.highlights}..remove(v.n))
                              : {...m.highlights, v.n},
                        ),
                      );
                      Navigator.pop(sheet);
                    },
                  ),
                  SoftChip(
                    icon: PhosphorIconsRegular.bookmarkSimple,
                    label: 'Закладка',
                    onTap: () {
                      _edit((m) => m.copyWith(bookmarked: true));
                      Navigator.pop(sheet);
                    },
                  ),
                  SoftChip(
                    icon: PhosphorIconsRegular.copy,
                    label: 'Копировать',
                    onTap: () {
                      final text = '$title:${v.n}\n${v.text}';
                      Navigator.pop(sheet);
                      copyText(host, text);
                    },
                  ),
                  SoftChip(
                    icon: PhosphorIconsRegular.shareNetwork,
                    label: 'Поделиться',
                    onTap: () {
                      Navigator.pop(sheet);
                      shareText(
                        '$title:${v.n}\n${v.text}',
                        subject: '$title:${v.n}',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// BIB-05 — AI-анализ стиха через Gemini.
  Future<void> _showExplain(Verse v, String title) async {
    if (!await ensureAiConsent(context, ref)) return;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _VerseExplainSheet(
        title: title,
        verse: v,
        tradition: ref.read(sessionProvider).specialDataConsent
            ? ref.read(sessionProvider).tradition
            : Tradition.undecided,
      ),
    );
  }
}

class _VerseExplainSheet extends ConsumerStatefulWidget {
  const _VerseExplainSheet({
    required this.title,
    required this.verse,
    required this.tradition,
  });
  final String title;
  final Verse verse;
  final Tradition tradition;

  @override
  ConsumerState<_VerseExplainSheet> createState() => _VerseExplainSheetState();
}

class _VerseExplainSheetState extends ConsumerState<_VerseExplainSheet> {
  String _text = '';
  bool _loading = true;
  bool _failed = false;
  StreamSubscription<String>? _sub;
  SmoothStreamBuffer? _reveal;

  @override
  void initState() {
    super.initState();
    final prompt =
        'Объясни стих ${widget.title}:${widget.verse.n}: «${widget.verse.text}». '
        'Коротко и по делу: 1) простой смысл, 2) контекст, 3) как применить в жизни. '
        'Не выдумывай цитаты. Если не уверен — скажи об этом.';
    _reveal = SmoothStreamBuffer(
      onUpdate: () {
        if (!mounted) return;
        setState(() => _text = _reveal!.visible);
      },
      onCaughtUp: () {
        if (!mounted) return;
        setState(() => _loading = false);
      },
    );
    _sub = ref
        .read(geminiServiceProvider)
        .streamReply(
          history: [ChatTurn(fromUser: true, text: prompt)],
          tradition: widget.tradition,
        )
        .listen(
          (chunk) => _reveal?.add(chunk),
          onError: (Object e) => setState(() {
            _failed = true;
            _loading = false;
            _text = e is GeminiException
                ? e.message
                : 'Не удалось получить объяснение';
          }),
          onDone: () => _reveal?.markStreamDone(),
          cancelOnError: true,
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _reveal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.title}, ${widget.verse.n}',
                  style: t.titleLarge,
                ),
              ),
              const AiBadge(),
            ],
          ),
          const SizedBox(height: 8),
          AppCard(
            color: c.surfaceWarm,
            child: Text(
              widget.verse.text,
              style: t.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading && _text.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(color: c.gold),
              ),
            )
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              alignment: Alignment.topLeft,
              child: Text(
                _text.isEmpty ? '…' : _text,
                style: t.bodyLarge?.copyWith(
                  color: _failed ? c.textMuted : null,
                  height: 1.45,
                ),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            'AI может ошибаться. Сверяйте важное с Писанием и священником.',
            style: t.bodySmall?.copyWith(color: c.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
