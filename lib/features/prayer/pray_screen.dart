import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/app_actions.dart';
import '../../data/mock_data.dart';
import '../../design/listen_sheet.dart';
import '../../design/widgets.dart';
import '../../state/app_state.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// PR-03 — чтение молитвы + «Молитва вместе» (PR-03a) и счётчик (PR-03b).
class PrayScreen extends ConsumerStatefulWidget {
  const PrayScreen({super.key, required this.prayerId});
  final String prayerId;

  @override
  ConsumerState<PrayScreen> createState() => _PrayScreenState();
}

class _PrayScreenState extends ConsumerState<PrayScreen> {
  late final Prayer _prayer = prayerById(widget.prayerId);
  late final List<String> _phrases = _prayer.text
      .split(RegExp(r'(?<=[;,!.:])\s+'))
      .where((s) => s.trim().isNotEmpty)
      .toList();
  bool _together = false;
  int _phrase = 0;
  int _count = 0;
  Timer? _timer;

  void _toggleTogether() {
    setState(() {
      _together = !_together;
      _phrase = 0;
    });
    _timer?.cancel();
    if (_together) {
      _timer = Timer.periodic(const Duration(milliseconds: 2600), (t) {
        if (_phrase >= _phrases.length - 1) {
          t.cancel();
          setState(() => _together = false);
        } else {
          setState(() => _phrase++);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final repeatable = widget.prayerId == 'jesus' || widget.prayerId == 'hail_mary';

    return Scaffold(
      appBar: appHeader(context, _prayer.title, actions: [
        IconButton(
          tooltip: ref.watch(favoritePrayersProvider).contains(widget.prayerId) ? 'Убрать из избранного' : 'В избранное',
          onPressed: () => ref.read(favoritePrayersProvider.notifier).toggle(widget.prayerId),
          icon: Icon(
            ref.watch(favoritePrayersProvider).contains(widget.prayerId) ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
            color: ref.watch(favoritePrayersProvider).contains(widget.prayerId) ? c.danger : null,
          ),
        ),
        IconButton(
          tooltip: 'Слушать',
          onPressed: () => showListenSheet(context, ref, title: _prayer.title, text: _prayer.text),
          icon: const Icon(PhosphorIconsRegular.speakerHigh),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          const Center(child: CrossMark(size: 36)),
          const SizedBox(height: 20),
          if (_together)
            for (var i = 0; i < _phrases.length; i++)
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: t.bodyLarge!.copyWith(
                  fontFamily: t.titleLarge?.fontFamily,
                  fontSize: 22,
                  height: 1.6,
                  color: i == _phrase ? c.text : c.textMuted.withValues(alpha: 0.5),
                  fontWeight: i == _phrase ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(_phrases[i]),
              )
          else
            Text(_prayer.text, style: t.bodyLarge?.copyWith(fontFamily: t.titleLarge?.fontFamily, fontSize: 22, height: 1.6)),
          if (_prayer.note != null) ...[
            const SizedBox(height: 16),
            Text(_prayer.note!, style: t.bodySmall?.copyWith(color: c.textMuted)),
          ],
          if (repeatable) ...[
            const SizedBox(height: 28),
            Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _count++);
                  if (_count % 10 == 0) HapticFeedback.heavyImpact();
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceWarm, border: Border.all(color: c.gold, width: 2)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_count', style: t.displaySmall?.copyWith(color: c.goldStrong)),
                      Text('нажмите', style: t.bodySmall?.copyWith(color: c.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: TextButton(onPressed: () => setState(() => _count = 0), child: const Text('Сбросить счётчик')),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: _together ? 'Остановить' : 'Молиться вместе',
                  leading: Icon(_together ? PhosphorIconsRegular.stop : PhosphorIconsRegular.play, color: c.goldStrong),
                  onPressed: _toggleTogether,
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'В мои молитвы',
                onPressed: () {
                  ref.read(myPrayersProvider.notifier).add(
                        MyPrayer(title: _prayer.title, text: _prayer.text),
                      );
                  showSnack(context, 'Сохранено в «Мои молитвы»');
                },
                icon: const Icon(PhosphorIconsRegular.bookmarkSimple),
              ),
              IconButton.outlined(
                tooltip: 'Поделиться',
                onPressed: () => shareText('${_prayer.title}\n\n${_prayer.text}', subject: _prayer.title),
                icon: const Icon(PhosphorIconsRegular.shareNetwork),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
