import 'package:flutter/material.dart';

/// Widget que adiciona padding inferior automaticamente para respeitar o FAB
class FabSafeScrollView extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  const FabSafeScrollView({
    super.key,
    required this.child,
    this.padding,
    this.physics,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Calcula o padding inferior baseado na altura do FAB
    const fabHeight = 56.0; // Altura padrão do FAB
    const fabMargin = 16.0; // Margem do FAB
    const bottomPadding = fabHeight + fabMargin + 16.0; // 16px extra de segurança

    // Combina o padding fornecido com o padding inferior para o FAB
    final effectivePadding = padding != null
        ? EdgeInsets.fromLTRB(
            padding!.resolve(TextDirection.ltr).left,
            padding!.resolve(TextDirection.ltr).top,
            padding!.resolve(TextDirection.ltr).right,
            padding!.resolve(TextDirection.ltr).bottom + bottomPadding,
          )
        : const EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding);

    return SingleChildScrollView(
      padding: effectivePadding,
      physics: physics,
      controller: controller,
      child: child,
    );
  }
}
