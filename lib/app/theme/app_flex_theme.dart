import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppFlexTheme {
  static const FlexScheme _scheme = FlexScheme.pinkM3;

  static ThemeData get light => FlexColorScheme.light(
        scheme: _scheme,
        useMaterial3: true,
        subThemesData: _sub,
      ).toTheme.copyWith(
        textTheme: GoogleFonts.notoSansTextTheme(),
        primaryTextTheme: GoogleFonts.notoSansTextTheme(),
        pageTransitionsTheme: _transitions,
      );

  static ThemeData get dark => FlexColorScheme.dark(
        scheme: _scheme,
        useMaterial3: true,
        subThemesData: _sub,
      ).toTheme.copyWith(
        textTheme: GoogleFonts.notoSansTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
        primaryTextTheme: GoogleFonts.notoSansTextTheme(
          ThemeData(brightness: Brightness.dark).primaryTextTheme,
        ),
        pageTransitionsTheme: _transitions,
      );

  static const FlexSubThemesData _sub = FlexSubThemesData(
    interactionEffects: true,
    defaultRadius: 12.0,
    cardRadius: 16.0,
    dialogRadius: 16.0,
    bottomSheetRadius: 16.0,
    fabRadius: 14.0,
    elevatedButtonRadius: 12.0,
    filledButtonRadius: 12.0,
    outlinedButtonRadius: 12.0,
    textButtonRadius: 10.0,
    appBarCenterTitle: true,
    appBarScrolledUnderElevation: 0.0,
    bottomNavigationBarElevation: 0.0,
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
}
