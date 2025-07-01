import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:servus_app/core/theme/color_scheme.dart';

final ThemeData lightTheme = ThemeData(
  
  textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
    bodyLarge: TextStyle(color: ServusColors.surface),
    bodyMedium: TextStyle(color: ServusColors.surface),
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: ServusColors.background,
  primaryColor: ServusColors.primary,
  colorScheme: ColorScheme.light(
    primary: ServusColors.primary,
    secondary: ServusColors.secondary,
    surface: ServusColors.background,    
    error: ServusColors.error,
    onPrimary: Colors.white,
    onSurface: ServusColors.primaryDark,
    onError: Colors.white,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ServusColors.background,
    border: OutlineInputBorder(
      borderSide: BorderSide(color: ServusColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
  ),
);
