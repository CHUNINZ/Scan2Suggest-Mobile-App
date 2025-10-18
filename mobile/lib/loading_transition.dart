import 'package:flutter/material.dart';
import 'main_navigation_controller.dart';
import 'dart:async';

class LoadingTransition extends StatefulWidget {
  const LoadingTransition({super.key});

  @override
  State<LoadingTransition> createState() => _LoadingTransitionState();
}

class _LoadingTransitionState extends State<LoadingTransition>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _morphController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _zoomController;
  
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _morphAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _zoomAnimation;
  late Animation<double> _fadeAnimation;
  
  int _currentMorphIndex = 0;
  Timer? _morphTimer;
  
  final List<IconData> _cookingIcons = [
    Icons.restaurant_menu,
    Icons.local_dining,
    Icons.cake,
    Icons.coffee,
  ];

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Morph animation controller
    _morphController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Progress animation controller
    _progressController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Zoom out controller
    _zoomController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Initialize animations
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));
    
    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _zoomAnimation = Tween<double>(
      begin: 1.0,
      end: 3.0,
    ).animate(CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeInCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeInCubic,
    ));
    
    _startLoadingSequence();
  }
  
  void _startLoadingSequence() async {
    // Start logo appearance
    await _logoController.forward();
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    // Start morphing icons
    _startIconMorphing();
    
    // Start progress animation
    _progressController.forward();
    
    // Wait for loading to complete
    await Future.delayed(const Duration(milliseconds: 3000));
    
    // Stop pulse and start zoom out
    _pulseController.stop();
    await _zoomController.forward();
    
    // Navigate to home
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return const MainNavigationController();
          },
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }
  
  void _startIconMorphing() {
    _morphTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (mounted) {
        _morphController.reset();
        setState(() {
          _currentMorphIndex = (_currentMorphIndex + 1) % _cookingIcons.length;
        });
        _morphController.forward();
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _morphController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    _zoomController.dispose();
    _morphTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1FCC79),
              Color(0xFF16A85F),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _zoomController,
            _fadeAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _zoomAnimation.value,
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Morphing cooking icons
                    _buildMorphingIcon(),
                    
                    const SizedBox(height: 40),
                    
                    // Scan2Suggest text
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Transform.rotate(
                            angle: _logoRotationAnimation.value * 0.1,
                            child: const Text(
                              'Scan2Suggest',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Progress bar
                    _buildProgressBar(),
                    
                    const SizedBox(height: 20),
                    
                    // Loading text
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoScaleAnimation.value,
                          child: const Text(
                            'Setting up your kitchen...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildMorphingIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoController,
        _morphController,
        _pulseController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value * _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Previous icon (fading out)
                if (_currentMorphIndex > 0)
                  Opacity(
                    opacity: 1.0 - _morphAnimation.value,
                    child: Transform.scale(
                      scale: 1.0 - (_morphAnimation.value * 0.3),
                      child: Icon(
                        _cookingIcons[(_currentMorphIndex - 1) % _cookingIcons.length],
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                
                // Current icon (fading in)
                Opacity(
                  opacity: _morphAnimation.value,
                  child: Transform.scale(
                    scale: 0.7 + (_morphAnimation.value * 0.3),
                    child: Icon(
                      _cookingIcons[_currentMorphIndex],
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProgressBar() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              // Progress fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 200 * _progressAnimation.value,
                height: 6,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Colors.white70],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
              
              // Shimmer effect
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}