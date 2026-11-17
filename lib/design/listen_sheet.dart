import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../app/theme.dart';
import '../core/ai_gate.dart';
import '../core/gemini_service.dart' show GeminiException;
import '../core/tts_service.dart';
import '../state/app_state.dart';
import 'widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Озвучить текст: шторка с плеером.
Future<void> showListenSheet(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String text,
}) async {
  if (!await ensureAiConsent(context, ref)) return;
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // Иначе на широких экранах Material сжимает шторку в «квадрат» по центру.
    constraints: const BoxConstraints(maxWidth: double.infinity),
    builder: (_) => _ListenSheet(title: title, text: text),
  );
}

class _ListenSheet extends ConsumerStatefulWidget {
  const _ListenSheet({required this.title, required this.text});
  final String title;
  final String text;

  @override
  ConsumerState<_ListenSheet> createState() => _ListenSheetState();
}

class _ListenSheetState extends ConsumerState<_ListenSheet> {
  final _player = AudioPlayer();
  String? _error;
  bool _loading = true;
  bool _bufferingMore = false;
  double _speed = 1;
  int _elapsedSec = 0;
  Timer? _tick;
  int _gen = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _startTick() {
    _tick?.cancel();
    _elapsedSec = 0;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSec++);
    });
  }

  Future<void> _load() async {
    final gen = ++_gen;
    setState(() {
      _loading = true;
      _bufferingMore = false;
      _error = null;
    });
    _startTick();
    await _player.stop();
    await _player.setAudioSources(const []);

    final voice = TtsVoice.values.asNameMap()[ref.read(sessionProvider).voice] ?? TtsVoice.primary;
    final chunks = TtsService.chunkText(widget.text);
    if (chunks.isEmpty) {
      _tick?.cancel();
      if (mounted) setState(() => _error = 'Нечего озвучивать');
      return;
    }

    final tts = ref.read(ttsServiceProvider);
    try {
      // Первый кусок — сразу в плеер, остальные догружаем в фоне.
      final first = await tts.synthesize(chunks.first, voice);
      if (!mounted || gen != _gen) return;

      await _player.setAudioSources([AudioSource.file(first.path)]);
      if (!mounted || gen != _gen) return;
      _tick?.cancel();
      setState(() {
        _loading = false;
        _bufferingMore = chunks.length > 1;
      });
      await _player.setSpeed(_speed);
      await _player.play();

      for (var i = 1; i < chunks.length; i++) {
        if (!mounted || gen != _gen) return;
        final file = await tts.synthesize(chunks[i], voice);
        if (!mounted || gen != _gen) return;
        await _player.addAudioSource(AudioSource.file(file.path));
      }
      if (mounted && gen == _gen) setState(() => _bufferingMore = false);
    } on GeminiException catch (e) {
      _tick?.cancel();
      if (mounted && gen == _gen) {
        setState(() {
          _error = e.message;
          _loading = true;
          _bufferingMore = false;
        });
      }
    } catch (_) {
      _tick?.cancel();
      if (mounted && gen == _gen) {
        setState(() {
          _error = 'Не удалось воспроизвести аудио. Попробуйте ещё раз.';
          _loading = true;
          _bufferingMore = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _gen++;
    _tick?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  Future<void> _seekBy(Duration delta) async {
    final pos = _player.position + delta;
    final total = _player.duration ?? Duration.zero;
    if (pos < Duration.zero) {
      final idx = _player.currentIndex ?? 0;
      if (idx > 0) {
        await _player.seek(Duration.zero, index: idx - 1);
      } else {
        await _player.seek(Duration.zero);
      }
      return;
    }
    if (total > Duration.zero && pos > total) {
      final idx = _player.currentIndex ?? 0;
      final count = _player.audioSources.length;
      if (idx + 1 < count) {
        await _player.seek(Duration.zero, index: idx + 1);
      } else {
        await _player.seek(total);
      }
      return;
    }
    await _player.seek(pos);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final long = widget.text.trim().length > 800;
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(widget.title, style: t.titleLarge, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Озвучка', style: t.bodySmall?.copyWith(color: c.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (_error != null) ...[
              Text(_error!, textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: c.textMuted)),
              const SizedBox(height: 12),
              TextButton(onPressed: _load, child: const Text('Попробовать ещё раз')),
            ] else if (_loading) ...[
              Center(child: CircularProgressIndicator(color: c.gold)),
              const SizedBox(height: 14),
              Text(
                _elapsedSec < 2 ? 'Готовим аудио…' : 'Готовим аудио… $_elapsedSec с',
                style: t.bodyMedium?.copyWith(color: c.textMuted),
                textAlign: TextAlign.center,
              ),
              if (long) ...[
                const SizedBox(height: 8),
                Text(
                  'Начинаем с первой фразы, остальное догрузится само.',
                  textAlign: TextAlign.center,
                  style: t.bodySmall?.copyWith(color: c.textMuted),
                ),
              ],
              const SizedBox(height: 8),
            ] else ...[
              StreamBuilder<Duration>(
                stream: _player.positionStream,
                builder: (context, snap) {
                  final pos = snap.data ?? Duration.zero;
                  final total = _player.duration ?? Duration.zero;
                  final max = total.inMilliseconds.toDouble().clamp(1, double.infinity).toDouble();
                  return Column(children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: c.gold,
                        inactiveTrackColor: c.chip,
                        thumbColor: c.goldStrong,
                        overlayColor: c.gold.withValues(alpha: 0.15),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: pos.inMilliseconds.toDouble().clamp(0, max),
                        max: max,
                        onChanged: (v) => _player.seek(Duration(milliseconds: v.round())),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_fmt(pos), style: t.bodySmall?.copyWith(color: c.textMuted)),
                        Text(
                          _bufferingMore ? '${_fmt(total)} · ещё…' : _fmt(total),
                          style: t.bodySmall?.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ]);
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Назад на 10 секунд',
                    onPressed: () => _seekBy(const Duration(seconds: -10)),
                    icon: const Icon(PhosphorIconsRegular.skipBack, size: 30),
                  ),
                  const SizedBox(width: 16),
                  StreamBuilder<PlayerState>(
                    stream: _player.playerStateStream,
                    builder: (context, snap) {
                      final state = snap.data;
                      final done = state?.processingState == ProcessingState.completed;
                      final playing = (state?.playing ?? false) && !done;
                      return GestureDetector(
                        onTap: () async {
                          if (done) await _player.seek(Duration.zero, index: 0);
                          playing ? await _player.pause() : await _player.play();
                        },
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: c.goldGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          ),
                          child: Icon(playing ? PhosphorIconsRegular.pause : PhosphorIconsRegular.play, color: c.onGold, size: 36),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    tooltip: 'Вперёд на 10 секунд',
                    onPressed: () => _seekBy(const Duration(seconds: 10)),
                    icon: const Icon(PhosphorIconsRegular.skipForward, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  for (final s in const [0.75, 1.0, 1.25, 1.5])
                    SoftChip(
                      label: '$s×',
                      selected: _speed == s,
                      onTap: () {
                        setState(() => _speed = s);
                        _player.setSpeed(s);
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}
