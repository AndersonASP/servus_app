import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servus_app/core/theme/color_scheme.dart';

final ThemeData darkTheme = ThemeData(
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme).copyWith(
    bodyLarge: TextStyle(color: ServusColors.darkTextHigh),
    bodyMedium: TextStyle(color: ServusColors.darkTextMedium),
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: ServusColors.darkBackground,
  canvasColor: ServusColors.funcoesBackgroundDark,
  primaryColor: ServusColors.primaryDark,
  colorScheme: ColorScheme.dark(
    primary: ServusColors.primary,
    secondary: ServusColors.secondary,
    surface: ServusColors.darkSurface,
    error: ServusColors.error,
    onPrimary: ServusColors.darkTextHigh,
    onSurface: ServusColors.onDarkSurface,
    onError: ServusColors.onDarkSurface,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ServusColors.darkSurface,
    labelStyle: TextStyle(color: ServusColors.darkTextHigh),
    hintStyle: TextStyle(color: ServusColors.darkTextHigh),
    errorStyle: TextStyle(color: ServusColors.error),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: ServusColors.darkTextHigh),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: ServusColors.primary, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: ServusColors.error),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: ServusColors.error, width: 2),
      borderRadius: BorderRadius.circular(8),
    ),
  ),
);
