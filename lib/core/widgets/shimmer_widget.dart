import 'package:flutter/material.dart';

/// Widget que cria efeito shimmer para estados de carregamento
class ShimmerWidget extends StatefulWidget {
  /// Widget filho que será "shimmerizado"
  final Widget child;
  
  /// Se o shimmer está ativo
  final bool isLoading;
  
  /// Cor base do shimmer
  final Color? baseColor;
  
  /// Cor de destaque do shimmer
  final Color? highlightColor;
  
  /// Duração da animação
  final Duration duration;
  
  /// Direção do gradiente
  final ShimmerDirection direction;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    this.direction = ShimmerDirection.leftToRight,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ShimmerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final baseColor = widget.baseColor ??
        (isDark ? Colors.grey[800]! : Colors.grey[300]!);
    final highlightColor = widget.highlightColor ??
        (isDark ? Colors.grey[700]! : Colors.grey[100]!);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return _createShader(bounds, baseColor, highlightColor);
          },
          child: widget.child,
        );
      },
    );
  }

  Shader _createShader(Rect bounds, Color baseColor, Color highlightColor) {
    final double position = _animation.value;
    
    Alignment begin, end;
    switch (widget.direction) {
      case ShimmerDirection.leftToRight:
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
        break;
      case ShimmerDirection.rightToLeft:
        begin = Alignment.centerRight;
        end = Alignment.centerLeft;
        break;
      case ShimmerDirection.topToBottom:
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
        break;
      case ShimmerDirection.bottomToTop:
        begin = Alignment.bottomCenter;
        end = Alignment.topCenter;
        break;
    }

    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        baseColor,
        highlightColor,
        baseColor,
      ],
      stops: [
        (position - 1).clamp(0.0, 1.0),
        position.clamp(0.0, 1.0),
        (position + 1).clamp(0.0, 1.0),
      ],
    ).createShader(bounds);
  }
}

/// Direções possíveis para o efeito shimmer
enum ShimmerDirection {
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop,
}

/// Widget shimmer pré-construído para cards
class ShimmerCard extends StatelessWidget {
  /// Altura do card
  final double height;
  
  /// Largura do card
  final double? width;
  
  /// Margem externa
  final EdgeInsets margin;
  
  /// Padding interno
  final EdgeInsets padding;
  
  /// Border radius
  final BorderRadius borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 120,
    this.width,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      child: ShimmerWidget(
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header com avatar e título
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: 8,
                          width: 80,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Linhas de conteúdo
              Container(
                height: 8,
                width: double.infinity,
                color: Colors.grey,
              ),
              const SizedBox(height: 2),
              Container(
                height: 8,
                width: 120,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget shimmer para listas
class ShimmerList extends StatelessWidget {
  /// Número de itens a serem exibidos
  final int itemCount;
  
  /// Altura de cada item
  final double itemHeight;
  
  /// Se deve mostrar separador entre itens
  final bool showSeparator;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.showSeparator = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (context, index) => showSeparator 
          ? const Divider() 
          : const SizedBox.shrink(),
      itemBuilder: (context, index) {
        return ShimmerItem(height: itemHeight);
      },
    );
  }
}

/// Item individual para shimmer
class ShimmerItem extends StatelessWidget {
  /// Altura do item
  final double height;
  
  /// Margem externa
  final EdgeInsets margin;

  const ShimmerItem({
    super.key,
    this.height = 80,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      child: ShimmerWidget(
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 8,
                    width: 100,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            // Ação
            Container(
              width: 18,
              height: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer para botões
class ShimmerButton extends StatelessWidget {
  /// Largura do botão
  final double width;
  
  /// Altura do botão
  final double height;
  
  /// Border radius
  final BorderRadius borderRadius;

  const ShimmerButton({
    super.key,
    this.width = 120,
    this.height = 40,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

/// Shimmer para texto
class ShimmerText extends StatelessWidget {
  /// Largura do texto
  final double width;
  
  /// Altura do texto
  final double height;

  const ShimmerText({
    super.key,
    this.width = 100,
    this.height = 14,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        color: Colors.grey,
      ),
    );
  }
}

/// Shimmer para imagens/avatares circulares
class ShimmerCircle extends StatelessWidget {
  /// Raio do círculo
  final double radius;

  const ShimmerCircle({
    super.key,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerWidget(
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Container pre-fabricado para dashboard com shimmer
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com greeting
            Row(
              children: [
                const ShimmerCircle(radius: 30),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ShimmerText(width: 120, height: 18),
                    const SizedBox(height: 4),
                    const ShimmerText(width: 80, height: 14),
                  ],
                ),
                const Spacer(),
                const ShimmerButton(width: 40, height: 40),
              ],
            ),
            const SizedBox(height: 24),
            
            // Título da seção
            const ShimmerText(width: 150, height: 20),
            const SizedBox(height: 16),
            
            // Card principal
            const ShimmerCard(height: 160),
            
            const SizedBox(height: 24),
            
            // Título de outra seção
            const ShimmerText(width: 120, height: 18),
            const SizedBox(height: 16),
            
            // Lista de itens
            Expanded(
              child: ListView.builder(
                itemCount: 3,
                itemBuilder: (context, index) {
                  return ShimmerCard(
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 12),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
