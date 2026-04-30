import 'package:flutter/material.dart';

/// Premium utilitarian minimalism palette. Color is deliberately scarce:
/// warm monochrome surfaces carry the interface, while washed pastel tones
/// appear only for semantic hints and compact status accents.
///
/// Tokens are split into a static neutral base plus per-mode resolvers
/// ([light]/[dark]) so themed surfaces and chrome can share one source of
/// truth across iOS, Android, light and dark.
class AppColors {
  const AppColors._();

  // ── Brand / Ink ─────────────────────────────────────────────────────────
  static const Color brandInk = Color(0xFF2F3437);

  // Backward-compatible names. Kept to avoid churn in older call sites.
  static const Color finOrange = brandInk;
  static const Color finOrangeDeep = Color(0xFF111111);

  // ── Light surface family ─────────────────────────────────────────────────
  /// Warm bone canvas.
  static const Color canvas = Color(0xFFFBFBFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF7F6F3);
  static const Color surfaceRaised = Color(0xFFF9F9F8);

  /// Structural hairline border.
  static const Color oat = Color(0xFFEAEAEA);
  static const Color oatSoft = Color(0xFFF0F0EF);

  // ── Dark surface family ──────────────────────────────────────────────────
  /// Dark canvas reads near-black while staying warm enough for long sessions.
  static const Color canvasDark = Color(0xFF070707);
  static const Color surfaceDark = Color(0xFF10100F);
  static const Color surfaceMutedDark = Color(0xFF171715);
  static const Color surfaceRaisedDark = Color(0xFF141413);

  static const Color oatDark = Color(0xFF2A2926);
  static const Color oatSoftDark = Color(0xFF20201D);

  // ── Ink (text) ───────────────────────────────────────────────────────────
  static const Color ink = brandInk;
  static const Color inkMuted = Color(0xFF787774);
  static const Color inkSubtle = Color(0xFF9B9996);

  // Dark-mode ink (warm bone, not pure white)
  static const Color inkOnDark = Color(0xFFF3F0E8);
  static const Color inkMutedOnDark = Color(0xFFB0ACA2);
  static const Color inkSubtleOnDark = Color(0xFF817D74);

  // ── Report palette (data-viz, sparingly used) ────────────────────────────
  static const Color reportBlue = Color(0xFF8DB6D1);
  static const Color reportGreen = Color(0xFF8AAE8D);
  static const Color reportRed = Color(0xFFC88784);
  static const Color reportPink = Color(0xFFB69AC7);
  static const Color reportLime = Color(0xFFC7B77A);

  // ── Washed pastel accents ────────────────────────────────────────────────
  static const Color washBlue = Color(0xFFE1F3FE);
  static const Color washBlueInk = Color(0xFF1F6C9F);
  static const Color washGreen = Color(0xFFEDF3EC);
  static const Color washGreenInk = Color(0xFF346538);
  static const Color washRed = Color(0xFFFDEBEC);
  static const Color washRedInk = Color(0xFF9F2F2D);
  static const Color washYellow = Color(0xFFFBF3DB);
  static const Color washYellowInk = Color(0xFF956400);
  static const Color washLav = Color(0xFFF3EFF8);
  static const Color washLavInk = Color(0xFF5B4A6B);

  // Backward-compatible names used by existing widgets.
  static const Color hairline = oatSoft;
  static const Color hairlineSoft = Color(0x0F000000);
  static const Color paleRedBg = washRed;
  static const Color paleRedInk = washRedInk;
  static const Color paleBlueBg = washBlue;
  static const Color paleBlueInk = washBlueInk;
  static const Color paleGreenBg = washGreen;
  static const Color paleGreenInk = washGreenInk;
  static const Color paleYellowBg = washYellow;
  static const Color paleYellowInk = washYellowInk;
  static const Color paleLavBg = washLav;
  static const Color paleLavInk = washLavInk;

  // Dark-mode washes (low-saturation, surface-blended)
  static const Color washBlueDark = Color(0xFF1B2A3A);
  static const Color washGreenDark = Color(0xFF1F2A1B);
  static const Color washRedDark = Color(0xFF3A1F1B);
  static const Color washYellowDark = Color(0xFF332A14);
  static const Color washLavDark = Color(0xFF2A2235);

  // ── Mode-aware resolvers ─────────────────────────────────────────────────
  static Color canvasOf(Brightness b) =>
      b == Brightness.light ? canvas : canvasDark;
  static Color surfaceOf(Brightness b) =>
      b == Brightness.light ? surface : surfaceDark;
  static Color surfaceMutedOf(Brightness b) =>
      b == Brightness.light ? surfaceMuted : surfaceMutedDark;
  static Color surfaceRaisedOf(Brightness b) =>
      b == Brightness.light ? surfaceRaised : surfaceRaisedDark;

  static Color oatOf(Brightness b) => b == Brightness.light ? oat : oatDark;
  static Color oatSoftOf(Brightness b) =>
      b == Brightness.light ? oatSoft : oatSoftDark;

  static Color inkOf(Brightness b) => b == Brightness.light ? ink : inkOnDark;
  static Color inkMutedOf(Brightness b) =>
      b == Brightness.light ? inkMuted : inkMutedOnDark;
  static Color inkSubtleOf(Brightness b) =>
      b == Brightness.light ? inkSubtle : inkSubtleOnDark;
}

/// Convenient theme-extension access to mode-resolved tokens. Pages that
/// previously read static [AppColors.canvas] should switch to
/// `context.tokens.canvas` so dark mode just works.
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceRaised,
    required this.oat,
    required this.oatSoft,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.accent,
    required this.washBlue,
    required this.washBlueInk,
    required this.washGreen,
    required this.washGreenInk,
    required this.washRed,
    required this.washRedInk,
    required this.washYellow,
    required this.washYellowInk,
    required this.washLav,
    required this.washLavInk,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceRaised;
  final Color oat;
  final Color oatSoft;
  final Color ink;
  final Color inkMuted;
  final Color inkSubtle;
  final Color accent;
  final Color washBlue;
  final Color washBlueInk;
  final Color washGreen;
  final Color washGreenInk;
  final Color washRed;
  final Color washRedInk;
  final Color washYellow;
  final Color washYellowInk;
  final Color washLav;
  final Color washLavInk;

  factory AppTokens.of(Brightness b) {
    final isLight = b == Brightness.light;
    return AppTokens(
      canvas: AppColors.canvasOf(b),
      surface: AppColors.surfaceOf(b),
      surfaceMuted: AppColors.surfaceMutedOf(b),
      surfaceRaised: AppColors.surfaceRaisedOf(b),
      oat: AppColors.oatOf(b),
      oatSoft: AppColors.oatSoftOf(b),
      ink: AppColors.inkOf(b),
      inkMuted: AppColors.inkMutedOf(b),
      inkSubtle: AppColors.inkSubtleOf(b),
      accent: AppColors.brandInk,
      washBlue: isLight ? AppColors.washBlue : AppColors.washBlueDark,
      washBlueInk: isLight ? AppColors.washBlueInk : AppColors.reportBlue,
      washGreen: isLight ? AppColors.washGreen : AppColors.washGreenDark,
      washGreenInk: isLight ? AppColors.washGreenInk : AppColors.reportGreen,
      washRed: isLight ? AppColors.washRed : AppColors.washRedDark,
      washRedInk: isLight ? AppColors.washRedInk : AppColors.reportRed,
      washYellow: isLight ? AppColors.washYellow : AppColors.washYellowDark,
      washYellowInk: isLight ? AppColors.washYellowInk : AppColors.reportLime,
      washLav: isLight ? AppColors.washLav : AppColors.washLavDark,
      washLavInk: isLight ? AppColors.washLavInk : AppColors.reportPink,
    );
  }

  @override
  AppTokens copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceRaised,
    Color? oat,
    Color? oatSoft,
    Color? ink,
    Color? inkMuted,
    Color? inkSubtle,
    Color? accent,
    Color? washBlue,
    Color? washBlueInk,
    Color? washGreen,
    Color? washGreenInk,
    Color? washRed,
    Color? washRedInk,
    Color? washYellow,
    Color? washYellowInk,
    Color? washLav,
    Color? washLavInk,
  }) {
    return AppTokens(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      oat: oat ?? this.oat,
      oatSoft: oatSoft ?? this.oatSoft,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkSubtle: inkSubtle ?? this.inkSubtle,
      accent: accent ?? this.accent,
      washBlue: washBlue ?? this.washBlue,
      washBlueInk: washBlueInk ?? this.washBlueInk,
      washGreen: washGreen ?? this.washGreen,
      washGreenInk: washGreenInk ?? this.washGreenInk,
      washRed: washRed ?? this.washRed,
      washRedInk: washRedInk ?? this.washRedInk,
      washYellow: washYellow ?? this.washYellow,
      washYellowInk: washYellowInk ?? this.washYellowInk,
      washLav: washLav ?? this.washLav,
      washLavInk: washLavInk ?? this.washLavInk,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      oat: l(oat, other.oat),
      oatSoft: l(oatSoft, other.oatSoft),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      inkSubtle: l(inkSubtle, other.inkSubtle),
      accent: l(accent, other.accent),
      washBlue: l(washBlue, other.washBlue),
      washBlueInk: l(washBlueInk, other.washBlueInk),
      washGreen: l(washGreen, other.washGreen),
      washGreenInk: l(washGreenInk, other.washGreenInk),
      washRed: l(washRed, other.washRed),
      washRedInk: l(washRedInk, other.washRedInk),
      washYellow: l(washYellow, other.washYellow),
      washYellowInk: l(washYellowInk, other.washYellowInk),
      washLav: l(washLav, other.washLav),
      washLavInk: l(washLavInk, other.washLavInk),
    );
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ??
      AppTokens.of(Theme.of(this).brightness);
}
