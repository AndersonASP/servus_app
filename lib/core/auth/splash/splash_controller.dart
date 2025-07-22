import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashController extends ChangeNotifier {
  late final AnimationController animationController;
  final void Function(String route) onNavigate;

  late final Animation<double> circleScale;
  late final Animation<double> logoTop;
  late final Animation<double> logoOpacity;
  late final Animation<double> textOpacity;

  final TickerProvider vsync;

  SplashController({required this.vsync, required this.onNavigate}) {
    _initAnimations();
  }

  void _initAnimations() {
    animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 4),
    );

    circleScale = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    logoTop = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.6, 0.8, curve: Curves.easeIn),
      ),
    );

    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _decidirRota();
      }
    });
  }

  void start() => animationController.forward();

  void disposeAnimations() => animationController.dispose();

  Future<void> _decidirRota() async {
    final prefs = await SharedPreferences.getInstance();
    final viuWelcome = prefs.getBool('viu_welcome') ?? false;
    final token = prefs.getString('token');

    if (token != null) {
      onNavigate('/dashboard');
    } else if (viuWelcome) {
      onNavigate('/login');
    } else {
      onNavigate('/welcome');
    }
  }
}