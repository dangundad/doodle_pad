// ================================================
// DangunDad Flutter App - app_theme.dart Template
// ================================================
// 앱별 FlexScheme 변경 (https://rydmike.com/flexcolorscheme/themesplayground)
// mbti_pro 프로덕션 패턴 기반

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

abstract final class AppTheme {
  // TODO: 앱별 FlexScheme 변경
  static const FlexScheme _scheme = FlexScheme.pinkM3;

  static ThemeData light = _buildLightTheme();
  static ThemeData dark = _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    final base = FlexThemeData.light(
      scheme: _scheme,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        useM2StyleDividerInM3: true,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        alignedDropdown: true,
        navigationRailUseIndicator: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    );

    return base.copyWith(dialogTheme: _buildDialogTheme(base));
  }

  static ThemeData _buildDarkTheme() {
    final base = FlexThemeData.dark(
      scheme: _scheme,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        blendOnColors: true,
        useM2StyleDividerInM3: true,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        alignedDropdown: true,
        navigationRailUseIndicator: true,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
    );

    return base.copyWith(dialogTheme: _buildDialogTheme(base));
  }

  static DialogThemeData _buildDialogTheme(ThemeData base) {
    final scheme = base.colorScheme;

    return DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.primary,
      elevation: 6,
      shadowColor: scheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      iconColor: scheme.secondary,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: base.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.4,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    );
  }
}
