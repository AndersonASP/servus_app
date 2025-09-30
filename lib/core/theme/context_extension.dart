import 'package:flutter/material.dart';
import 'premium_input_theme.dart';

extension ThemeExtensions on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  ThemeData get theme => Theme.of(this);
  
  // Premium input decoration
  InputDecoration premiumInputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return PremiumInputTheme.getDefaultDecoration(
      labelText: labelText,
      context: this,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }
  
  // Premium chip decoration
  BoxDecoration premiumChipDecoration({
    required bool isSelected,
    double borderRadius = 20,
  }) {
    return PremiumInputTheme.getPremiumChipDecoration(
      isSelected: isSelected,
      context: this,
      borderRadius: borderRadius,
    );
  }
  
  // Premium card decoration
  BoxDecoration premiumCardDecoration({
    double borderRadius = 20,
  }) {
    return PremiumInputTheme.getPremiumCardDecoration(
      context: this,
      borderRadius: borderRadius,
    );
  }
}