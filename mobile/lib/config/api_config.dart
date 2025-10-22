class ApiConfig {
  
  // ========================================
  // 🔧 CHANGE THIS IP ADDRESS WHEN SWITCHING WIFI NETWORKS
  // ========================================
  static const String BACKEND_IP = '10.196.73.221'; // <-- UPDATE THIS IP ONLY
  static const String BACKEND_PORT = '3000';
  
  // ⚠️ DEVICE TYPE SELECTION:
  // Uncomment ONE of these based on your testing device:
  static const bool IS_ANDROID_EMULATOR = false;  // Set to true if using Android Emulator
  static const bool IS_IOS_SIMULATOR = false;     // Set to true if using iOS Simulator
  static const bool IS_REAL_DEVICE = true;        // Set to true if using real phone
  
  // Primary backend URL (automatically selected based on device type)
  static String get primaryBackendUrl {
    if (IS_ANDROID_EMULATOR) {
      return 'http://10.0.2.2:$BACKEND_PORT/api'; // Android emulator host
    } else if (IS_IOS_SIMULATOR) {
      return 'http://localhost:$BACKEND_PORT/api'; // iOS simulator
    } else {
      return 'http://$BACKEND_IP:$BACKEND_PORT/api'; // Real device
    }
  }
  
  // Multiple possible server addresses - the app will try each one
  static List<String> get possibleBaseUrls => [
    primaryBackendUrl, // Primary URL based on device type above
    'http://$BACKEND_IP:$BACKEND_PORT/api', // Your computer's IP
    'http://10.0.2.2:$BACKEND_PORT/api', // Android emulator fallback
    'http://localhost:$BACKEND_PORT/api', // iOS simulator fallback
  ];
  
  // Current working base URL (will be set after connection test)
  static String baseUrl = '';
  
  // Initialize baseUrl with primary URL if empty
  static void _initializeBaseUrl() {
    if (baseUrl.isEmpty) {
      baseUrl = primaryBackendUrl;
      if (enableLogging) {
        print('🔧 Initialized baseUrl to: $baseUrl');
      }
    }
  }
  
  // Ensure baseUrl is always initialized
  static String get safeBaseUrl {
    _initializeBaseUrl();
    return baseUrl;
  }
  
  // API timeout settings
  static const Duration timeout = Duration(seconds: 10);
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const int maxRetries = 3;
  
  // Development settings
  static const bool isDevelopment = true;
  static const bool enableLogging = true;
  
  // Get the full API URL for a given endpoint
  static String getUrl(String endpoint) {
    _initializeBaseUrl();
    return '$baseUrl/$endpoint';
  }
  
  // Update the base URL when a working one is found
  static void setWorkingBaseUrl(String workingUrl) {
    baseUrl = workingUrl;
    if (enableLogging) {
      print('✅ Using API base URL: $baseUrl');
    }
  }
  
  // ========================================
  // 📝 SETUP INSTRUCTIONS:
  // ========================================
  // 
  // FOR REAL DEVICE (Phone/Tablet):
  // 1. Make sure your phone and computer are on the SAME WiFi network
  // 2. Find your computer's IP: Open terminal and run: ifconfig | grep "inet "
  // 3. Update BACKEND_IP above with your computer's IP
  // 4. Set IS_REAL_DEVICE = true (and others to false)
  // 5. Restart the app completely (stop and rebuild)
  //
  // FOR ANDROID EMULATOR:
  // 1. Set IS_ANDROID_EMULATOR = true (and others to false)
  // 2. Restart the app
  //
  // FOR iOS SIMULATOR:
  // 1. Set IS_IOS_SIMULATOR = true (and others to false)
  // 2. Restart the app
  //
  // ⚠️ TROUBLESHOOTING:
  // - If you get "Connection refused", make sure backend is running: 
  //   cd backend && npm start
  // - Test backend: curl http://YOUR_IP:3000/api/health
  // - Uninstall and reinstall the app if config changes don't work
  // ========================================
}
