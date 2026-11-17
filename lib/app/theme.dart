import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Токены дизайн-системы «Слово»: cool parchment + ink + brass.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceWarm,
    required this.chip,
    required this.border,
    required this.gold,
    required this.goldStrong,
    required this.goldGradient,
    required this.onGold,
    required this.text,
    required this.textMuted,
    required this.aiTint,
    required this.success,
    required this.danger,
    required this.shadow,
  });

  final Color background;
  final Color surface;

  /// Тёплый, но не cream-peach акцент для цитат.
  final Color surfaceWarm;

  /// Невыбранные сегменты и поля поиска.
  final Color chip;
  final Color border;
  final Color gold;

  /// Brass для текста-ссылок.
  final Color goldStrong;

  /// Градиент основных кнопок.
  final List<Color> goldGradient;
  final Color onGold;
  final Color text;
  final Color textMuted;
  final Color aiTint;
  final Color success;
  final Color danger;
  final Color shadow;

  static const light = AppColors(
    background: Color(0xFFEFF2F5),
    surface: Color(0xFFFBFCFD),
    surfaceWarm: Color(0xFFE8EEF3),
    chip: Color(0xFFE4EAF0),
    border: Color(0xFFD2DAE3),
    gold: Color(0xFFC4A35A),
    goldStrong: Color(0xFF8B6B2E),
    goldGradient: [Color(0xFFCDB06A), Color(0xFFA07F3D)],
    onGold: Color(0xFFFFFCF5),
    text: Color(0xFF1B2430),
    textMuted: Color(0xFF6B7684),
    aiTint: Color(0xFFF2EBDA),
    success: Color(0xFF3F8F6E),
    danger: Color(0xFFC94A3D),
    shadow: Color(0x14202A38),
  );

  static const dark = AppColors(
    background: Color(0xFF12161C),
    surface: Color(0xFF1C222B),
    surfaceWarm: Color(0xFF252C36),
    chip: Color(0xFF2A323D),
    border: Color(0xFF3A4452),
    gold: Color(0xFFD4B56E),
    goldStrong: Color(0xFFD4B56E),
    goldGradient: [Color(0xFFD4B56E), Color(0xFFB08A42)],
    onGold: Color(0xFF12161C),
    text: Color(0xFFECE7DC),
    textMuted: Color(0xFFA8B0BC),
    aiTint: Color(0xFF2A261C),
    success: Color(0xFF7FB89A),
    danger: Color(0xFFE08B78),
    shadow: Color(0x40000000),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      other is AppColors && t > 0.5 ? other : this;
}

/// Шкала отступов.
abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const page = 20.0;
}

/// Скругления.
abstract final class AppRadius {
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const btn = 18.0;
  static const sheet = 24.0;
}

extension AppThemeX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}

/// Рукописный акцент для редких подписей.
TextStyle scriptStyle({double size = 26, Color? color}) =>
    GoogleFonts.marckScript(fontSize: size, color: color);

class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness b) {
    final body = GoogleFonts.sourceSans3TextTheme();
    final serif = GoogleFonts.cormorantGaramondTextTheme();
    final text = body
        .copyWith(
          displaySmall: serif.displaySmall?.copyWith(fontSize: 36, fontWeight: FontWeight.w600, height: 1.12),
          headlineMedium: serif.headlineMedium?.copyWith(fontSize: 30, fontWeight: FontWeight.w600, height: 1.2),
          headlineSmall: serif.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
          titleLarge: serif.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
          titleMedium: body.titleMedium?.copyWith(fontSize: 15.5, fontWeight: FontWeight.w600),
          bodyLarge: body.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
          bodyMedium: body.bodyMedium?.copyWith(fontSize: 14.5, height: 1.4),
          bodySmall: body.bodySmall?.copyWith(fontSize: 12.5, height: 1.35),
          labelLarge: body.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: c.text, displayColor: c.text);

    OutlineInputBorder border(Color color, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: color, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: c.background,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.gold,
        brightness: b,
        primary: c.goldStrong,
        onPrimary: c.onGold,
        surface: c.surface,
        onSurface: c.text,
      ),
      textTheme: text,
      iconTheme: IconThemeData(color: c.text, size: 24),
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.background.withValues(alpha: 0.92),
        foregroundColor: c.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        titleTextStyle: text.headlineSmall,
      ),
      dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        constraints: const BoxConstraints(maxWidth: double.infinity),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        showDragHandle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: text.bodyLarge?.copyWith(color: c.textMuted.withValues(alpha: 0.8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: border(Colors.transparent),
        enabledBorder: border(c.border),
        focusedBorder: border(c.gold, 1.4),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.onGold : null),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.gold : null),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? c.gold : null),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }
}
