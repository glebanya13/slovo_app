import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Шапка в языке glass-nav: frost + полупрозрачный surface.
PreferredSizeWidget appHeader(
  BuildContext context,
  String title, {
  List<Widget> actions = const [],
  bool serif = true,
}) {
  final canPop = GoRouter.of(context).canPop();
  final c = context.colors;
  return PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 60,
          titleSpacing: canPop ? 0 : 20,
          backgroundColor: Color.alphaBlend(c.surface.withValues(alpha: 0.72), c.background.withValues(alpha: 0.35)),
          leading: canPop
              ? IconButton(
                  tooltip: 'Назад',
                  onPressed: () => context.pop(),
                  icon: const Icon(PhosphorIconsRegular.caretLeft, size: 20),
                )
              : null,
          title: Text(
            title,
            style: serif ? context.text.headlineSmall : context.text.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          actions: [...actions, const SizedBox(width: 8)],
        ),
      ),
    ),
  );
}

/// Кастомный переключатель в тоне бренда (вместо Material Switch).
class BrandToggle extends StatelessWidget {
  const BrandToggle({super.key, required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onChanged != null;
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 48,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: value ? c.gold : c.chip,
            border: Border.all(color: value ? c.goldStrong.withValues(alpha: 0.35) : c.border),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? c.onGold : c.surface,
                boxShadow: [BoxShadow(color: c.shadow, blurRadius: 4, offset: const Offset(0, 1))],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Плоская секция строк с разделителями (без карточной тени).
class FlatSection extends StatelessWidget {
  const FlatSection({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final border = context.colors.border.withValues(alpha: 0.85);
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, color: border),
          children[i],
        ],
      ],
    );
  }
}

/// Диалог подтверждения в стиле приложения.
Future<bool> showBrandConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  bool danger = false,
}) async {
  final c = context.colors;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.xxl, AppSpace.lg, AppSpace.xxl, AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: sheet.text.headlineSmall),
            const SizedBox(height: AppSpace.md),
            Text(body, style: sheet.text.bodyLarge?.copyWith(color: c.textMuted, height: 1.45)),
            const SizedBox(height: AppSpace.xxl),
            PrimaryButton(
              label: action,
              onPressed: () => Navigator.pop(sheet, true),
            ),
            const SizedBox(height: AppSpace.sm),
            TextButton(
              onPressed: () => Navigator.pop(sheet, false),
              child: Text('Отмена', style: sheet.text.bodyMedium?.copyWith(color: c.textMuted)),
            ),
          ],
        ),
      ),
    ),
  );
  return ok == true;
}

/// Золотой крест из макета.
class CrossMark extends StatelessWidget {
  const CrossMark({super.key, this.size = 40, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(size * 0.62, size),
        painter: _CrossPainter(color ?? context.colors.gold),
      );
}

class _CrossPainter extends CustomPainter {
  _CrossPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(color, Colors.white, 0.45)!, color, Color.lerp(color, Colors.brown, 0.25)!],
      ).createShader(Offset.zero & s);
    final w = s.width * 0.17;
    canvas.drawShadow(
      Path()..addRect(Rect.fromLTWH((s.width - w) / 2, 0, w, s.height)),
      color.withValues(alpha: 0.6),
      3,
      false,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH((s.width - w) / 2, 0, w, s.height), Radius.circular(w / 3)),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, s.height * 0.27, s.width, w), Radius.circular(w / 3)),
      p,
    );
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.color != color;
}

/// Мягкий mist-фон (для экранов без фото).
class DawnBackground extends StatelessWidget {
  const DawnBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(c.surfaceWarm, Colors.white, 0.55)!, c.background],
        ),
      ),
      child: child,
    );
  }
}

/// Золотая градиентная кнопка (макет: «Далее», «Войти», «Сохранить запись»).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon, this.width});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Container(
        width: width ?? double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.btn),
          gradient: enabled
              ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: c.goldGradient)
              : null,
          color: enabled ? null : c.chip,
          boxShadow: enabled
              ? [BoxShadow(color: c.gold.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 5))]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.btn),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: context.text.labelLarge?.copyWith(color: enabled ? c.onGold : c.textMuted, fontSize: 17)),
                if (icon != null) ...[
                  const SizedBox(width: 10),
                  Icon(icon, size: 20, color: enabled ? c.onGold : c.textMuted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Белая кнопка с тонкой рамкой (макет: «Продолжить с Apple»).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.leading});
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: c.surface,
          foregroundColor: c.text,
          side: BorderSide(color: c.border, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.btn)),
          textStyle: context.text.labelLarge?.copyWith(fontSize: 15.5),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// Карточка: elevated — для CTA; иначе лёгкая рамка без тени.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.gradient,
    this.radius = AppRadius.lg,
    this.elevated = false,
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final Gradient? gradient;
  final double radius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? c.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: elevated ? null : Border.all(color: c.border.withValues(alpha: 0.85)),
        boxShadow: elevated ? [BoxShadow(color: c.shadow, blurRadius: 14, offset: const Offset(0, 5))] : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 0, 12),
        child: Row(
          children: [
            Expanded(child: Text(title, style: context.text.titleLarge)),
            if (action != null)
              GestureDetector(
                onTap: onAction,
                child: Text(action!, style: context.text.bodyMedium?.copyWith(color: context.colors.goldStrong, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      );
}

/// Персиковая карточка цитаты с сердечком (макет, экраны 5, 8, 13).
class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key, required this.text, required this.reference, this.onTap});
  final String text;
  final String reference;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      elevated: true,
      color: c.surfaceWarm,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
      child: Stack(
        children: [
          Positioned(left: -6, top: -6, child: Icon(PhosphorIconsRegular.quotes, size: 18, color: c.gold.withValues(alpha: 0.7))),
          Column(
            children: [
              const SizedBox(height: 4),
              Text(
                '«$text»',
                textAlign: TextAlign.center,
                style: context.text.bodyLarge?.copyWith(fontSize: 15.5, height: 1.5, color: c.text),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(reference, style: context.text.bodySmall?.copyWith(color: c.textMuted)),
                  const SizedBox(width: 5),
                  Icon(PhosphorIconsRegular.heart, size: 13, color: c.gold),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Пастельные палитры кружков из макета (Библия, Молитва, Планы, Дневник…).
class Pastel {
  const Pastel(this.bg, this.fg);
  final List<Color> bg;
  final Color fg;

  static const peach = Pastel([Color(0xFFE8F0E6), Color(0xFFD5E4D1)], Color(0xFF5B7A52));
  static const mint = Pastel([Color(0xFFDDF2E8), Color(0xFFC2E6D4)], Color(0xFF3E9B74));
  static const lavender = Pastel([Color(0xFFE0EEFA), Color(0xFFC8E0F5)], Color(0xFF3F84C4)); // cool mist, не purple
  static const honey = Pastel([Color(0xFFF2EBDA), Color(0xFFE6D8B8)], Color(0xFF8B6B2E));
  static const sky = Pastel([Color(0xFFE0EEFA), Color(0xFFC8E0F5)], Color(0xFF3F84C4));
  static const rose = Pastel([Color(0xFFF3E4E2), Color(0xFFE6CFCB)], Color(0xFFB05A52));
  static const sand = Pastel([Color(0xFFE8EEF3), Color(0xFFD5DEE8)], Color(0xFF6B7684));
}

class PastelIcon extends StatelessWidget {
  const PastelIcon(this.icon, this.pastel, {super.key, this.size = 58, this.square = false});
  final IconData icon;
  final Pastel pastel;
  final double size;
  final bool square;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: square ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: square ? BorderRadius.circular(size * 0.26) : null,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: pastel.bg),
        ),
        child: Icon(icon, color: pastel.fg, size: size * 0.46),
      );
}

/// Круглая иконка с подписью — быстрые действия (макет, экран 5).
class ActionTile extends StatelessWidget {
  const ActionTile({super.key, required this.icon, required this.label, required this.pastel, this.onTap});
  final IconData icon;
  final String label;
  final Pastel pastel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              PastelIcon(icon, pastel, size: 62),
              const SizedBox(height: 8),
              Text(label, style: context.text.bodySmall?.copyWith(fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

class ListRowCard extends StatelessWidget {
  const ListRowCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
  });
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleMedium),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: context.text.bodySmall?.copyWith(color: c.textMuted, fontSize: 13)),
                  ],
                ],
              ),
            ),
            trailing ?? Icon(PhosphorIconsRegular.caretRight, color: c.textMuted.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

/// Строка настроек: линейная иконка, название, значение, шеврон (макет, экраны 12, 15).
class SettingsTile extends StatelessWidget {
  const SettingsTile({super.key, required this.icon, required this.title, this.value, this.subtitle, this.onTap, this.iconColor, this.trailing});
  final IconData icon;
  final String title;
  final String? value;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListRowCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      leading: Icon(icon, size: 23, color: iconColor ?? c.text.withValues(alpha: 0.8)),
      title: title,
      subtitle: subtitle,
      trailing: trailing ??
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (value != null) Text(value!, style: context.text.bodyMedium?.copyWith(color: c.textMuted)),
            Icon(PhosphorIconsRegular.caretRight, color: c.textMuted.withValues(alpha: 0.7)),
          ]),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.tint, this.size = 44});
  final IconData icon;
  final Color? tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = tint ?? context.colors.gold;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: t.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(size / 3.2)),
      child: Icon(icon, color: t, size: size * 0.52),
    );
  }
}

/// Группа строк в одной карточке (настройки, профиль).
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: EdgeInsets.zero,
        elevated: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(indent: 16, endIndent: 16, color: context.colors.border.withValues(alpha: 0.8)),
                children[i],
              ],
            ],
          ),
        ),
      );
}

/// Текстовые сегменты с подчёркиванием (без stadium-пилюль).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.labels, required this.index, required this.onChanged});
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == index ? c.goldStrong : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: context.text.bodyMedium?.copyWith(
                      color: i == index ? c.text : c.textMuted,
                      fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Поле поиска на бежевом фоне (макет, экран 6).
class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.hint, this.onSubmitted, this.onChanged});
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        fillColor: c.chip,
        prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, color: c.textMuted),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class AiBadge extends StatelessWidget {
  const AiBadge({super.key, this.label = 'AI'});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.aiTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: context.text.bodySmall?.copyWith(color: c.goldStrong, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Пастельный чип категории (макет, экран 8).
class PastelChip extends StatelessWidget {
  const PastelChip({super.key, required this.label, required this.icon, required this.pastel, this.onTap});
  final String label;
  final IconData icon;
  final Pastel pastel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: pastel.bg.first.withValues(alpha: 0.75),
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: pastel.fg),
                const SizedBox(width: 8),
                Text(label, style: context.text.bodyMedium?.copyWith(color: Color.lerp(pastel.fg, Colors.black, 0.35), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      );
}

class SoftChip extends StatelessWidget {
  const SoftChip({super.key, required this.label, this.icon, this.onTap, this.selected = false});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        gradient: selected ? LinearGradient(colors: c.goldGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
        color: selected ? null : c.chip,
        border: selected ? null : Border.all(color: c.border),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: selected ? c.onGold : c.gold), const SizedBox(width: 7)],
                Flexible(child: Text(label, style: context.text.bodyMedium?.copyWith(color: selected ? c.onGold : c.text, fontWeight: FontWeight.w500))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Поле ввода AI с микрофоном и постоянной подписью (раздел 7 ТЗ).
class ChatInput extends StatelessWidget {
  const ChatInput({super.key, required this.controller, required this.onSend, this.hint = 'Задайте вопрос о вере…', this.onMic});
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onMic;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.btn),
                  border: Border.all(color: c.border),
                ),
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: hint,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.btn), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.btn), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      tooltip: 'Сказать голосом',
                      icon: Icon(PhosphorIconsRegular.microphone, color: c.goldStrong),
                      onPressed: onMic,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onSend,
              child: Semantics(
                button: true,
                label: 'Отправить',
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: c.goldGradient, begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    boxShadow: [BoxShadow(color: c.gold.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Icon(PhosphorIconsRegular.arrowUp, color: c.onGold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Я AI-помощник, не священник и не заменяю священнослужителя',
          style: context.text.bodySmall?.copyWith(color: c.textMuted, fontSize: 11.5),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Фото из assets/images (Unsplash, см. CREDITS.md).
class Photo extends StatelessWidget {
  const Photo(this.name, {super.key, this.radius = 16, this.width, this.height, this.alignment = Alignment.center});
  final String name;
  final double radius;
  final double? width;
  final double? height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/images/$name.jpg',
          width: width,
          height: height,
          fit: BoxFit.cover,
          alignment: alignment,
          filterQuality: FilterQuality.medium,
        ),
      );
}

void showSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what — в следующей итерации')));
}
