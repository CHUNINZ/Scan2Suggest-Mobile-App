import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';
import 'app_theme.dart';
import 'main_navigation_controller.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String name;

  const VerifyEmailScreen({
    Key? key,
    required this.email,
    required this.name,
  }) : super(key: key);

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  
  bool _isLoading = false;
  
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

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _buttonController.forward();

    try {
      final result = await ApiService.verifyEmail(
        email: widget.email,
        code: _codeController.text.trim(),
      );
      
      if (mounted) {
        // Save token and user data
        await ApiService.saveToken(result['token']);
        
        _showSnackBar(result['message'] ?? 'Email verified successfully!', isSuccess: true);
        
        // Navigate to main app after successful verification
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
        _showSnackBar('Failed to verify email. Please check your code and try again.');
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

  Future<void> _resendCode() async {
    try {
      final result = await ApiService.resendVerificationCode(
        email: widget.email,
      );
      
      if (result['success']) {
        _showSnackBar('Verification code sent again. Please check your email.', isSuccess: true);
      } else {
        _showSnackBar(result['message'] ?? 'Failed to resend code. Please try again.');
      }
    } catch (e) {
      _showSnackBar('Failed to resend code. Please try again.');
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
                        Icons.email_outlined,
                        size: 50,
                        color: AppTheme.primaryDarkGreen,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDarkGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  Text(
                    'We\'ve sent a 6-digit verification code to ${widget.email}. Please enter it below to complete your registration.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
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
                  const SizedBox(height: 40),
                  
                  // Verify Button
                  ScaleTransition(
                    scale: _buttonAnimation,
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyEmail,
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
                                'Verify Email',
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
                      onPressed: _resendCode,
                      child: Text(
                        'Didn\'t receive code? Resend',
                        style: TextStyle(
                          color: AppTheme.primaryDarkGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Help text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Having trouble?',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Check your spam/junk folder\n• Make sure you entered the correct email\n• The code expires in 10 minutes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[600],
                            height: 1.4,
                          ),
                        ),
                      ],
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
