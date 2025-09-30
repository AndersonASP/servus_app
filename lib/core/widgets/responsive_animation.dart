import 'package:flutter/material.dart';

/// Configurações de animação baseadas no tamanho da tela
class ResponsiveAnimationConfig {
  /// Duração da animação para mobile
  final Duration mobileDuration;
  
  /// Duração da animação para tablet
  final Duration tabletDuration;
  
  /// Duração da animação para desktop
  final Duration desktopDuration;
  
  /// Delay para mobile
  final Duration mobileDelay;
  
  /// Delay para tablet
  final Duration tabletDelay;
  
  /// Delay para desktop
  final Duration desktopDelay;
  
  /// Se deve reduzir animações em dispositivos lentos
  final bool respectReduceMotion;
  
  /// Multiplicador para dispositivos de baixa performance
  final double lowPerformanceMultiplier;

  const ResponsiveAnimationConfig({
    this.mobileDuration = const Duration(milliseconds: 300),
    this.tabletDuration = const Duration(milliseconds: 400),
    this.desktopDuration = const Duration(milliseconds: 500),
    this.mobileDelay = Duration.zero,
    this.tabletDelay = Duration.zero,
    this.desktopDelay = Duration.zero,
    this.respectReduceMotion = true,
    this.lowPerformanceMultiplier = 0.5,
  });
}

/// Widget que adapta animações baseado no tamanho da tela
class ResponsiveAnimatedWidget extends StatefulWidget {
  /// Widget filho
  final Widget child;
  
  /// Configurações de animação
  final ResponsiveAnimationConfig config;
  
  /// Builder da animação
  final Widget Function(BuildContext context, Animation<double> animation, Widget child) builder;
  
  /// Tween da animação
  final Tween<double>? tween;
  
  /// Curva da animação
  final Curve curve;
  
  /// Se deve iniciar automaticamente
  final bool autoStart;

  const ResponsiveAnimatedWidget({
    super.key,
    required this.child,
    required this.builder,
    this.config = const ResponsiveAnimationConfig(),
    this.tween,
    this.curve = Curves.easeOutCubic,
    this.autoStart = true,
  });

  @override
  State<ResponsiveAnimatedWidget> createState() => _ResponsiveAnimatedWidgetState();
}

class _ResponsiveAnimatedWidgetState extends State<ResponsiveAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAnimation();
      });
    }
  }

  void _initializeAnimation() {
    final duration = _getResponsiveDuration();
    
    _controller = AnimationController(
      duration: duration,
      vsync: this,
    );

    final tween = widget.tween ?? Tween<double>(begin: 0.0, end: 1.0);
    
    _animation = tween.animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  Duration _getResponsiveDuration() {
    final screenSize = MediaQuery.of(context).size;
    final isReduceMotionEnabled = MediaQuery.of(context).disableAnimations;
    
    Duration baseDuration;
    
    if (screenSize.width < 600) {
      // Mobile
      baseDuration = widget.config.mobileDuration;
    } else if (screenSize.width < 1200) {
      // Tablet
      baseDuration = widget.config.tabletDuration;
    } else {
      // Desktop
      baseDuration = widget.config.desktopDuration;
    }

    // Respeitar configurações de acessibilidade
    if (widget.config.respectReduceMotion && isReduceMotionEnabled) {
      return Duration(
        milliseconds: (baseDuration.inMilliseconds * widget.config.lowPerformanceMultiplier).round(),
      );
    }

    return baseDuration;
  }

  Duration _getResponsiveDelay() {
    final screenSize = MediaQuery.of(context).size;
    
    if (screenSize.width < 600) {
      return widget.config.mobileDelay;
    } else if (screenSize.width < 1200) {
      return widget.config.tabletDelay;
    } else {
      return widget.config.desktopDelay;
    }
  }

  void _startAnimation() async {
    final delay = _getResponsiveDelay();
    
    if (delay != Duration.zero) {
      await Future.delayed(delay);
    }
    
    if (mounted) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ResponsiveAnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Reinicializar se as configurações mudaram
    if (widget.config != oldWidget.config) {
      _controller.dispose();
      _initializeAnimation();
      
      if (widget.autoStart) {
        _startAnimation();
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return widget.builder(context, _animation, widget.child);
      },
    );
  }
}

/// Utility class para detectar capacidades do dispositivo
class DeviceCapabilities {
  /// Detecta se o dispositivo é considerado de baixa performance
  static bool isLowPerformanceDevice(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    // Considerar baixa performance se:
    // 1. Animações estão desabilitadas pelo sistema
    // 2. Tela muito pequena (dispositivos antigos)
    // 3. Pixel ratio muito baixo
    return mediaQuery.disableAnimations ||
        mediaQuery.size.width < 360 ||
        mediaQuery.devicePixelRatio < 1.5;
  }
  
  /// Detecta se é um dispositivo móvel
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }
  
  /// Detecta se é um tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }
  
  /// Detecta se é desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }
  
  /// Retorna o tipo de dispositivo
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 600) {
      return DeviceType.mobile;
    } else if (width < 1200) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }
}

/// Enum para tipos de dispositivo
enum DeviceType {
  mobile,
  tablet,
  desktop,
}

/// Widget que aplica animações adaptáveis para entrada
class ResponsiveSlideIn extends StatelessWidget {
  /// Widget filho
  final Widget child;
  
  /// Direção do slide
  final SlideDirection direction;
  
  /// Delay antes da animação
  final Duration? delay;
  
  /// Se deve usar configurações responsivas
  final bool useResponsiveConfig;

  const ResponsiveSlideIn({
    super.key,
    required this.child,
    this.direction = SlideDirection.bottom,
    this.delay,
    this.useResponsiveConfig = true,
  });

  @override
  Widget build(BuildContext context) {
    final config = useResponsiveConfig 
        ? ResponsiveAnimationConfig(
            mobileDuration: const Duration(milliseconds: 400),
            tabletDuration: const Duration(milliseconds: 500),
            desktopDuration: const Duration(milliseconds: 600),
            mobileDelay: delay ?? Duration.zero,
            tabletDelay: delay ?? Duration.zero,
            desktopDelay: delay ?? Duration.zero,
          )
        : ResponsiveAnimationConfig(
            mobileDuration: const Duration(milliseconds: 400),
            tabletDuration: const Duration(milliseconds: 400),
            desktopDuration: const Duration(milliseconds: 400),
            mobileDelay: delay ?? Duration.zero,
            tabletDelay: delay ?? Duration.zero,
            desktopDelay: delay ?? Duration.zero,
          );

    return ResponsiveAnimatedWidget(
      config: config,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        Offset begin;
        switch (direction) {
          case SlideDirection.left:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.right:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.top:
            begin = const Offset(0.0, -1.0);
            break;
          case SlideDirection.bottom:
            begin = const Offset(0.0, 1.0);
            break;
        }

        final slideAnimation = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(animation);

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(animation);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Direções possíveis para slide
enum SlideDirection {
  left,
  right,
  top,
  bottom,
}

/// Widget que aplica scale responsivo
class ResponsiveScaleIn extends StatelessWidget {
  /// Widget filho
  final Widget child;
  
  /// Delay antes da animação
  final Duration? delay;
  
  /// Scale inicial
  final double initialScale;

  const ResponsiveScaleIn({
    super.key,
    required this.child,
    this.delay,
    this.initialScale = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    final config = ResponsiveAnimationConfig(
      mobileDuration: const Duration(milliseconds: 300),
      tabletDuration: const Duration(milliseconds: 400),
      desktopDuration: const Duration(milliseconds: 500),
      mobileDelay: delay ?? Duration.zero,
      tabletDelay: delay ?? Duration.zero,
      desktopDelay: delay ?? Duration.zero,
    );

    return ResponsiveAnimatedWidget(
      config: config,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animation, child) {
        final scaleAnimation = Tween<double>(
          begin: initialScale,
          end: 1.0,
        ).animate(animation);

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(animation);

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Widget que aplica fade responsivo
class ResponsiveFadeIn extends StatelessWidget {
  /// Widget filho
  final Widget child;
  
  /// Delay antes da animação
  final Duration? delay;

  const ResponsiveFadeIn({
    super.key,
    required this.child,
    this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final config = ResponsiveAnimationConfig(
      mobileDuration: const Duration(milliseconds: 500),
      tabletDuration: const Duration(milliseconds: 600),
      desktopDuration: const Duration(milliseconds: 800),
      mobileDelay: delay ?? Duration.zero,
      tabletDelay: delay ?? Duration.zero,
      desktopDelay: delay ?? Duration.zero,
    );

    return ResponsiveAnimatedWidget(
      config: config,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, animation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Mixin para adicionar capacidades de animação responsiva a widgets
mixin ResponsiveAnimationMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController responsiveController;
  
  /// Inicializa o controller com duração responsiva
  void initResponsiveController({
    ResponsiveAnimationConfig? config,
  }) {
    final animConfig = config ?? const ResponsiveAnimationConfig();
    final duration = _getResponsiveDuration(animConfig);
    
    responsiveController = AnimationController(
      duration: duration,
      vsync: this,
    );
  }
  
  Duration _getResponsiveDuration(ResponsiveAnimationConfig config) {
    final screenSize = MediaQuery.of(context).size;
    final isReduceMotionEnabled = MediaQuery.of(context).disableAnimations;
    
    Duration baseDuration;
    
    if (screenSize.width < 600) {
      baseDuration = config.mobileDuration;
    } else if (screenSize.width < 1200) {
      baseDuration = config.tabletDuration;
    } else {
      baseDuration = config.desktopDuration;
    }

    if (config.respectReduceMotion && isReduceMotionEnabled) {
      return Duration(
        milliseconds: (baseDuration.inMilliseconds * config.lowPerformanceMultiplier).round(),
      );
    }

    return baseDuration;
  }
  
  @override
  void dispose() {
    responsiveController.dispose();
    super.dispose();
  }
}
