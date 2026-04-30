import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Premium utilitarian minimalism theme. Warm bone canvas, off-black ink,
/// #EAEAEA hairline borders, sharp 4px button geometry, and high-contrast
/// editorial headings with calm document-style surfaces.
///
/// One source of truth for both light and dark; iOS gets a matching
/// [CupertinoThemeData] so navigation chrome feels native on both platforms.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(brightness: Brightness.light);
  static ThemeData dark() => _build(brightness: Brightness.dark);

  static CupertinoThemeData cupertino({required Brightness brightness}) {
    final tokens = AppTokens.of(brightness);
    return CupertinoThemeData(
      brightness: brightness,
      primaryColor: tokens.ink,
      scaffoldBackgroundColor: tokens.canvas,
      barBackgroundColor: tokens.canvas,
      applyThemeToAll: true,
      textTheme: CupertinoTextThemeData(
        primaryColor: tokens.ink,
        textStyle: TextStyle(
          fontFamily: '.SF Pro Text',
          color: tokens.ink,
          fontSize: 16,
          height: 1.50,
          letterSpacing: 0,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: '.SF Pro Text',
          color: tokens.ink,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: '.SF Pro Display',
          color: tokens.ink,
          fontSize: 34,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.06,
        ),
        actionTextStyle: TextStyle(
          fontFamily: '.SF Pro Text',
          color: tokens.ink,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        tabLabelTextStyle: TextStyle(
          fontFamily: '.SF Pro Text',
          color: tokens.inkSubtle,
          fontSize: 10,
          letterSpacing: 0,
        ),
      ),
    );
  }

  static ThemeData _build({required Brightness brightness}) {
    final isLight = brightness == Brightness.light;
    final tokens = AppTokens.of(brightness);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.ink,
      onPrimary: tokens.canvas,
      secondary: tokens.washBlueInk,
      onSecondary: tokens.canvas,
      tertiary: tokens.washLavInk,
      onTertiary: tokens.canvas,
      error: tokens.washRedInk,
      onError: tokens.canvas,
      surface: tokens.surface,
      onSurface: tokens.ink,
      onSurfaceVariant: tokens.inkMuted,
      outline: tokens.oat,
      outlineVariant: tokens.oatSoft,
      surfaceContainerLowest: tokens.canvas,
      surfaceContainerLow: tokens.canvas,
      surfaceContainer: tokens.surface,
      surfaceContainerHigh: tokens.surfaceRaised,
      surfaceContainerHighest: tokens.surfaceMuted,
      inverseSurface: tokens.ink,
      onInverseSurface: tokens.canvas,
      inversePrimary: tokens.canvas,
      shadow: Colors.black.withValues(alpha: 0.04),
      scrim: Colors.black.withValues(alpha: 0.4),
    );

    // Use the platform's native sans; weight, spacing, and tight line-height
    // carry the editorial signature without bundled font weight.
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme.apply(bodyColor: tokens.ink, displayColor: tokens.ink);

    final textTheme = base.copyWith(
      // Display ── editorial headings, weight 400/500, tight 1.00 line.
      displayLarge: base.displayLarge?.copyWith(
        color: tokens.ink,
        fontSize: 64,
        fontWeight: FontWeight.w500,
        height: 1.00,
        letterSpacing: 0,
      ),
      displayMedium: base.displayMedium?.copyWith(
        color: tokens.ink,
        fontSize: 54,
        fontWeight: FontWeight.w500,
        height: 1.00,
        letterSpacing: 0,
      ),
      displaySmall: base.displaySmall?.copyWith(
        color: tokens.ink,
        fontSize: 40,
        fontWeight: FontWeight.w500,
        height: 1.00,
        letterSpacing: 0,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        color: tokens.ink,
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.04,
        letterSpacing: 0,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: tokens.ink,
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1.06,
        letterSpacing: 0,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: tokens.ink,
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.08,
        letterSpacing: 0,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: tokens.ink,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: 0,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: tokens.ink,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0,
      ),
      titleSmall: base.titleSmall?.copyWith(
        color: tokens.ink,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: tokens.ink,
        fontSize: 16,
        height: 1.50,
        letterSpacing: 0,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: tokens.ink,
        fontSize: 15,
        height: 1.50,
        letterSpacing: 0,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: tokens.inkMuted,
        fontSize: 13,
        height: 1.45,
        letterSpacing: 0,
      ),
      labelLarge: base.labelLarge?.copyWith(
        color: tokens.ink,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: tokens.inkMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: tokens.inkSubtle,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0, // mono-style uppercase eyebrow
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: tokens.canvas,
      canvasColor: tokens.canvas,
      textTheme: textTheme,
      extensions: [tokens],
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: isLight
          ? Colors.black.withValues(alpha: 0.02)
          : Colors.white.withValues(alpha: 0.03),
      dividerTheme: DividerThemeData(color: tokens.oat, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        foregroundColor: tokens.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: 0,
        ),
        toolbarHeight: 56,
        iconTheme: IconThemeData(color: tokens.ink, size: 22),
        actionsIconTheme: IconThemeData(color: tokens.ink, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: tokens.oat),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return tokens.oat;
            if (states.contains(WidgetState.pressed)) return tokens.inkMuted;
            return tokens.ink;
          }),
          foregroundColor: WidgetStatePropertyAll(tokens.canvas),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0,
            ),
          ),
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
          foregroundColor: WidgetStatePropertyAll(tokens.ink),
          backgroundColor: WidgetStatePropertyAll(tokens.surface),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.oat)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0,
            ),
          ),
          overlayColor: WidgetStatePropertyAll(
            tokens.ink.withValues(alpha: 0.04),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(tokens.ink),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          overlayColor: WidgetStatePropertyAll(
            tokens.ink.withValues(alpha: 0.04),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(tokens.ink),
          overlayColor: WidgetStatePropertyAll(
            tokens.ink.withValues(alpha: 0.04),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
        ),
      ),
      iconTheme: IconThemeData(color: tokens.ink, size: 20),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        labelStyle: textTheme.labelMedium?.copyWith(color: tokens.inkMuted),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(
          color: tokens.ink,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: tokens.inkSubtle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: tokens.oat),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: tokens.oat),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: tokens.ink, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: tokens.washRedInk),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: textTheme.bodyMedium,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(tokens.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: tokens.oat),
            ),
          ),
          elevation: const WidgetStatePropertyAll(0),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: tokens.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: tokens.oat),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 2,
        activeTrackColor: tokens.ink,
        inactiveTrackColor: tokens.oat,
        thumbColor: tokens.ink,
        overlayColor: Colors.transparent,
        overlayShape: SliderComponentShape.noOverlay,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return tokens.ink;
            return tokens.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return tokens.canvas;
            return tokens.ink;
          }),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.oat)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: tokens.ink,
        textColor: tokens.ink,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.canvas;
          return tokens.inkSubtle;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.ink;
          return tokens.oat;
        }),
        trackOutlineColor: WidgetStatePropertyAll(tokens.oat),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: tokens.canvas),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        showDragHandle: true,
        dragHandleColor: tokens.oat,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokens.oat),
        ),
      ),
    );
  }
}
