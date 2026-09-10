import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Doodle Pad 디자인 토큰.
///
/// 방향: "종이 + 잉크". 따뜻한 종이색 표면 위에 잉크 블루 하나만 강조색으로 쓰고,
/// 그림 도구(크레용 노랑·초록)는 보조색으로만 아껴 쓴다. 장식용 그라데이션·글로우는
/// 쓰지 않고, 헤어라인(1px outlineVariant)과 표면 단계(surfaceContainer*)로만
/// 위계를 만든다.
abstract final class AppTheme {
  // 반경 — 한 화면 안에서 3단계만 쓴다.
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2F4FBF),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDDE4FF),
    onPrimaryContainer: Color(0xFF0F2470),
    secondary: Color(0xFFB9761A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFFFE1B3),
    onSecondaryContainer: Color(0xFF4A2E00),
    tertiary: Color(0xFF2B7A57),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFC8F0DA),
    onTertiaryContainer: Color(0xFF06371F),
    error: Color(0xFFC4342B),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD5),
    onErrorContainer: Color(0xFF5A0F0A),
    surface: Color(0xFFFBF9F4),
    onSurface: Color(0xFF1E1B16),
    onSurfaceVariant: Color(0xFF5D5A52),
    surfaceDim: Color(0xFFDAD6CD),
    surfaceBright: Color(0xFFFBF9F4),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF4F1EA),
    surfaceContainer: Color(0xFFEEEAE2),
    surfaceContainerHigh: Color(0xFFE7E3DA),
    surfaceContainerHighest: Color(0xFFDFDBD1),
    outline: Color(0xFF7C786E),
    outlineVariant: Color(0xFFD9D4C9),
    inverseSurface: Color(0xFF33302A),
    onInverseSurface: Color(0xFFF5F2EB),
    inversePrimary: Color(0xFFB5C4FF),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFF2F4FBF),
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFB5C4FF),
    onPrimary: Color(0xFF0B1F66),
    primaryContainer: Color(0xFF26429E),
    onPrimaryContainer: Color(0xFFDDE4FF),
    secondary: Color(0xFFF0BF74),
    onSecondary: Color(0xFF3E2600),
    secondaryContainer: Color(0xFF5C3F0A),
    onSecondaryContainer: Color(0xFFFFE1B3),
    tertiary: Color(0xFF8FD8B2),
    onTertiary: Color(0xFF003822),
    tertiaryContainer: Color(0xFF1D5C3F),
    onTertiaryContainer: Color(0xFFC8F0DA),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF16140F),
    onSurface: Color(0xFFEAE6DD),
    onSurfaceVariant: Color(0xFFC9C4B8),
    surfaceDim: Color(0xFF16140F),
    surfaceBright: Color(0xFF3D3931),
    surfaceContainerLowest: Color(0xFF100E0A),
    surfaceContainerLow: Color(0xFF1E1B16),
    surfaceContainer: Color(0xFF23201A),
    surfaceContainerHigh: Color(0xFF2D2A23),
    surfaceContainerHighest: Color(0xFF38342C),
    outline: Color(0xFF938E82),
    outlineVariant: Color(0xFF48443C),
    inverseSurface: Color(0xFFEAE6DD),
    onInverseSurface: Color(0xFF33302A),
    inversePrimary: Color(0xFF2F4FBF),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0xFFB5C4FF),
  );

  static final ThemeData light = _finish(
    FlexThemeData.light(
      colorScheme: lightScheme,
      blendLevel: 0,
      subThemesData: _subThemes,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    ),
  );

  static final ThemeData dark = _finish(
    FlexThemeData.dark(
      colorScheme: darkScheme,
      blendLevel: 0,
      subThemesData: _subThemes,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    ),
  );

  static const FlexSubThemesData _subThemes = FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    useM2StyleDividerInM3: true,
    inputDecoratorIsFilled: true,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    alignedDropdown: true,
    // AppBar는 색을 칠하지 않는다. 표면과 같은 종이색 + 잉크색 아이콘.
    appBarCenterTitle: false,
    appBarScrolledUnderElevation: 0,
    appBarBackgroundSchemeColor: SchemeColor.surface,
    appBarForegroundSchemeColor: SchemeColor.onSurface,
    appBarIconSchemeColor: SchemeColor.onSurface,
    listTileIconSchemeColor: SchemeColor.onSurfaceVariant,
    bottomNavigationBarElevation: 0,
    bottomSheetBackgroundColor: SchemeColor.surface,
    bottomSheetModalBackgroundColor: SchemeColor.surface,
    dialogBackgroundSchemeColor: SchemeColor.surface,
    dialogElevation: 0,
    defaultRadius: radiusMd,
    cardRadius: radiusMd,
    dialogRadius: radiusLg,
    bottomSheetRadius: radiusLg,
    fabRadius: radiusMd,
    elevatedButtonRadius: radiusMd,
    filledButtonRadius: radiusMd,
    outlinedButtonRadius: radiusMd,
    textButtonRadius: radiusSm,
    chipRadius: 999,
    // 선택 = 잉크 블루. 칩도 예외 없이 같은 규칙을 따른다.
    chipSelectedSchemeColor: SchemeColor.primaryContainer,
    chipSecondarySelectedSchemeColor: SchemeColor.primaryContainer,
    thickBorderWidth: 1.5,
    thinBorderWidth: 1,
  );

  static const PageTransitionsTheme _transitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
    },
  );

  static ThemeData _finish(ThemeData theme) {
    final cs = theme.colorScheme;
    final text = theme.textTheme;
    return theme.copyWith(
      pageTransitionsTheme: _transitions,
      scaffoldBackgroundColor: cs.surface,
      dividerColor: cs.outlineVariant,
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          height: 1.15,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          height: 1.2,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
        labelSmall: text.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: cs.onSurface,
        ),
      ),
      sliderTheme: theme.sliderTheme.copyWith(
        trackHeight: 4,
        activeTrackColor: cs.onSurface,
        inactiveTrackColor: cs.surfaceContainerHighest,
        thumbColor: cs.onSurface,
        overlayColor: cs.onSurface.withValues(alpha: 0.08),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      switchTheme: theme.switchTheme.copyWith(
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : cs.outlineVariant,
        ),
      ),
    );
  }
}

abstract final class AppFlexTheme {
  static ThemeData get light => AppTheme.light;
  static ThemeData get dark => AppTheme.dark;
}
