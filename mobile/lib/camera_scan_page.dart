import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'services/api_service.dart';
import 'enhanced_scan_results_page.dart';
import 'ingredient_scan_results_page.dart';
import 'progressive_ingredient_scan_page.dart';
import 'utils/dialog_helper.dart';

class CameraScanPage extends StatefulWidget {
  final String scanType; // 'Food' or 'Ingredient'
  
  const CameraScanPage({super.key, required this.scanType});

  @override
  State<CameraScanPage> createState() => _CameraScanPageState();
}

class _CameraScanPageState extends State<CameraScanPage>
    with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isAutoScanning = false;
  bool _flashEnabled = false;
  // bool _frontCamera = false; // Removed unused variable
  List<Map<String, dynamic>> _detectedItems = [];
  
  late AnimationController _scanAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _detectionAnimationController;
  // late Animation<double> _scanAnimation; // Removed unused animation
  late Animation<double> _pulseAnimation;
  late Animation<double> _detectionAnimation;

  @override
  void initState() {
    super.initState();
    
    // If Ingredient scan, redirect to Progressive Ingredient Scan page immediately
    if (widget.scanType.toLowerCase() == 'ingredient') {
      // Use a more immediate redirect
      Future.microtask(() {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProgressiveIngredientScanPage(),
            ),
          );
        }
      });
      return;
    }
    
    // Scanning line animation
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    // _scanAnimation removed - was unused

    // Pulse animation for shutter button
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    // Detection box animation
    _detectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _detectionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _detectionAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _initializeCamera();
    _startAutoScanning();
  }

  @override
  void dispose() {
    _controller?.dispose();
    // Only dispose animation controllers if they were initialized (not redirected)
    if (widget.scanType.toLowerCase() != 'ingredient') {
      _scanAnimationController.dispose();
      _pulseAnimationController.dispose();
      _detectionAnimationController.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      _showPermissionDeniedDialog();
      return;
    }

    try {
      // Get available cameras
      _cameras = await availableCameras();
      
      if (_cameras.isEmpty) {
        _showError('No cameras found');
        return;
      }

      // Initialize with back camera by default
      await _setupCamera(_cameras.first);
    } catch (e) {
      _showError('Error initializing camera: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription camera) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('Error setting up camera: $e');
    }
  }

  void _showPermissionDeniedDialog() {
    DialogHelper.showInfo(
      context,
      title: "Camera Permission Required 📷",
      message: "This app needs camera access to scan food and ingredients. Please grant camera permission in settings.",
      buttonText: "Open Settings",
      onPressed: () {
        Navigator.pop(context);
        openAppSettings();
      },
    );
  }

  void _showError(String message) {
    DialogHelper.showError(
      context,
      title: "Error",
      message: message,
    );
  }

  void _showAuthenticationRequiredDialog() {
    DialogHelper.showAuthError(
      context,
      onLogin: () {
        Navigator.pop(context); // Go back to previous screen
      },
    );
  }

  void _startAutoScanning() {
    // Simulate real-time ingredient detection
    if (widget.scanType == 'Ingredient') {
      Timer.periodic(const Duration(seconds: 3), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        // Real-time detection simulation removed - using real AI detection only
      });
    }
  }


  void _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      _flashEnabled = !_flashEnabled;
      await _controller!.setFlashMode(
        _flashEnabled ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
      HapticFeedback.lightImpact();
    } catch (e) {
      _showError('Error toggling flash: $e');
    }
  }

  void _switchCamera() async {
    if (_cameras.length < 2) return;

    final currentIndex = _cameras.indexOf(_controller!.description);
    final nextIndex = (currentIndex + 1) % _cameras.length;
    
    await _setupCamera(_cameras[nextIndex]);
    setState(() {
      // _frontCamera removed - was unused
    });
    HapticFeedback.lightImpact();
  }

  void _openGallery() async {
    HapticFeedback.lightImpact();
    
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Process the selected image for scanning
        await _processGalleryImage(File(image.path));
      }
    } catch (e) {
      _showError('Error accessing gallery: $e');
    }
  }
  
  Future<void> _processGalleryImage(File imageFile) async {
    setState(() {
      _isScanning = true;
      _detectedItems.clear();
    });

    try {
      print('🔄 Processing gallery image...');
      print('📂 Image path: ${imageFile.path}');
      print('📊 Image size: ${await imageFile.length()} bytes');
      
      // Initialize token first
      await ApiService.initializeToken();
      
      // Test connection to ensure backend is reachable
      final isConnected = await ApiService.testConnection();
      if (!isConnected) {
        throw Exception('Cannot connect to backend server. Check your network connection.');
      }
      
      // Call real AI detection API
      final scanType = widget.scanType.toLowerCase();
      final result = await ApiService.analyzeImage(
        imageFile: imageFile,
        scanType: scanType,
      );

      setState(() {
        _isScanning = false;
      });

      HapticFeedback.heavyImpact();

      // Extract detected item names from API response
      List<String> detectedItems = [];
      if (result['detectedItems'] != null) {
        for (var item in result['detectedItems']) {
          detectedItems.add(item['name'] ?? 'Unknown item');
        }
      }

      // Show success dialog and navigate to results
      DialogHelper.showScanSuccess(
        context,
        scanType: widget.scanType,
        itemCount: detectedItems.length,
        onViewResults: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => widget.scanType.toLowerCase() == 'ingredient'
                  ? IngredientScanResultsPage(imageFile: imageFile)
                  : EnhancedScanResultsPage(
                      imageFile: imageFile,
                      scanType: widget.scanType,
                    ),
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      
      print('❌ Gallery scan error: $e');
      
      String errorMessage = 'Error scanning image';
      if (e.toString().contains('Network') || e.toString().contains('connect')) {
        errorMessage = 'Network error. Check your connection and try again.';
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        errorMessage = 'Authentication required. Please log in to scan images.';
        _showAuthenticationRequiredDialog();
        return;
      }
      
      _showError(errorMessage);
    }
  }

  void _openManualEntry() {
    HapticFeedback.lightImpact();
    DialogHelper.showComingSoon(
      context,
      featureName: "Manual Ingredient Entry",
    );
  }

  void _captureImage() {
    if (_isScanning || !_isInitialized) return;
    _performScan();
  }

  void _performScan() async {
    if (!_isInitialized || _controller == null) return;

    setState(() {
      _isScanning = true;
      _detectedItems.clear();
    });

    HapticFeedback.mediumImpact();
    
    try {
      print('🔄 Starting scan process...');
      
      // Initialize token first
      print('🔑 Initializing authentication token...');
      await ApiService.initializeToken();
      
      // Test connection to ensure backend is reachable
      print('🌐 Testing backend connection...');
      final isConnected = await ApiService.testConnection();
      if (!isConnected) {
        print('❌ Backend connection failed');
        throw Exception('Cannot connect to backend server. Check your network connection.');
      }
      print('✅ Backend connection successful');
      
      // Capture image
      print('📸 Capturing image...');
      final image = await _controller!.takePicture();
      final imageFile = File(image.path);
      print('✅ Image captured: ${image.path}');
      print('📊 Image file size: ${await imageFile.length()} bytes');
      
      // Call real AI detection API
      final scanType = widget.scanType.toLowerCase(); // Convert 'Food' to 'food', 'Ingredient' to 'ingredient'
      print('🤖 Calling AI detection API with scanType: $scanType');
      final result = await ApiService.analyzeImage(
        imageFile: imageFile,
        scanType: scanType,
      );
      print('✅ AI detection API call successful');

      setState(() {
        _isScanning = false;
      });

      HapticFeedback.heavyImpact();

      // Extract detected item names from API response
      List<String> detectedItems = [];
      if (result['detectedItems'] != null) {
        detectedItems = (result['detectedItems'] as List)
            .map((item) => item['name'].toString())
            .toList();
      }

      // If no items detected, show appropriate message
      if (detectedItems.isEmpty) {
        detectedItems = ['No ${scanType}s detected. Try adjusting lighting or angle.'];
      }

      // Show success dialog and navigate to results
      DialogHelper.showScanSuccess(
        context,
        scanType: widget.scanType,
        itemCount: detectedItems.length,
        onViewResults: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => widget.scanType.toLowerCase() == 'ingredient'
                  ? IngredientScanResultsPage(imageFile: imageFile)
                  : EnhancedScanResultsPage(
                      imageFile: imageFile,
                      scanType: widget.scanType,
                    ),
            ),
          );
        },
      );
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      
      print('❌ Scan error occurred: $e');
      print('❌ Error type: ${e.runtimeType}');
      print('❌ Full error details: ${e.toString()}');
      
      // Show more specific error messages
      if (e.toString().contains('Network') || e.toString().contains('connect') || 
          e.toString().contains('SocketException')) {
        DialogHelper.showNetworkError(context, onRetry: _performScan);
      } else if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _showAuthenticationRequiredDialog();
        return;
      } else {
        DialogHelper.showScanError(context, onRetry: _performScan);
      }
      
      // For other errors, just show the error message
      // User can try scanning again
    }
  }


  @override
  Widget build(BuildContext context) {
    // If this is an ingredient scan, show a loading screen while redirecting
    if (widget.scanType.toLowerCase() == 'ingredient') {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.search,
                        color: Colors.green,
                        size: 35,
                      ),
                    ),
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.green,
                        strokeWidth: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '🤖 Loading Progressive Scanner...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Preparing advanced ingredient detection',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_controller!),
          
          // Real-time detection overlays
          if (widget.scanType == 'Ingredient' && !_isScanning)
            _buildRealtimeDetections(),

          // Scanning overlay
          if (_isScanning) _buildScanningOverlay(),

          // Top-left back button
          _buildBackButton(),

          // Top-right control cluster
          _buildTopRightControls(),

          // Bottom control cluster
          _buildBottomControls(),

          // Status bar overlay
          _buildStatusOverlay(),
        ],
      ),
    );
  }



  Widget _buildRealtimeDetections() {
    return AnimatedBuilder(
      animation: _detectionAnimation,
      builder: (context, child) {
        return Stack(
          children: _detectedItems.map((item) {
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            
            return Positioned(
              left: screenWidth * item['x'] * _detectionAnimation.value,
              top: screenHeight * item['y'] * _detectionAnimation.value,
              child: Transform.scale(
                scale: _detectionAnimation.value,
                child: Container(
                  width: screenWidth * item['width'],
                  height: screenHeight * item['height'],
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.green,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Detection label
                      Positioned(
                        top: -25,
                        left: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${item['name']} ${(item['confidence'] * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced AI processing indicator
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      widget.scanType == 'Food' ? Icons.restaurant : Icons.search,
                      color: Colors.green,
                      size: 50,
                    ),
                  ),
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      strokeWidth: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // AI Processing text with animation
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: (0.7 + (_pulseAnimation.value * 0.3)).clamp(0.0, 1.0),
                  child: Text(
                    '🤖 AI Processing ${widget.scanType}...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 12),
            
            // Processing steps
            _buildProcessingSteps(),
            
            const SizedBox(height: 24),
            
            // Progress indicator
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _pulseAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'This may take a few seconds...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingSteps() {
    final steps = widget.scanType == 'Food' 
        ? ['📸 Analyzing image', '🔍 Detecting food items', '🍽️ Identifying dishes']
        : ['📸 Analyzing image', '🔍 Detecting ingredients', '🥬 Identifying items'];
    
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final isActive = _pulseAnimation.value > (index * 0.33);
                  return Icon(
                    isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isActive ? Colors.green : Colors.white.withOpacity(0.5),
                    size: 16,
                  );
                },
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  final isActive = _pulseAnimation.value > (index * 0.33);
                  return Text(
                    step,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopRightControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: Column(
        children: [
          // Flash toggle button
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _flashEnabled 
                  ? Colors.amber.withOpacity(0.9) 
                  : Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: _flashEnabled ? Colors.amber : Colors.white.withOpacity(0.3)
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _toggleFlash,
                child: Icon(
                  _flashEnabled ? Icons.flash_on : Icons.flash_off,
                  color: _flashEnabled ? Colors.black : Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          
          // Camera switch button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: _switchCamera,
                child: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: _openGallery,
                child: const Icon(
                  Icons.photo_library,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          
          // Main capture button with pulse animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isScanning ? 1.0 : _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isScanning ? Colors.grey[300] : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isScanning ? Colors.grey[400]! : Colors.green,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(40),
                      onTap: _isScanning ? null : _captureImage,
                      child: Icon(
                        _isScanning ? Icons.hourglass_empty : Icons.camera_alt,
                        color: _isScanning ? Colors.grey[600] : Colors.green,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Manual entry button
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: _openManualEntry,
                child: const Icon(
                  Icons.keyboard,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusOverlay() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Text(
            widget.scanType == 'Food'
                ? 'Point camera at prepared food dish'
                : _isAutoScanning 
                    ? 'Real-time detection active'
                    : 'Point camera at ingredients',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for grid overlay
class GridPainter extends CustomPainter {
  final double opacity;
  
  GridPainter({required this.opacity});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 1;

    // Draw rule of thirds grid
    final horizontalSpacing = size.height / 3;
    final verticalSpacing = size.width / 3;

    // Horizontal lines
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(0, horizontalSpacing * i),
        Offset(size.width, horizontalSpacing * i),
        paint,
      );
    }

    // Vertical lines
    for (int i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(verticalSpacing * i, 0),
        Offset(verticalSpacing * i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

