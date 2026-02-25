import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _subThemesData = FlexSubThemesData(
    blendOnLevel: 10,
    blendOnColors: false,
    sliderTrackHeight: 8,
    fabSchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    segmentedButtonSelectedForegroundSchemeColor: SchemeColor.onPrimary,
  );

  static const _subThemesDataDark = FlexSubThemesData(
    blendOnLevel: 20,
    sliderTrackHeight: 8,
    fabSchemeColor: SchemeColor.primary,
    segmentedButtonSchemeColor: SchemeColor.primary,
    segmentedButtonSelectedForegroundSchemeColor: SchemeColor.onPrimary,
  );

  static ThemeData light = FlexThemeData.light(
    scheme: FlexScheme.blueWhale,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 9,
    subThemesData: _subThemesData,
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
  );

  static ThemeData dark = FlexThemeData.dark(
    scheme: FlexScheme.blueWhale,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 15,
    subThemesData: _subThemesDataDark,
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
  );
}
