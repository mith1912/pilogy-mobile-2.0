import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const labelMedium = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.26,
    color: AppColors.onSurface,
  );
  static const labelSmall = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.66,
    color: AppColors.onSurface,
  );
  static const bodyMedium = TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.00,
    color: AppColors.onSurface,
  );
  static const bodyLarge = TextStyle(
    fontSize: 16,
    height: 26 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.16,
    color: AppColors.onSurface,
  );
  static const bodySmall = TextStyle(
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.12,
    color: AppColors.onSurface,
  );
  static const headlineLarge = TextStyle(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.32,
    color: AppColors.onSurface,
  );
  static const headlineLargeMobile = TextStyle(
    fontSize: 26,
    height: 34 / 26,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.26,
    color: AppColors.onSurface,
  );
  static const headlineMedium = TextStyle(
    fontSize: 22,
    height: 30 / 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.00,
    color: AppColors.onSurface,
  );
  static const headlineSmall = TextStyle(
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.18,
    color: AppColors.onSurface,
  );
  static const displayNumeral = TextStyle(
    fontSize: 64,
    height: 72 / 64,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.28,
    color: AppColors.onSurface,
  );
  static const displayNumeralMobile = TextStyle(
    fontSize: 48,
    height: 56 / 48,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.48,
    color: AppColors.onSurface,
  );

  static TextStyle _body(TextStyle style, bool fonts) =>
      fonts
          ? GoogleFonts.inter(textStyle: style)
          : style.copyWith(fontFamily: 'sans-serif');

  static TextStyle _heading(TextStyle style, bool fonts) =>
      fonts
          ? GoogleFonts.playfairDisplay(textStyle: style)
          : style.copyWith(fontFamily: 'serif');

  static TextTheme textTheme({bool useGoogleFonts = true}) => TextTheme(
    displayLarge: _heading(displayNumeral, useGoogleFonts),
    displayMedium: _heading(displayNumeralMobile, useGoogleFonts),
    headlineLarge: _heading(headlineLarge, useGoogleFonts),
    headlineMedium: _heading(headlineLargeMobile, useGoogleFonts),
    headlineSmall: _heading(headlineMedium, useGoogleFonts),
    titleLarge: _heading(headlineSmall, useGoogleFonts),
    bodyLarge: _body(bodyLarge, useGoogleFonts),
    bodyMedium: _body(bodyMedium, useGoogleFonts),
    bodySmall: _body(bodySmall, useGoogleFonts),
    labelLarge: _body(labelMedium, useGoogleFonts),
    labelMedium: _body(labelMedium, useGoogleFonts),
    labelSmall: _body(labelSmall, useGoogleFonts),
  );
}
