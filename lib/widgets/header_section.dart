import 'package:flutter/material.dart';
import 'package:servus_app/core/theme/context_extension.dart';

class HeaderSection extends StatelessWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget trailing;
  final EdgeInsetsGeometry padding;

  const HeaderSection({
    super.key,
    required this.leading,
    required this.title,
    required this.trailing,
    this.subtitle,
    this.padding = const EdgeInsets.fromLTRB(8, 12, 8, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DefaultTextStyle(
                  style: context.textStyles.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ) ??
                      TextStyle(color: context.colors.onSurface),
                  child: Align(alignment: Alignment.center, child: title),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  DefaultTextStyle(
                    style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurface.withValues(alpha: 0.7),
                        ) ??
                        TextStyle(color: context.colors.onSurface.withValues(alpha: 0.7)),
                    child: Align(alignment: Alignment.center, child: subtitle!),
                  ),
                ],
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}


