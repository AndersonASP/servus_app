import 'package:flutter/material.dart';

class ServusLoadingWidget extends StatefulWidget {
  const ServusLoadingWidget({super.key});

  @override
  State<ServusLoadingWidget> createState() => _ServusLoadingWidgetState();
}

class _ServusLoadingWidgetState extends State<ServusLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.black.withOpacity(0.5),
          width: double.infinity,
          height: double.infinity,
        ),
        Center(
          child: RotationTransition(
            turns: _controller,
            child: Image.asset(
              'assets/images/logo_loading.png',
              width: 60,
              height: 60,
            ),
          ),
        ),
      ],
    );
  }
}