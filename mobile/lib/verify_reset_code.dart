import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';
import 'app_theme.dart';
import 'main_navigation_controller.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  final String email;

  const VerifyResetCodeScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  _VerifyResetCodeScreenState createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  late AnimationController _buttonController;
  late Animation<double> _buttonAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _slideController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _verifyCodeAndResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _buttonController.forward();

    try {
      final result = await ApiService.verifyResetCode(
        widget.email,
        _codeController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        _showSnackBar(result['message'] ?? 'Password reset successful', isSuccess: true);
        
        // Navigate to main app after successful reset
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainNavigationController()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to reset password. Please check your code and try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _buttonController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryDarkGreen),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: SlideTransition(
            position: _slideAnimation,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'Verify Code',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    'Enter the 6-digit code sent to ${widget.email}',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  
                  // Verification Code Field
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Verification Code',
                      hintText: 'Enter 6-digit code',
                      prefixIcon: Icon(Icons.security, color: AppTheme.primaryDarkGreen),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryDarkGreen, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the verification code';
                      }
                      if (value.length != 6) {
                        return 'Code must be 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // New Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter new password',
                      prefixIcon: Icon(Icons.lock, color: AppTheme.primaryDarkGreen),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: AppTheme.primaryDarkGreen,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryDarkGreen, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Confirm new password',
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryDarkGreen),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          color: AppTheme.primaryDarkGreen,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryDarkGreen, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  
                  // Reset Password Button
                  ScaleTransition(
                    scale: _buttonAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCodeAndResetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryDarkGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Reset Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Resend Code Button
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Didn\'t receive code? Go back',
                        style: TextStyle(
                          color: AppTheme.primaryDarkGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
