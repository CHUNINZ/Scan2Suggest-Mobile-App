import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'signin.dart';
import 'app_theme.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _buttonController;
  late AnimationController _sparkleController;
  late AnimationController _fadeController;
  late AnimationController _contentController;
  
  late Animation<double> _buttonBreathingAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _subtitleAnimation;
  late Animation<double> _buttonSlideAnimation;
  
  int _currentImageIndex = 0;
  Timer? _imageTimer;
  
  // Original background food images
  final List<String> _foodImages = [
    'assets/images/image1.jpg',
    'assets/images/image2.jpg',
    'assets/images/image3.jpg',
    'assets/images/image4.jpg',
    'assets/images/image5.jpg',
  ];

  // Food circles positioned across the entire screen area
  final List<Map<String, dynamic>> _foodCircles = [
    // Top left corner
    {
      'image': 'assets/images/image6.png',
      'size': 115.0,
      'left': 80.0,
      'top': 120.0,
      'animationOffset': 0.0,
    },
    // Top center
    {
      'image': 'assets/images/image7.png',
      'size': 105.0,
      'left': 210.0,
      'top': 80.0,
      'animationOffset': 1.0,
    },
    // Top right corner
    {
      'image': 'assets/images/image8.png',
      'size': 120.0,
      'left': 340.0,
      'top': 120.0,
      'animationOffset': 2.0,
    },
    // Middle left
    {
      'image': 'assets/images/image9.png',
      'size': 100.0,
      'left': 20.0,
      'top': 250.0,
      'animationOffset': 3.0,
    },
    // Center (main focal point)
    {
      'image': 'assets/images/image10.png',
      'size': 160.0,
      'left': 190.0,
      'top': 210.0,
      'animationOffset': 4.0,
    },
    // Middle right
    {
      'image': 'assets/images/image11.png',
      'size': 110.0,
      'left': 380.0,
      'top': 260.0,
      'animationOffset': 5.0,
    },
    // Bottom left
    {
      'image': 'assets/images/image12.png',
      'size': 115.0,
      'left': 100.0,
      'top': 360.0,
      'animationOffset': 6.0,
    },
    // Bottom right
    {
      'image': 'assets/images/image13.png',
      'size': 120.0,
      'left': 300.0,
      'top': 370.0,
      'animationOffset': 7.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Background slideshow controller
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Button breathing animation controller
    _buttonController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Sparkle animation controller
    _sparkleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Fade controller for image transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Content animation controller
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Initialize animations with proper clamping
    _buttonBreathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));
    
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Content animations with staggered timing
    _titleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    ));
    
    _subtitleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _buttonSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOutCubic),
    ));
    
    // Start animations
    _startButtonBreathing();
    _startSparkleAnimation();
    _startBackgroundSlideshow();
    _fadeController.forward();
    _contentController.forward();
  }
  
  void _startButtonBreathing() {
    _buttonController.repeat(reverse: true);
  }
  
  void _startSparkleAnimation() {
    _sparkleController.repeat();
  }
  
  void _startBackgroundSlideshow() {
    _imageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _foodImages.length;
        });
      }
    });
  }
  
  void _onGetStartedPressed() async {
    // Provide haptic feedback
    HapticFeedback.mediumImpact();
    
    // Scale down animation
    await _buttonController.forward();
    
    // Navigate after a brief delay
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const SignIn(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _buttonController.dispose();
    _sparkleController.dispose();
    _fadeController.dispose();
    _contentController.dispose();
    _imageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Animated background with original food images
            _buildAnimatedBackground(),
            
            // Static food circles overlay
            _buildStaticFoodCircles(),
            
            // Subtle sparkle effects overlay
            _buildSparkleOverlay(),
            
            // Status bar with better layout
          
            
            // Main content positioned at bottom
            _buildBottomContentLayout(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1500),
        child: Container(
          key: ValueKey(_currentImageIndex),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(_foodImages[_currentImageIndex]),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.4),
                BlendMode.darken,
              ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildStaticFoodCircles() {
    return Stack(
      children: _foodCircles.map((circle) {
        return Positioned(
          left: circle['left'],
          top: circle['top'],
          child: _buildFoodCircle(
            circle['image'],
            circle['size'],
            circle['animationOffset'],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildFoodCircle(String imagePath, double size, double offset) {
    return AnimatedBuilder(
      animation: _contentController,
      builder: (context, child) {
        // Staggered entrance animation with proper clamping
        final entranceDelay = (offset * 0.1).clamp(0.0, 0.8);
        final entranceEnd = (entranceDelay + 0.4).clamp(0.2, 1.0);
        
        final entranceAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _contentController,
          curve: Interval(
            entranceDelay,
            entranceEnd,
            curve: Curves.elasticOut,
          ),
        ));
        
        // Clamp the animation value to ensure it stays within valid range
        final clampedValue = entranceAnimation.value.clamp(0.0, 1.0);
        
        return Transform.scale(
          scale: clampedValue,
          child: Opacity(
            opacity: clampedValue,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to colored circle if image not found
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.secondaryLightGreen,
                            AppTheme.primaryDarkGreen,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: size * 0.4,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSparkleOverlay() {
    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, child) {
        return Positioned.fill(
          child: CustomPaint(
            painter: SparklePainter(_sparkleAnimation.value),
          ),
        );
      },
    );
  }
  
  
  
  Widget _buildBottomContentLayout() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with animation
              AnimatedBuilder(
                animation: _titleAnimation,
                builder: (context, child) {
                  final clampedValue = _titleAnimation.value.clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - clampedValue)),
                    child: Opacity(
                      opacity: clampedValue,
                      child: const Text(
                        'Scan2Suggest',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 12,
                              color: Colors.black54,
                            ),
                            Shadow(
                              offset: Offset(0, 4),
                              blurRadius: 24,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle with animation
              AnimatedBuilder(
                animation: _subtitleAnimation,
                builder: (context, child) {
                  final clampedValue = _subtitleAnimation.value.clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - clampedValue)),
                    child: Opacity(
                      opacity: clampedValue,
                      child: const Text(
                        'Your Next Delicious Hapag-Kainan is One Scan Away.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 8,
                              color: Colors.black45,
                            ),
                            Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 16,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 40),
              
              // Get Started Button with animation
              AnimatedBuilder(
                animation: _buttonSlideAnimation,
                builder: (context, child) {
                  final clampedSlideValue = _buttonSlideAnimation.value.clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - clampedSlideValue)),
                    child: Opacity(
                      opacity: clampedSlideValue,
                      child: AnimatedBuilder(
                        animation: _buttonBreathingAnimation,
                        builder: (context, child) {
                          final clampedBreathingValue = _buttonBreathingAnimation.value.clamp(0.8, 1.2);
                          return Transform.scale(
                            scale: clampedBreathingValue,
                            child: GestureDetector(
                              onTapDown: (_) {
                                _buttonController.stop();
                                _buttonController.forward();
                              },
                              onTapUp: (_) => _onGetStartedPressed(),
                              onTapCancel: () {
                                _buttonController.reverse().then((_) {
                                  _startButtonBreathing();
                                });
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1FCC79),
                                      Color(0xFF16A85F),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1FCC79).withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Get Started',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              
              // Bottom indicator
              AnimatedBuilder(
                animation: _buttonSlideAnimation,
                builder: (context, child) {
                  final clampedValue = _buttonSlideAnimation.value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: clampedValue,
                    child: Container(
                      width: 134,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SparklePainter extends CustomPainter {
  final double animationValue;
  
  SparklePainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final random = [0.2, 0.7, 0.4, 0.9, 0.1, 0.6, 0.3, 0.8, 0.5, 0.25];
    
    for (int i = 0; i < 6; i++) {
      final opacity = (animationValue + random[i]) % 1.0;
      final sparkleOpacity = (1.0 - (opacity - 0.5).abs() * 2).clamp(0.0, 1.0);
      
      if (sparkleOpacity > 0) {
        paint.color = Colors.white.withOpacity(sparkleOpacity * 0.4);
        
        final x = size.width * (0.15 + (i * 0.15)) + 
                 (animationValue * 15 - 7.5);
        final y = size.height * (0.1 + (i * 0.1)) + 
                 (animationValue * 10 - 5);
        
        // Draw sparkle with glow effect
        canvas.drawLine(Offset(x - 6, y), Offset(x + 6, y), paint);
        canvas.drawLine(Offset(x, y - 6), Offset(x, y + 6), paint);
        canvas.drawLine(Offset(x - 4, y - 4), Offset(x + 4, y + 4), paint);
        canvas.drawLine(Offset(x - 4, y + 4), Offset(x + 4, y - 4), paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}