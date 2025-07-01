import 'package:flutter/widgets.dart';

class BotaoStatusData {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;

  const BotaoStatusData({
    required this.label,
    required this.icon,
    required this.color,
    this.enabled = true,
  });
}