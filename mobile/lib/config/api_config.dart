class ApiConfig {
  
  // ========================================
  // 🔧 CHANGE THIS IP ADDRESS WHEN SWITCHING WIFI NETWORKS
  // ========================================
  static const String BACKEND_IP = '10.164.210.221';
  static const String BACKEND_PORT = '3000';
  

  static const bool IS_ANDROID_EMULATOR = false;
  static const bool IS_IOS_SIMULATOR = false;    
  static const bool IS_REAL_DEVICE = true;        
  
  // Primary backend URL (automatically selected based on device type)
  static String get primaryBackendUrl {
    if (IS_ANDROID_EMULATOR) {
      return 'http://10.0.2.2:$BACKEND_PORT/api'; 
    } else if (IS_IOS_SIMULATOR) {
      return 'http://localhost:$BACKEND_PORT/api';
    } else {
      return 'http://$BACKEND_IP:$BACKEND_PORT/api'; 
    }
  }
  
  // Multiple possible server addresses - the app will try each one
  static List<String> get possibleBaseUrls => [
    primaryBackendUrl, 
    'http://$BACKEND_IP:$BACKEND_PORT/api', 
    'http://10.0.2.2:$BACKEND_PORT/api', 
    'http://localhost:$BACKEND_PORT/api', 
  ];
  
  
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
  

}
