import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doodle_pad/app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme', () {
    test('light and dark themes use the shared Material 3 base', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(theme.useMaterial3, isTrue);
        expect(theme.visualDensity, FlexColorScheme.comfortablePlatformDensity);
        // 종이+잉크 방향: AppBar 제목은 왼쪽 정렬(안드로이드 기본), 표면색 배경.
        expect(theme.appBarTheme.centerTitle, isFalse);
        expect(theme.inputDecorationTheme.filled, isTrue);
        expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      }
    });

    test('chrome is paper-colored with ink foreground (no painted app bar)', () {
      final light = AppTheme.light;
      final dark = AppTheme.dark;

      expect(light.appBarTheme.backgroundColor, light.colorScheme.surface);
      expect(light.appBarTheme.iconTheme?.color, light.colorScheme.onSurface);
      expect(light.scaffoldBackgroundColor, light.colorScheme.surface);

      expect(dark.appBarTheme.backgroundColor, dark.colorScheme.surface);
      expect(dark.appBarTheme.iconTheme?.color, dark.colorScheme.onSurface);
      expect(dark.scaffoldBackgroundColor, dark.colorScheme.surface);
    });

    test('palette keeps the hand-tuned paper/ink colors', () {
      expect(AppTheme.light.colorScheme.primary, AppTheme.lightScheme.primary);
      expect(AppTheme.light.colorScheme.surface, AppTheme.lightScheme.surface);
      expect(
        AppTheme.light.colorScheme.surfaceContainerLowest,
        AppTheme.lightScheme.surfaceContainerLowest,
      );
      expect(AppTheme.dark.colorScheme.primary, AppTheme.darkScheme.primary);
      expect(AppTheme.dark.colorScheme.surface, AppTheme.darkScheme.surface);
    });

    test('primaryContainer foreground keeps readable contrast', () {
      for (final cs in [AppTheme.lightScheme, AppTheme.darkScheme]) {
        final bg = cs.primaryContainer.computeLuminance();
        final fg = cs.onPrimaryContainer.computeLuminance();
        final ratio = (bg > fg ? (bg + 0.05) / (fg + 0.05) : (fg + 0.05) / (bg + 0.05));
        expect(ratio, greaterThanOrEqualTo(4.5));
      }
    });
  });
}
