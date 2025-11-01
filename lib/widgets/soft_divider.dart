import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';

class SoftDivider extends StatelessWidget {
  final double height;
  final double alpha;
  final EdgeInsetsGeometry? margin;

  const SoftDivider({super.key, this.height = 1, this.alpha = 0.06, this.margin});

  @override
  Widget build(BuildContext context) {
    final dividerWidget = Container(
      height: height,
      color: context.colors.outline.withValues(alpha: alpha),
    );
    if (margin != null) {
      return Container(margin: margin, child: dividerWidget);
    }
    return dividerWidget;
  }
}


