import 'dart:async';
import 'dart:math' as math;

/// Плавно показывает текст из SSE-чанков: буферизует приход и выдаёт понемногу.
class SmoothStreamBuffer {
  SmoothStreamBuffer({
    required this.onUpdate,
    this.onCaughtUp,
    this.charsPerTick = 3,
    this.tick = const Duration(milliseconds: 20),
  });

  final void Function() onUpdate;
  final void Function()? onCaughtUp;
  int charsPerTick;
  final Duration tick;

  String visible = '';
  String _pending = '';
  Timer? _timer;
  bool _streamDone = false;
  bool _notified = false;

  bool get isCaughtUp => _streamDone && _pending.isEmpty;

  void add(String chunk) {
    if (chunk.isEmpty) return;
    _pending += chunk;
    _ensureTimer();
  }

  void markStreamDone() {
    _streamDone = true;
    // Добиваем хвост чуть быстрее, но всё ещё плавно.
    charsPerTick = math.max(charsPerTick, 6);
    _ensureTimer();
    if (_pending.isEmpty) _finish();
  }

  /// Мгновенно показать всё (ошибка / отмена).
  void flush() {
    visible += _pending;
    _pending = '';
    _streamDone = true;
    _timer?.cancel();
    _timer = null;
    onUpdate();
    _finish();
  }

  void _ensureTimer() {
    _timer ??= Timer.periodic(tick, (_) => _tick());
  }

  void _tick() {
    if (_pending.isEmpty) {
      if (_streamDone) {
        _timer?.cancel();
        _timer = null;
        _finish();
      }
      return;
    }
    var n = math.min(charsPerTick, _pending.length);
    // Стараемся не рвать слово посередине, если в окне есть пробел.
    if (n < _pending.length && n > 1) {
      final window = _pending.substring(0, n);
      final space = window.lastIndexOf(' ');
      if (space > n ~/ 3) n = space + 1;
    }
    visible += _pending.substring(0, n);
    _pending = _pending.substring(n);
    onUpdate();
    if (_pending.isEmpty && _streamDone) {
      _timer?.cancel();
      _timer = null;
      _finish();
    }
  }

  void _finish() {
    if (_notified) return;
    _notified = true;
    onCaughtUp?.call();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
