import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:servus_app/core/auth/services/auth_service.dart';
import 'package:servus_app/core/constants/env.dart';
import 'package:servus_app/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:servus_app/core/enums/user_role.dart';

class SplashController {
  final AnimationController animationController;
  final void Function(String route) onNavigate;

  late final Animation<double> circleScale;
  late final Animation<double> logoTop;
  late final Animation<double> logoOpacity;
  late final Animation<double> textOpacity;

  SplashController({
    required TickerProvider vsync,
    required this.onNavigate,
  }) : animationController = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 3000),
        );

  void _debugSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    if (keys.isEmpty) {
      print('🔍 SharedPreferences está vazio');
      return;
    }

    print('🔍 Conteúdo do SharedPreferences:');
    for (final key in keys) {
      final value = prefs.get(key);
      print('  → $key = $value');
    }
  }

  void start(BuildContext context) {
    _debugSharedPrefs();
    final curved = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    circleScale = Tween<double>(begin: 0.0, end: 8.0).animate(curved);

    logoTop = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -150, end: 0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -20)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -20, end: -10)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
    ]).animate(curved);

    logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeIn),
      ),
    );

    textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
      ),
    );

    animationController.forward();
    Future.delayed(const Duration(milliseconds: 3200), () => _decidirRota(context));
  }

  Future<void> _decidirRota(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final storage = FlutterSecureStorage();

    final jaViuWelcome = prefs.getBool('viu_welcome') ?? false;
    final accessToken = await storage.read(key: 'access_token');
    final refreshToken = await storage.read(key: 'refresh_token');
    final nome = prefs.getString('nome');
    final email = prefs.getString('email');
    final role = prefs.getString('role');

    if (!jaViuWelcome) {
      onNavigate('/welcome');
      return;
    }

    if (accessToken == null || refreshToken == null || nome == null || email == null) {
      onNavigate('/login');
      return;
    }

    final sucesso = await AuthService().renovarToken(refreshToken, context);
    if (!sucesso) {
      await _limparDadosLogin();
      onNavigate('/login');
      return;
    }

    if (role != null) {
      final papel = UserRole.values.firstWhere(
        (e) => e.name == role,
        orElse: () => UserRole.volunteer,
      );

      switch (papel) {
        case UserRole.superadmin:
        case UserRole.admin:
        case UserRole.leader:
          onNavigate('/leader/dashboard');
          break;
        case UserRole.volunteer:
          onNavigate('/volunteer/dashboard');
          break;
      }
    } else {
      onNavigate('/choose-role');
    }
  }

  Future<void> _limparDadosLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('nome');
    await prefs.remove('email');
    await prefs.remove('papelSelecionado');
  }

  void dispose() {
    animationController.dispose();
  }
}
