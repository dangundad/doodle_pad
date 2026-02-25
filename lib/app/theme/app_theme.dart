import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  static const Color _textPrimary = Color(0xFF1D2938);
  static const Color _textSecondary = Color(0xFF6A7788);
  static const Color _line = Color(0xFFD6DFEA);
  static const Color _lineDark = Color(0xFF3B4A61);

  static const Color _surface = Color(0xFFF4F7FB);
  static const Color _surfaceCard = Color(0xFFFFFFFF);
  static const Color _surfaceDark = Color(0xFF151D2A);
  static const Color _surfaceCardDark = Color(0xFF1F2939);

  static const Color _seed = Color(0xFF5A7497);
  static const Color _seedDark = Color(0xFF7D99BC);

  static final ThemeData light = _buildTheme(
    brightness: Brightness.light,
    scaffoldBackground: _surface,
    cardColor: _surfaceCard,
  );

  static final ThemeData dark = _buildTheme(
    brightness: Brightness.dark,
    scaffoldBackground: _surfaceDark,
    cardColor: _surfaceCardDark,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color cardColor,
  }) {
    final bool isDark = brightness == Brightness.dark;
    final Color seed = isDark ? _seedDark : _seed;
    final Color onText = isDark ? Colors.white : _textPrimary;
    final Color mutedText = isDark ? const Color(0xFFB0BECE) : _textSecondary;
    final Color mutedBg = isDark ? const Color(0xFF293447) : Colors.white;

    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final ThemeData base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: scaffoldBackground,
      cardColor: cardColor,
      dividerColor: isDark ? _lineDark : _line,
      fontFamily: GoogleFonts.notoSans().fontFamily,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );

    final TextTheme editorialText =
        GoogleFonts.notoSansTextTheme(base.textTheme).apply(
      bodyColor: onText,
      displayColor: onText,
    );

    final InputBorder fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? _lineDark : _line,
        width: 0.9,
      ),
    );

    return base.copyWith(
      textTheme: editorialText,
      primaryTextTheme: editorialText,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        foregroundColor: onText,
        titleTextStyle: editorialText.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: onText,
        ),
        iconTheme: IconThemeData(color: onText),
        actionsIconTheme: IconThemeData(color: onText),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? _lineDark : _line, width: 0.9),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: onText,
        textColor: onText,
        selectedColor: seed,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mutedBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: seed, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: seed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: editorialText.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: editorialText.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onText,
          side: BorderSide(color: isDark ? _lineDark : _line),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: editorialText.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: onText,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: editorialText.titleSmall,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardColor,
        contentTextStyle: editorialText.bodyMedium?.copyWith(color: onText),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: seed,
        unselectedItemColor: mutedText,
        selectedLabelStyle: editorialText.labelMedium?.copyWith(
          color: seed,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: editorialText.labelMedium?.copyWith(color: mutedText),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: onText,
        unselectedLabelColor: mutedText,
        indicatorColor: seed,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: editorialText.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: editorialText.titleSmall,
      ),
      dividerTheme: DividerThemeData(
        thickness: 0.8,
        color: isDark ? _lineDark : _line,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        titleTextStyle: editorialText.titleLarge?.copyWith(
          color: onText,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        labelTextStyle: WidgetStatePropertyAll(editorialText.bodyMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: editorialText.bodyMedium,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(cardColor),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(cardColor),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: mutedBg,
        labelStyle: editorialText.labelMedium?.copyWith(
          color: onText,
          fontWeight: FontWeight.w500,
        ),
        selectedColor: Color.alphaBlend(seed.withAlpha(40), cardColor),
        secondarySelectedColor: seed,
        shape: const StadiumBorder(),
        side: BorderSide(color: isDark ? _lineDark : _line),
        checkmarkColor: seed,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: seed,
        linearTrackColor: (isDark ? _lineDark : _line),
        linearMinHeight: 6,
        circularTrackColor: (isDark ? _lineDark : _line),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: seed,
        inactiveTrackColor: isDark ? const Color(0xFF2E3A4F) : _line,
        thumbColor: seed,
        trackHeight: 6,
        valueIndicatorTextStyle:
            editorialText.labelSmall?.copyWith(color: Colors.white),
      ),
      iconTheme: IconThemeData(color: onText),
    );
  }
}

