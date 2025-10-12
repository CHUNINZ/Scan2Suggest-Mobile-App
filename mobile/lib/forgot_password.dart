import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'app_theme.dart';
import 'verify_reset_code.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;
  
  late AnimationController _fadeController;
  late AnimationController _buttonController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fadeController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackBar('Please enter your email address');
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showSnackBar('Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _buttonController.forward();

    try {
      final result = await ApiService.forgotPassword(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _buttonController.reverse();
        
        // Check if email was actually sent
        bool emailSent = result['emailSent'] ?? false;
        
        if (emailSent) {
          _showSnackBar('Verification code sent to your email. Please check your inbox.', isSuccess: true);
        } else {
          _showSnackBar('Verification code sent. Check your email or console logs.', isSuccess: true);
        }
        
        // Navigate to verification code screen
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VerifyResetCodeScreen(
                email: _emailController.text.trim(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _buttonController.reverse();
        _showSnackBar('Failed to send verification code. Please try again.');
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryDarkGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Forgot Password',
          style: TextStyle(
            color: AppTheme.primaryDarkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Icon
              Container(
                alignment: Alignment.center,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDarkGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 50,
                    color: AppTheme.primaryDarkGreen,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title and Description
              Text(
                _emailSent ? 'Check Your Email' : 'Reset Your Password',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              Text(
                _emailSent 
                    ? 'We\'ve sent password reset instructions to ${_emailController.text.trim()}'
                    : 'Enter your email address and we\'ll send you instructions to reset your password.',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              if (!_emailSent) ...[
                // Email Input
                Container(
                  decoration: AppTheme.cardDecoration(),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleForgotPassword(),
                    decoration: const InputDecoration(
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryDarkGreen),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Send Reset Button
                AnimatedBuilder(
                  animation: _buttonAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _buttonAnimation.value,
                      child: Container(
                        width: double.infinity,
                        height: 56,
                        decoration: AppTheme.primaryGradientDecoration(),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _isLoading ? null : _handleForgotPassword,
                            child: Container(
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Send Reset Instructions',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                // Success Actions
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: AppTheme.primaryGradientDecoration(),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context),
                      child: const Center(
                        child: Text(
                          'Back to Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Resend Button
                TextButton(
                  onPressed: () {
                    setState(() {
                      _emailSent = false;
                    });
                  },
                  child: const Text(
                    'Didn\'t receive email? Try again',
                    style: TextStyle(
                      color: AppTheme.primaryDarkGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Back to Sign In Link
              if (!_emailSent)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      text: 'Remember your password? ',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: AppTheme.primaryDarkGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
