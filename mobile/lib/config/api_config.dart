class ApiConfig {
  
  static const String baseUrl = 'http://192.168.0.105:3000/api';
  
  // API timeout settings
  static const Duration timeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  
  // Development settings
  static const bool isDevelopment = true;
  static const bool enableLogging = true;
  
  // Get the full API URL for a given endpoint
  static String getUrl(String endpoint) {
    return '$baseUrl/$endpoint';
  }
}
