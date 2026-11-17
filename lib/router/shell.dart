import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../app/theme.dart';

/// Плавающая нижняя навигация в закруглённом контейнере (liquid glass).
/// Состав вкладок — по ТЗ: Главная / Библия / Молитва / Спросить / Профиль.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const _items = [
    (PhosphorIconsRegular.house, PhosphorIconsFill.house, 'Главная'),
    (PhosphorIconsRegular.bookOpen, PhosphorIconsFill.bookOpen, 'Библия'),
    (PhosphorIconsRegular.flame, PhosphorIconsFill.flame, 'Молитва'),
    (PhosphorIconsRegular.chatCircle, PhosphorIconsFill.chatCircle, 'Спросить'),
    (PhosphorIconsRegular.user, PhosphorIconsFill.user, 'Профиль'),
  ];

  static const barHeight = 66.0;
  static const barBottom = 10.0;
  static const _barHPad = 18.0;

  /// Зазор под плавающую панель (для padding списков вне shell).
  static double contentBottomInset(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + barHeight + barBottom + 8;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mq = MediaQuery.of(context);
    final bottomInset = mq.padding.bottom;
    final clearance = barHeight + barBottom + 8;
    final glass = Color.alphaBlend(
      c.surface.withValues(alpha: 0.55),
      Colors.white.withValues(alpha: 0.35),
    );

    return Scaffold(
      extendBody: true,
      body: MediaQuery(
        // Увеличиваем нижний safe-padding, чтобы списки/SafeArea не уезжали под панель.
        data: mq.copyWith(
          padding: mq.padding.copyWith(bottom: bottomInset + clearance),
        ),
        child: Builder(
          builder: (context) => SafeArea(
            // Один раз оставляем место снизу для всех вкладок.
            top: false,
            left: false,
            right: false,
            child: MediaQuery.removePadding(
              // Чтобы вложенные SafeArea не удваивали нижний отступ.
              context: context,
              removeBottom: true,
              child: shell,
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(_barHPad, 0, _barHPad, bottomInset + barBottom),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: glass,
                border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
                boxShadow: [
                  BoxShadow(color: c.shadow.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10)),
                ],
              ),
              child: SizedBox(
                height: barHeight,
                child: Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        child: _NavItem(
                          icon: _items[i].$1,
                          selectedIcon: _items[i].$2,
                          label: _items[i].$3,
                          selected: i == shell.currentIndex,
                          onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = selected ? c.goldStrong : c.textMuted;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? c.gold.withValues(alpha: 0.14) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedScale(
                scale: selected ? 1.06 : 1,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: Icon(selected ? selectedIcon : icon, color: color, size: 24),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall?.copyWith(
                fontSize: 10.5,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
