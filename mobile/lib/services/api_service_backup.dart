import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  
  static String? _token;
  
  // Initialize token from storage
  static Future<void> initializeToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }
  
  // Test connection to backend
  static Future<bool> testConnection() async {
    try {
      if (ApiConfig.enableLogging) {
        print('🔍 Testing connection to: ${ApiConfig.baseUrl}');
      }
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/test'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (ApiConfig.enableLogging) {
        print('📡 Connection test response: ${response.statusCode}');
      }
      
      return response.statusCode == 200 || response.statusCode == 404; // 404 is OK, means server is reachable
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('❌ Connection test failed: $e');
      }
      return false;
    }
  }
  
  // Save token to storage
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }
  
  // Clear token from storage
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }
  
  // Get headers with optional auth
  static Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (includeAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }
  
  // Handle HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final data = json.decode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else {
      // For error responses, preserve the backend error message
      String errorMessage = data['message'] ?? 'Unknown error occurred';
      
      if (response.statusCode == 400) {
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        throw Exception(errorMessage);
      } else if (response.statusCode == 422) {
        // Validation errors
        if (data['errors'] != null && data['errors'] is List) {
          final errors = data['errors'] as List;
          if (errors.isNotEmpty) {
            errorMessage = errors.first['msg'] ?? errorMessage;
          }
        }
        throw Exception(errorMessage);
      } else {
        throw Exception(errorMessage);
      }
    }
  }

  // Authentication methods
  static Future<Map<String, dynamic>> login(String email, String password) async {
    if (ApiConfig.enableLogging) {
      print('🔐 Logging in user: $email');
      print('🌐 API URL: ${ApiConfig.baseUrl}/auth/login');
    }
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConfig.timeout);

      if (ApiConfig.enableLogging) {
        print('📡 Login response status: ${response.statusCode}');
        print('📡 Login response body: ${response.body}');
      }

      final data = _handleResponse(response);
      
      // Save token if provided
      if (data['token'] != null) {
        await saveToken(data['token']);
        if (ApiConfig.enableLogging) {
          print('🔐 Token saved');
        }
      }
      
      if (ApiConfig.enableLogging) {
        print('✅ Login successful');
      }
      
      return data;
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('❌ Login error: $e');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    if (ApiConfig.enableLogging) {
      print('🔄 Requesting password reset for: $email');
    }
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
        headers: _getHeaders(includeAuth: false),
        body: json.encode({'email': email}),
      ).timeout(ApiConfig.timeout);

      if (ApiConfig.enableLogging) {
        print('📡 Forgot password response: ${response.statusCode}');
      }

      return _handleResponse(response);
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('❌ Forgot password error: $e');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyResetCode(String email, String code) async {
    if (ApiConfig.enableLogging) {
      print('🔄 Verifying reset code for: $email');
    }
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-reset-code'),
        headers: _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'code': code,
        }),
      ).timeout(ApiConfig.timeout);

      if (ApiConfig.enableLogging) {
        print('📡 Verify reset code response: ${response.statusCode}');
      }

      return _handleResponse(response);
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('❌ Verify reset code error: $e');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    if (ApiConfig.enableLogging) {
      print('🔄 Resetting password for: $email');
    }
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
        headers: _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      ).timeout(ApiConfig.timeout);

      if (ApiConfig.enableLogging) {
        print('📡 Reset password response: ${response.statusCode}');
      }

      return _handleResponse(response);
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('❌ Reset password error: $e');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (ApiConfig.enableLogging) {
      print('📝 Registering user: $email');
      print('🌐 API URL: ${ApiConfig.baseUrl}/auth/register');
    }
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: _getHeaders(includeAuth: false),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(ApiConfig.timeout);

      if (ApiConfig.enableLogging) {
        print('📡 Register response status: ${response.statusCode}');
        print('📡 Register response body: ${response.body}');
      }

      final data = _handleResponse(response);
      
      if (ApiConfig.enableLogging) {
        print('✅ Registration request completed');
      }
      
      return data;
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('❌ Registration error: $e');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      if (ApiConfig.enableLogging) {
        print('🔄 Verifying email for: $email');
      }
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-email'),
        headers: _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'code': code,
        }),
      ).timeout(ApiConfig.timeout);

      if (ApiConfig.enableLogging) {
        print('📡 Verify email response: ${response.statusCode}');
      }

      final data = _handleResponse(response);
      
      // Save token if provided after email verification
      if (data['token'] != null) {
        await saveToken(data['token']);
        if (ApiConfig.enableLogging) {
          print('🔐 Token saved after email verification');
        }
      }
      
      return data;
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('❌ Email verification error: $e');
      }
      rethrow;
    }
  }
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-reset-code'),
        headers: _getHeaders(includeAuth: false),
        body: json.encode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      ).timeout(ApiConfig.timeout);

      if (ApiConfig.enableLogging) {
        print('📡 Verify reset code response status: ${response.statusCode}');
        print('📡 Verify reset code response body: ${response.body}');
      }

      final data = _handleResponse(response);
      
      // Save token if provided
      if (data['token'] != null) {
        await saveToken(data['token']);
        if (ApiConfig.enableLogging) {
          print('✅ Password reset successful, token saved');
        }
      }
      
      return data;
    } catch (e) {
      if (ApiConfig.enableLogging) {
        print('❌ Verify reset code error: $e');
      }
      rethrow;
    }
  }
  
  static Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$ApiConfig.baseUrl/auth/me'),
      headers: _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('$ApiConfig.baseUrl/auth/logout'),
      headers: _getHeaders(),
    );
    
    await clearToken();
    return _handleResponse(response);
  }
  
  // User APIs
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? bio,
    String? location,
    Map<String, dynamic>? preferences,
  }) async {
    final response = await http.put(
      Uri.parse('$ApiConfig.baseUrl/users/profile'),
      headers: _getHeaders(),
      body: json.encode({
        'name': name,
        'bio': bio,
        'location': location,
        'preferences': preferences,
      }),
    );
    
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$ApiConfig.baseUrl/users/upload-avatar'),
    );
    
    request.headers.addAll(_getMultipartHeaders());
    request.files.add(
      await http.MultipartFile.fromPath('profileImage', imageFile.path),
    );
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    return _handleResponse(response);
  }
  
  // Recipe APIs
  static Future<Map<String, dynamic>> getRecipes({
    int page = 1,
    int limit = 10,
    String? category,
    String? difficulty,
    String? search,
    String sort = 'createdAt',
    String order = 'desc',
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'sort': sort,
      'order': order,
    };
    
    if (category != null) queryParams['category'] = category;
    if (difficulty != null) queryParams['difficulty'] = difficulty;
    if (search != null) queryParams['search'] = search;
    
    final uri = Uri.parse('$ApiConfig.baseUrl/recipes').replace(
      queryParameters: queryParams,
    );
    
    final response = await http.get(uri, headers: _getHeaders(includeAuth: false));
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> getRecipe(String recipeId) async {
    final response = await http.get(
      Uri.parse('$ApiConfig.baseUrl/recipes/$recipeId'),
      headers: _getHeaders(includeAuth: false),
    );
    
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> createRecipe({
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required int prepTime,
    required int cookTime,
    required int servings,
    required List<Map<String, dynamic>> ingredients,
    required List<Map<String, dynamic>> instructions,
    List<File>? images,
    Map<String, dynamic>? nutrition,
    List<String>? tags,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$ApiConfig.baseUrl/recipes'),
    );
    
    request.headers.addAll(_getMultipartHeaders());
    
    // Add text fields
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['category'] = category;
    request.fields['difficulty'] = difficulty;
    request.fields['prepTime'] = prepTime.toString();
    request.fields['cookTime'] = cookTime.toString();
    request.fields['servings'] = servings.toString();
    request.fields['ingredients'] = json.encode(ingredients);
    request.fields['instructions'] = json.encode(instructions);
    
    if (nutrition != null) {
      request.fields['nutrition'] = json.encode(nutrition);
    }
    
    if (tags != null) {
      request.fields['tags'] = json.encode(tags);
    }
    
    // Add image files
    if (images != null) {
      for (final image in images) {
        request.files.add(
          await http.MultipartFile.fromPath('recipeImages', image.path),
        );
      }
    }
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> likeRecipe(String recipeId) async {
    final response = await http.post(
      Uri.parse('$ApiConfig.baseUrl/recipes/$recipeId/like'),
      headers: _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> bookmarkRecipe(String recipeId) async {
    final response = await http.post(
      Uri.parse('$ApiConfig.baseUrl/recipes/$recipeId/bookmark'),
      headers: _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> rateRecipe({
    required String recipeId,
    required int rating,
    String? review,
  }) async {
    final response = await http.post(
      Uri.parse('$ApiConfig.baseUrl/recipes/$recipeId/rate'),
      headers: _getHeaders(),
      body: json.encode({
        'rating': rating,
        'review': review,
      }),
    );
    
    return _handleResponse(response);
  }
  
  // Scanning APIs
  static Future<Map<String, dynamic>> analyzeImage({
    required File imageFile,
    required String scanType, // 'food' or 'ingredient'
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$ApiConfig.baseUrl/scan/analyze'),
    );
    
    request.headers.addAll(_getMultipartHeaders());
    request.fields['scanType'] = scanType;
    request.files.add(
      await http.MultipartFile.fromPath('scanImage', imageFile.path),
    );
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> getScanResult(String scanId) async {
    final response = await http.get(
      Uri.parse('$ApiConfig.baseUrl/scan/result/$scanId'),
      headers: _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> getScanHistory({
    int page = 1,
    int limit = 10,
    String? scanType,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (scanType != null) queryParams['scanType'] = scanType;
    
    final uri = Uri.parse('$ApiConfig.baseUrl/scan/history').replace(
      queryParameters: queryParams,
    );
    
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }
  
  // Social APIs
  static Future<Map<String, dynamic>> followUser(String userId) async {
    final response = await http.post(
      Uri.parse('$ApiConfig.baseUrl/social/follow/$userId'),
      headers: _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> getSocialFeed({
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    final uri = Uri.parse('$ApiConfig.baseUrl/social/feed').replace(
      queryParameters: queryParams,
    );
    
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> getTrendingRecipes({
    int page = 1,
    int limit = 10,
    String timeframe = 'week',
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'timeframe': timeframe,
    };
    
    final uri = Uri.parse('$ApiConfig.baseUrl/social/trending').replace(
      queryParameters: queryParams,
    );
    
    final response = await http.get(uri, headers: _getHeaders(includeAuth: false));
    return _handleResponse(response);
  }
  
  // Notification APIs
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'unreadOnly': unreadOnly.toString(),
    };
    
    final uri = Uri.parse('$ApiConfig.baseUrl/notifications').replace(
      queryParameters: queryParams,
    );
    
    final response = await http.get(uri, headers: _getHeaders());
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    final response = await http.put(
      Uri.parse('$ApiConfig.baseUrl/notifications/$notificationId/read'),
      headers: _getHeaders(),
    );
    
    return _handleResponse(response);
  }
  
  static Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    final response = await http.put(
      Uri.parse('$ApiConfig.baseUrl/notifications/read-all'),
      headers: _getHeaders(),
    );
    
    return _handleResponse(response);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic errors;
  
  ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
  });
  
  @override
  String toString() {
    return message;
  }
}
