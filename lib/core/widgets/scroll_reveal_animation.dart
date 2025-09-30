import 'package:flutter/material.dart';

/// Widget que aplica animações baseadas na visibilidade durante o scroll
class ScrollRevealAnimation extends StatefulWidget {
  /// Widget filho que será animado
  final Widget child;
  
  /// Duração da animação
  final Duration duration;
  
  /// Delay antes da animação começar
  final Duration delay;
  
  /// Offset inicial da animação (direção do movimento)
  final Offset initialOffset;
  
  /// Opacidade inicial
  final double initialOpacity;
  
  /// Curva de animação
  final Curve curve;
  
  /// Se deve animar apenas uma vez ou sempre que entrar/sair da tela
  final bool animateOnce;
  
  /// Porcentagem da tela que o widget precisa estar visível para triggerar a animação
  final double threshold;

  const ScrollRevealAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.initialOffset = const Offset(0, 50),
    this.initialOpacity = 0.0,
    this.curve = Curves.easeOutCubic,
    this.animateOnce = true,
    this.threshold = 0.1,
  });

  @override
  State<ScrollRevealAnimation> createState() => _ScrollRevealAnimationState();
}

class _ScrollRevealAnimationState extends State<ScrollRevealAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  
  bool _hasAnimated = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _offsetAnimation = Tween<Offset>(
      begin: widget.initialOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: widget.initialOpacity,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Delay inicial se especificado
    if (widget.delay != Duration.zero) {
      Future.delayed(widget.delay, () {
        if (mounted && _isVisible) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(bool isVisible) {
    if (!mounted) return;
    
    setState(() {
      _isVisible = isVisible;
    });

    if (isVisible && (!_hasAnimated || !widget.animateOnce)) {
      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else if (!_hasAnimated) {
        Future.delayed(widget.delay, () {
          if (mounted && _isVisible) {
            _controller.forward();
          }
        });
      }
      _hasAnimated = true;
    } else if (!isVisible && !widget.animateOnce) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? ValueKey(hashCode),
      onVisibilityChanged: (info) {
        final isVisible = info.visibleFraction >= widget.threshold;
        _onVisibilityChanged(isVisible);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: _offsetAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Widget detector de visibilidade personalizado
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final Key key;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    required this.key,
    required this.child,
    required this.onVisibilityChanged,
  }) : super(key: key);

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  final GlobalKey _key = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  @override
  void didUpdateWidget(VisibilityDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    if (!mounted) return;
    
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;
    
    // Calcular a visibilidade baseada na posição na tela
    final visibleHeight = _calculateVisibleHeight(offset, size, screenSize);
    final visibleFraction = visibleHeight / size.height;
    
    widget.onVisibilityChanged(VisibilityInfo(
      key: widget.key,
      size: size,
      visibleFraction: visibleFraction.clamp(0.0, 1.0),
    ));
  }

  double _calculateVisibleHeight(Offset offset, Size size, Size screenSize) {
    final top = offset.dy;
    final bottom = offset.dy + size.height;
    
    // Se está completamente acima da tela
    if (bottom <= 0) return 0.0;
    
    // Se está completamente abaixo da tela
    if (top >= screenSize.height) return 0.0;
    
    // Calcular parte visível
    final visibleTop = top < 0 ? 0.0 : top;
    final visibleBottom = bottom > screenSize.height ? screenSize.height : bottom;
    
    return (visibleBottom - visibleTop).clamp(0.0, size.height);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkVisibility();
        });
        return false;
      },
      child: Container(
        key: _key,
        child: widget.child,
      ),
    );
  }
}

/// Informações sobre a visibilidade do widget
class VisibilityInfo {
  final Key? key;
  final Size size;
  final double visibleFraction;

  const VisibilityInfo({
    this.key,
    required this.size,
    required this.visibleFraction,
  });
}

/// Preset para animação de slide da esquerda
class SlideFromLeft extends ScrollRevealAnimation {
  const SlideFromLeft({
    super.key,
    required super.child,
    super.duration = const Duration(milliseconds: 600),
    super.delay = Duration.zero,
    super.curve = Curves.easeOutCubic,
  }) : super(
    initialOffset: const Offset(-100, 0),
    initialOpacity: 0.0,
  );
}

/// Preset para animação de slide da direita
class SlideFromRight extends ScrollRevealAnimation {
  const SlideFromRight({
    super.key,
    required super.child,
    super.duration = const Duration(milliseconds: 600),
    super.delay = Duration.zero,
    super.curve = Curves.easeOutCubic,
  }) : super(
    initialOffset: const Offset(100, 0),
    initialOpacity: 0.0,
  );
}

/// Preset para animação de slide de baixo para cima
class SlideFromBottom extends ScrollRevealAnimation {
  const SlideFromBottom({
    super.key,
    required super.child,
    super.duration = const Duration(milliseconds: 600),
    super.delay = Duration.zero,
    super.curve = Curves.easeOutCubic,
  }) : super(
    initialOffset: const Offset(0, 50),
    initialOpacity: 0.0,
  );
}

/// Preset para animação de fade in
class FadeInUp extends ScrollRevealAnimation {
  const FadeInUp({
    super.key,
    required super.child,
    super.duration = const Duration(milliseconds: 800),
    super.delay = Duration.zero,
    super.curve = Curves.easeOutCubic,
  }) : super(
    initialOffset: const Offset(0, 30),
    initialOpacity: 0.0,
  );
}

/// Preset para animação de scale
class ScaleReveal extends ScrollRevealAnimation {
  const ScaleReveal({
    super.key,
    required super.child,
    super.duration = const Duration(milliseconds: 500),
    super.delay = Duration.zero,
    super.curve = Curves.elasticOut,
  }) : super(
    initialOffset: Offset.zero,
    initialOpacity: 0.0,
  );

  @override
  State<ScaleReveal> createState() => _ScaleRevealState();
}

class _ScaleRevealState extends State<ScaleReveal>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  bool _hasAnimated = false;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(bool isVisible) {
    if (!mounted) return;
    
    setState(() {
      _isVisible = isVisible;
    });

    if (isVisible && (!_hasAnimated || !widget.animateOnce)) {
      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else if (!_hasAnimated) {
        Future.delayed(widget.delay, () {
          if (mounted && _isVisible) {
            _controller.forward();
          }
        });
      }
      _hasAnimated = true;
    } else if (!isVisible && !widget.animateOnce) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? ValueKey(hashCode),
      onVisibilityChanged: (info) {
        final isVisible = info.visibleFraction >= widget.threshold;
        _onVisibilityChanged(isVisible);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
