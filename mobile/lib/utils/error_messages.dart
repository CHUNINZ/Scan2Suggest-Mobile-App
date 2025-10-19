/// Centralized error message utility for consistent error handling
class ErrorMessages {
  // Network errors
  static const String networkError = 'Network connection failed. Please check your internet connection and try again.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String serverError = 'Server is temporarily unavailable. Please try again later.';
  static const String connectionRefused = 'Unable to connect to server. Please check your network settings.';
  
  // Authentication errors
  static const String invalidCredentials = 'Invalid email or password. Please check your credentials and try again.';
  static const String userNotFound = 'No account found with this email address.';
  static const String emailAlreadyExists = 'An account with this email already exists. Please use a different email or try signing in.';
  static const String weakPassword = 'Password must be at least 6 characters long.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String tokenExpired = 'Your session has expired. Please sign in again.';
  static const String unauthorized = 'You are not authorized to perform this action.';
  
  // Email verification errors
  static const String emailNotVerified = 'Please verify your email address before continuing.';
  static const String invalidVerificationCode = 'Invalid verification code. Please check the code and try again.';
  static const String verificationCodeExpired = 'Verification code has expired. Please request a new one.';
  static const String emailVerificationFailed = 'Email verification failed. Please try again or contact support.';
  
  // File upload errors
  static const String fileTooLarge = 'File size is too large. Please select a smaller image (max 5MB).';
  static const String invalidFileType = 'Invalid file type. Please select a valid image file (JPG, PNG, GIF).';
  static const String uploadFailed = 'Failed to upload file. Please try again.';
  static const String noFileSelected = 'Please select a file to upload.';
  
  // Recipe errors
  static const String recipeNotFound = 'Recipe not found. It may have been deleted or is no longer available.';
  static const String recipeCreationFailed = 'Failed to create recipe. Please check your input and try again.';
  static const String recipeUpdateFailed = 'Failed to update recipe. Please try again.';
  static const String recipeDeleteFailed = 'Failed to delete recipe. Please try again.';
  static const String invalidRecipeData = 'Invalid recipe data. Please check all required fields.';
  
  // Social features errors
  static const String followFailed = 'Failed to follow user. Please try again.';
  static const String unfollowFailed = 'Failed to unfollow user. Please try again.';
  static const String likeFailed = 'Failed to like recipe. Please try again.';
  static const String bookmarkFailed = 'Failed to bookmark recipe. Please try again.';
  static const String ratingFailed = 'Failed to submit rating. Please try again.';
  
  // Scanning errors
  static const String scanFailed = 'Failed to scan image. Please try again with a clearer image.';
  static const String noIngredientsDetected = 'No ingredients detected in the image. Please try a different image or add ingredients manually.';
  static const String scanTimeout = 'Scan is taking too long. Please try again.';
  static const String cameraPermissionDenied = 'Camera permission is required to scan images. Please enable camera access in settings.';
  static const String galleryPermissionDenied = 'Gallery permission is required to select images. Please enable gallery access in settings.';
  
  // Profile errors
  static const String profileUpdateFailed = 'Failed to update profile. Please try again.';
  static const String profileImageUpdateFailed = 'Failed to update profile image. Please try again.';
  static const String invalidProfileData = 'Invalid profile data. Please check your input.';
  
  // Notification errors
  static const String notificationLoadFailed = 'Failed to load notifications. Please try again.';
  static const String notificationMarkReadFailed = 'Failed to mark notification as read.';
  
  // General errors
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  static const String dataLoadFailed = 'Failed to load data. Please try again.';
  static const String operationFailed = 'Operation failed. Please try again.';
  static const String validationFailed = 'Please check your input and try again.';
  
  // Success messages
  static const String profileUpdated = 'Profile updated successfully!';
  static const String recipeCreated = 'Recipe created successfully!';
  static const String recipeUpdated = 'Recipe updated successfully!';
  static const String recipeDeleted = 'Recipe deleted successfully!';
  static const String userFollowed = 'You are now following this user!';
  static const String userUnfollowed = 'You have unfollowed this user.';
  static const String recipeLiked = 'Recipe liked!';
  static const String recipeUnliked = 'Recipe unliked.';
  static const String recipeBookmarked = 'Recipe bookmarked!';
  static const String recipeUnbookmarked = 'Recipe removed from bookmarks.';
  static const String ratingSubmitted = 'Rating submitted successfully!';
  static const String emailSent = 'Email sent successfully!';
  static const String emailVerified = 'Email verified successfully!';
  
  /// Get user-friendly error message from API response
  static String getApiErrorMessage(dynamic error) {
    if (error is String) {
      return error;
    }
    
    if (error is Map<String, dynamic>) {
      // Check for specific error types
      if (error.containsKey('message')) {
        return error['message'].toString();
      }
      
      if (error.containsKey('error')) {
        return error['error'].toString();
      }
      
      // Check for validation errors
      if (error.containsKey('errors')) {
        final errors = error['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.first.toString();
        }
        if (errors is Map && errors.isNotEmpty) {
          return errors.values.first.toString();
        }
      }
    }
    
    return unknownError;
  }
  
  /// Get specific error message based on HTTP status code
  static String getHttpErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Authentication required. Please sign in again.';
      case 403:
        return 'Access denied. You do not have permission to perform this action.';
      case 404:
        return 'Resource not found. The requested item may have been deleted.';
      case 409:
        return 'Conflict detected. The resource already exists or is in use.';
      case 422:
        return 'Validation failed. Please check your input and try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Server temporarily unavailable. Please try again later.';
      case 503:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return 'An error occurred (${statusCode}). Please try again.';
    }
  }
  
  /// Get error message for specific operation
  static String getOperationErrorMessage(String operation, dynamic error) {
    final baseMessage = getApiErrorMessage(error);
    
    switch (operation.toLowerCase()) {
      case 'login':
        return baseMessage.contains('invalid') ? invalidCredentials : baseMessage;
      case 'register':
        return baseMessage.contains('exists') ? emailAlreadyExists : baseMessage;
      case 'upload':
        return baseMessage.contains('large') ? fileTooLarge : uploadFailed;
      case 'scan':
        return baseMessage.contains('detect') ? noIngredientsDetected : scanFailed;
      case 'follow':
        return followFailed;
      case 'like':
        return likeFailed;
      case 'bookmark':
        return bookmarkFailed;
      default:
        return baseMessage;
    }
  }
}
