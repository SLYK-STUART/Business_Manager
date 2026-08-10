import 'package:flutter/material.dart';

/// Business Manager color palette — black + gold "workspace platform" theme.
/// Derived from the login screen and sell-item sheet visual language.
class AppColors {
  AppColors._();

  // ---- Brand ----
  static const Color primary = Color(0xFFFFC700); // core gold/yellow
  static const Color primaryDark = Color(0xFFE6B400);
  static const Color primaryLight = Color(0xFFFFD84D);

  // ---- Surfaces ----
  static const Color background = Color(0xFFF7F7F5); // light app bg
  static const Color surface = Color(0xFFFFFFFF); // cards/sheets
  static const Color surfaceRaised = Color(0xFFFFFFFF); // inputs, elevated elements
  static const Color surfaceLight = Color(0xFFFFFFFF); // white cards/sheets (sell sheet, inputs)
  static const Color surfaceMuted = Color(0xFFF5F5F5); // subtle off-white fields
  static const Color surfaceDark = Color(0xFF1A1A1A); // dark accent bands (headers, nav bar)

  // ---- Text ----
  static const Color textPrimary = Color(0xFF0A0A0A); // headings (light bg is now default)
  static const Color textPrimaryOnLight = Color(0xFF0A0A0A); // headings on white
  static const Color textSecondary = Color(0xFF6B6B6B); // subtitles
  static const Color textSecondaryOnLight = Color(0xFF6B6B6B); // subtitles on white
  static const Color textOnPrimary = Color(0xFF0A0A0A); // text on gold buttons
  static const Color textOnDark = Color(0xFFFFFFFF); // text on dark accent bands
  static const Color textHint = Color(0xFF8A8A8A); // placeholder text

  // ---- Borders / dividers ----
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderOnLight = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEDEDED);

  // ---- Status ----
  static const Color success = Color(0xFF3ED598);
  static const Color warning = Color(0xFFFFA726); // e.g. low-stock badge
  static const Color error = Color(0xFFFF5C5C);
  static const Color info = Color(0xFF4DA6FF);

  // ---- Component-specific ----
  static const Color stockBadge = primary; // "12 left" pill background
  static const Color stockBadgeText = Color(0xFF0A0A0A);
  static const Color toggleActive = primary; // discount switch
  static const Color toggleInactive = Color(0xFFD8D8D8);
  static const Color linkAccent = primaryDark; // "Forgot password?", "Request Access"

  // ---- Gradients ----
  static const LinearGradient goldSlab = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  // ---- Overlays ----
  static const Color scrim = Color(0xB3000000); // modal backdrop over content
  static const Color glassFill = Color(0x1AFFFFFF); // frosted glass panels
}