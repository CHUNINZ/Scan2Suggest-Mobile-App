import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';
import 'app_theme.dart';
import 'verify_email.dart';
import 'signin.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _formController;
  late AnimationController _shakeController;
  late AnimationController _buttonController;
  
  late Animation<double> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _buttonScaleAnimation;
  
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  
  bool _isLoading = false;
  bool _hasMinLength = false;
  bool _hasNumber = false;
  
  List<AnimationController> _checkAnimations = [];

  @override
  void initState() {
    super.initState();
    
    _formController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    for (int i = 0; i < 2; i++) {
      _checkAnimations.add(
        AnimationController(
          duration: const Duration(milliseconds: 600),
          vsync: this,
        ),
      );
    }
    
    _formSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutCubic,
    ));
    
    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOut,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _buttonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));
    
    _passwordController.addListener(_validatePassword);
    
    _formController.forward();
  }
  
  void _validatePassword() {
    final password = _passwordController.text;
    
    bool newHasMinLength = password.length >= 6;
    if (newHasMinLength != _hasMinLength) {
      setState(() {
        _hasMinLength = newHasMinLength;
      });
      if (_hasMinLength) {
        _checkAnimations[0].forward();
      } else {
        _checkAnimations[0].reverse();
      }
    }
    
    bool newHasNumber = password.contains(RegExp(r'[0-9]'));
    if (newHasNumber != _hasNumber) {
      setState(() {
        _hasNumber = newHasNumber;
      });
      if (_hasNumber) {
        _checkAnimations[1].forward();
      } else {
        _checkAnimations[1].reverse();
      }
    }
  }
  
  void _shakeUnmetRequirements() {
    if (!_hasMinLength || !_hasNumber) {
      _shakeController.reset();
      _shakeController.forward();
    }
  }

  @override
  void dispose() {
    _formController.dispose();
    _shakeController.dispose();
    _buttonController.dispose();
    for (var controller in _checkAnimations) {
      controller.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Please enter your email address');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    if (password.isEmpty) {
      _showSnackBar('Please enter your password');
      return;
    }
    
    if (!_hasMinLength || !_hasNumber) {
      _shakeUnmetRequirements();
      _showSnackBar('Please meet all password requirements');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    _buttonController.forward();

    try {
      // Use email as name for now, or you can add a name field
      await ApiService.register(
        name: email.split('@')[0], // Use email prefix as name
        email: email,
        password: password,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _buttonController.reverse();

        // Registration successful, navigate to email verification
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) {
              return VerifyEmailScreen(
                email: email,
                name: email.split('@')[0],
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _buttonController.reverse();
        
        String errorMessage = 'Registration failed';
        
        if (e.toString().contains('Cannot connect')) {
          errorMessage = 'Cannot connect to server. Check network and backend.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Connection timeout. Check your network.';
        } else {
          errorMessage = e.toString();
        }
        
        _showSnackBar(errorMessage);
        print('🚨 Registration Debug Info: $e');
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSnackBar(String message, {Duration duration = const Duration(seconds: 2)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.error,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPasswordRequirement({
    required String text,
    required bool isMet,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: Listenable.merge([_formController, _shakeController]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeAnimation.value * (!isMet ? 10 * (1 - _shakeAnimation.value) : 0), 
            _formSlideAnimation.value,
          ),
          child: Opacity(
            opacity: _formFadeAnimation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _checkAnimations[index],
                    builder: (context, child) {
                      return Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isMet 
                              ? AppTheme.primaryDarkGreen
                              : Colors.transparent,
                          border: Border.all(
                            color: isMet 
                                ? AppTheme.primaryDarkGreen
                                : AppTheme.textSecondary,
                            width: 2,
                          ),
                        ),
                        child: Transform.scale(
                          scale: _checkAnimations[index].value,
                          child: isMet
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: AppTheme.surfaceWhite,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: isMet 
                            ? AppTheme.primaryDarkGreen
                            : AppTheme.textSecondary,
                        fontSize: 14,
                        fontWeight: isMet 
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                      child: Text(text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 1),
                    
                    // Welcome text
                    AnimatedBuilder(
                      animation: _formController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _formSlideAnimation.value),
                          child: Opacity(
                            opacity: _formFadeAnimation.value,
                            child: Column(
                              children: [
                                Text(
                                  'Welcome!',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.50,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please enter your account here',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Sign Up Form Card
                    AnimatedBuilder(
                      animation: _formController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _formSlideAnimation.value),
                          child: Opacity(
                            opacity: _formFadeAnimation.value,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: AppTheme.cardDecoration(elevation: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email field
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: _emailFocus.hasFocus ? [
                                        BoxShadow(
                                          color: AppTheme.primaryDarkGreen.withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ] : [],
                                    ),
                                    child: TextField(
                                      controller: _emailController,
                                      focusNode: _emailFocus,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Email or phone number',
                                        hintStyle: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: _emailFocus.hasFocus 
                                              ? AppTheme.primaryDarkGreen
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Password field
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      boxShadow: _passwordFocus.hasFocus ? [
                                        BoxShadow(
                                          color: AppTheme.primaryDarkGreen.withOpacity(0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ] : [],
                                    ),
                                    child: TextField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocus,
                                      obscureText: true,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Password',
                                        hintStyle: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.lock_outline,
                                          color: _passwordFocus.hasFocus 
                                              ? AppTheme.primaryDarkGreen
                                              : AppTheme.textSecondary,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(32),
                                          borderSide: BorderSide(
                                            color: (_hasMinLength && _hasNumber && _passwordController.text.isNotEmpty) 
                                                ? AppTheme.primaryDarkGreen
                                                : AppTheme.textDisabled,
                                            width: (_hasMinLength && _hasNumber && _passwordController.text.isNotEmpty) 
                                                ? 2 : 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(32),
                                          borderSide: const BorderSide(
                                            color: AppTheme.primaryDarkGreen,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Password requirements
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your Password must contain:',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildPasswordRequirement(
                                        text: 'At least 6 characters',
                                        isMet: _hasMinLength,
                                        index: 0,
                                      ),
                                      _buildPasswordRequirement(
                                        text: 'Contains a number',
                                        isMet: _hasNumber,
                                        index: 1,
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Sign Up button
                                  AnimatedBuilder(
                                    animation: _buttonController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _buttonScaleAnimation.value,
                                        child: GestureDetector(
                                          onTapDown: (_) {
                                            HapticFeedback.lightImpact();
                                            _buttonController.forward();
                                          },
                                          onTapUp: (_) => _signUp(),
                                          onTapCancel: () {
                                            _buttonController.reverse();
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(vertical: 19),
                                            decoration: AppTheme.primaryGradientDecoration(),
                                            child: _isLoading
                                                ? const Center(
                                                    child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.surfaceWhite),
                                                      ),
                                                    ),
                                                  )
                                                : Text(
                                                    'Sign Up',
                                                    textAlign: TextAlign.center,
                                                    style: Theme.of(context).textTheme.labelLarge,
                                                  ),
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
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Sign in link
                    AnimatedBuilder(
                      animation: _formController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _formSlideAnimation.value),
                          child: Opacity(
                            opacity: _formFadeAnimation.value,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) => const SignIn(),
                                        transitionDuration: const Duration(milliseconds: 500),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(-1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            )),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Text(
                                    'Sign In',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppTheme.primaryDarkGreen,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppTheme.primaryDarkGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const Spacer(flex: 2),
                  ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}