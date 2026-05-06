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
        expect(theme.appBarTheme.centerTitle, isTrue);
        expect(theme.inputDecorationTheme.filled, isTrue);
        expect(theme.inputDecorationTheme.border, isA<OutlineInputBorder>());
      }
    });

    test('chrome colors follow the active color scheme', () {
      final light = AppTheme.light;
      final dark = AppTheme.dark;

      expect(light.appBarTheme.backgroundColor, light.colorScheme.primary);
      expect(light.appBarTheme.iconTheme?.color, light.colorScheme.onPrimary);
      expect(light.listTileTheme.iconColor, light.colorScheme.primary);

      expect(dark.appBarTheme.backgroundColor, dark.colorScheme.primary);
      expect(dark.appBarTheme.iconTheme?.color, dark.colorScheme.onPrimary);
      expect(dark.listTileTheme.iconColor, dark.colorScheme.primary);
    });
  });
}
