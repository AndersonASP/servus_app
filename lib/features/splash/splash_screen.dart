import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'splash_controller.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late SplashController _splash;

  @override
  void initState() {
    super.initState();

    _splash = SplashController(this);
    _splash.start();

    Future.delayed(const Duration(seconds: 4), () {
      context.go('/welcome'); // ou '/welcome'
    });
  }

  @override
  void dispose() {
    _splash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary; // Cor do Servus

    return Scaffold(
      body: AnimatedBuilder(
        animation: _splash.controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // 🔵 Círculo crescendo
              Center(
                child: Transform.scale(
                  scale: _splash.circleScale.value,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // 🔻 Logo deslizando + texto
              Positioned(
                top: (MediaQuery.of(context).size.height / 2) -
                    (60 / 2) +
                    _splash.logoTop.value,
                child: Opacity(
                  opacity: _splash.logoOpacity.value,
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: 60,
                        semanticsLabel: 'Servus Logo',
                      ),
                      const SizedBox(height: 5),
                      Opacity(
                        opacity: _splash.textOpacity.value,
                        child: Text(
                          'SERVUS',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color:  Color.fromARGB(255, 242, 237, 237),
                                    letterSpacing: -2.0,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
