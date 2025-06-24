import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_scheme.dart';

TextTheme getTextTheme() => TextTheme(
  displayLarge: GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: ServusColors.textHigh,
  ),
  headlineMedium: GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: ServusColors.textHigh,
  ),
  titleLarge: GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ServusColors.textHigh,
  ),
  bodyLarge: GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ServusColors.textMedium,
  ),
  bodyMedium: GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: ServusColors.textMedium,
  ),
  labelLarge: GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: ServusColors.primary,
  ),
);