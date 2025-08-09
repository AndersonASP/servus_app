import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servus_app/core/theme/color_scheme.dart';

final ThemeData lightTheme = ThemeData(
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
    bodyLarge: TextStyle(color: ServusColors.textHigh),
    bodyMedium: TextStyle(color: ServusColors.textMedium),
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: ServusColors.background,
  canvasColor: ServusColors.funcoesBackground,
  primaryColor: ServusColors.primary,
  colorScheme: ColorScheme.light(
    primary: ServusColors.primary,
    secondary: ServusColors.secondary,
    surface: ServusColors.surface,
    error: ServusColors.error,
    onPrimary: ServusColors.darkTextHigh,
    onSurface: ServusColors.primaryDark,
    onError: ServusColors.primary,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ServusColors.surface, // fundo dos inputs
    labelStyle: TextStyle(color: ServusColors.textMedium), // label
    hintStyle: TextStyle(color: ServusColors.textMedium.withOpacity(0.5)),
    errorStyle: TextStyle(color: ServusColors.error),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: ServusColors.border),
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
