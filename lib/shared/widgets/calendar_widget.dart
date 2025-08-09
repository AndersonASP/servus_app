import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/color_scheme.dart';
import 'package:table_calendar/table_calendar.dart';

CalendarStyle buildCalendarStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return CalendarStyle(
    defaultTextStyle: TextStyle(
      color: isDark ? ServusColors.onDarkSurface : ServusColors.textHigh,
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w600
    ),
    weekendTextStyle: TextStyle(
      color: isDark ? ServusColors.onDarkSurface : ServusColors.textHigh,
      fontFamily: 'Poppins',
      fontSize: 16,
      fontWeight: FontWeight.w600
    ),
    outsideTextStyle: TextStyle(
      color: isDark ? Colors.grey[700] : Colors.grey[400],
      fontFamily: 'Poppins',
      fontSize: 14,
    ),
    todayDecoration: BoxDecoration(
      color: ServusColors.primary,
      shape: BoxShape.circle,
    ),
    todayTextStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    ),
    selectedDecoration: const BoxDecoration(
      color: ServusColors.error,
      shape: BoxShape.circle,
    ),
    selectedTextStyle: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      fontSize: 18,
    ),
    markerDecoration: BoxDecoration(
      color: ServusColors.secondary,
      shape: BoxShape.circle,
    ),
  );
}