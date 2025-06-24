import 'package:flutter/material.dart';

class SplashController {
  late final AnimationController controller;

  late final Animation<double> circleScale;
  late final Animation<double> logoTop;
  late final Animation<double> logoOpacity;
  late final Animation<double> textOpacity;

  SplashController(TickerProvider vsync) {
    controller = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 4),
    );

    circleScale = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );

    logoTop = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );

    logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: controller,
          curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );

    textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: controller,
          curve: const Interval(0.6, 0.8, curve: Curves.easeIn)),
    );
  }

  void start() => controller.forward();

  void dispose() => controller.dispose();
}
