import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const FlexScheme _scheme = FlexScheme.shadOrange;

  static final ThemeData light = _applyAppMotion(
    FlexThemeData.light(
      scheme: _scheme,
      subThemesData: _lightSubThemes,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    ),
  );

  static final ThemeData dark = _applyAppMotion(
    FlexThemeData.dark(
      scheme: _scheme,
      subThemesData: _darkSubThemes,
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
    ),
  );

  static const FlexSubThemesData _lightSubThemes = FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    useM2StyleDividerInM3: true,
    inputDecoratorIsFilled: true,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    alignedDropdown: true,
    navigationRailUseIndicator: true,
    appBarCenterTitle: true,
    appBarScrolledUnderElevation: 0,
    appBarBackgroundSchemeColor: SchemeColor.primary,
    appBarIconSchemeColor: SchemeColor.onPrimary,
    listTileIconSchemeColor: SchemeColor.primary,
    bottomNavigationBarElevation: 0,
    defaultRadius: 12,
    cardRadius: 14,
    dialogRadius: 18,
    bottomSheetRadius: 20,
    fabRadius: 14,
    elevatedButtonRadius: 12,
    filledButtonRadius: 12,
    outlinedButtonRadius: 12,
    textButtonRadius: 10,
  );

  static const FlexSubThemesData _darkSubThemes = FlexSubThemesData(
    interactionEffects: true,
    tintedDisabledControls: true,
    blendOnColors: true,
    useM2StyleDividerInM3: true,
    inputDecoratorIsFilled: true,
    inputDecoratorBorderType: FlexInputBorderType.outline,
    alignedDropdown: true,
    navigationRailUseIndicator: true,
    appBarCenterTitle: true,
    appBarScrolledUnderElevation: 0,
    appBarBackgroundSchemeColor: SchemeColor.primary,
    appBarIconSchemeColor: SchemeColor.onPrimary,
    listTileIconSchemeColor: SchemeColor.primary,
    bottomNavigationBarElevation: 0,
    defaultRadius: 12,
    cardRadius: 14,
    dialogRadius: 18,
    bottomSheetRadius: 20,
    fabRadius: 14,
    elevatedButtonRadius: 12,
    filledButtonRadius: 12,
    outlinedButtonRadius: 12,
    textButtonRadius: 10,
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

  static ThemeData _applyAppMotion(ThemeData theme) {
    return theme.copyWith(pageTransitionsTheme: _transitions);
  }
}

abstract final class AppFlexTheme {
  static ThemeData get light => AppTheme.light;
  static ThemeData get dark => AppTheme.dark;
}
