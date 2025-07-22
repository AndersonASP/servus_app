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
  SplashController? _splash;

  @override
  void initState() {
    super.initState();
    _splash = SplashController(
      vsync: this,
      onNavigate: (route) {
        if (!mounted) return;
        context.go(route);
      },
    );
    _splash?.start();
  }

  @override
  void dispose() {
    _splash?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    if (_splash == null || _splash!.animationController.isDismissed) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: _splash!.animationController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Transform.scale(
                  scale: _splash!.circleScale.value,
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
              Positioned(
                top: (MediaQuery.of(context).size.height / 2) -
                    (60 / 2) +
                    _splash!.logoTop.value,
                child: Opacity(
                  opacity: _splash!.logoOpacity.value,
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/images/logo.svg',
                        width: 75,
                        semanticsLabel: 'Servus Logo',
                      ),
                      const SizedBox(height: 5),
                      Opacity(
                        opacity: _splash!.textOpacity.value,
                        child: Text(
                          'SERVUS',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: const Color.fromARGB(255, 242, 237, 237),
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
