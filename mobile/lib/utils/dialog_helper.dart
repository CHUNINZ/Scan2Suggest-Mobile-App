import 'package:flutter/material.dart';

/// Comprehensive dialog helper class for consistent UI across the app
class DialogHelper {
  
  // ==================== SUCCESS DIALOGS ====================
  
  /// Show success dialog with custom message
  static void showSuccess(BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: onPressed ?? () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonText ?? "OK"),
          ),
        ],
      ),
    );
  }

  /// Show recipe saved success dialog
  static void showRecipeSaved(BuildContext context, {VoidCallback? onViewRecipe}) {
    showSuccess(
      context,
      title: "Recipe Saved! 🎉",
      message: "Your recipe has been added to your collection.",
      buttonText: "View Recipe",
      onPressed: () {
        Navigator.pop(context);
        onViewRecipe?.call();
      },
    );
  }

  /// Show scan success dialog
  static void showScanSuccess(BuildContext context, {
    required String scanType,
    required int itemCount,
    VoidCallback? onViewResults,
  }) {
    showSuccess(
      context,
      title: "Scan Complete! 🔍",
      message: "Found $itemCount ${scanType.toLowerCase()}${itemCount > 1 ? 's' : ''} in your image.",
      buttonText: "View Results",
      onPressed: () {
        Navigator.pop(context);
        onViewResults?.call();
      },
    );
  }

  // ==================== ERROR DIALOGS ====================
  
  /// Show error dialog with custom message
  static void showError(BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: onPressed ?? () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonText ?? "OK"),
          ),
        ],
      ),
    );
  }

  /// Show network error dialog
  static void showNetworkError(BuildContext context, {VoidCallback? onRetry}) {
    showError(
      context,
      title: "Connection Error 📡",
      message: "Please check your internet connection and try again.",
      buttonText: "Retry",
      onPressed: () {
        Navigator.pop(context);
        onRetry?.call();
      },
    );
  }

  /// Show scan error dialog
  static void showScanError(BuildContext context, {VoidCallback? onRetry}) {
    showError(
      context,
      title: "Scan Failed 🔍",
      message: "Unable to analyze the image. Please try again with better lighting.",
      buttonText: "Try Again",
      onPressed: () {
        Navigator.pop(context);
        onRetry?.call();
      },
    );
  }

  /// Show authentication error dialog
  static void showAuthError(BuildContext context, {VoidCallback? onLogin}) {
    showError(
      context,
      title: "Authentication Required 🔐",
      message: "Please log in to use this feature.",
      buttonText: "Login",
      onPressed: () {
        Navigator.pop(context);
        onLogin?.call();
      },
    );
  }

  // ==================== WARNING DIALOGS ====================
  
  /// Show warning dialog with custom message
  static void showWarning(BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: onCancel ?? () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
            ),
            child: Text(cancelText ?? "Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm?.call();
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText ?? "Confirm"),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog
  static void showDeleteConfirmation(BuildContext context, {
    required String itemName,
    required VoidCallback onDelete,
  }) {
    showWarning(
      context,
      title: "Delete $itemName?",
      message: "This action cannot be undone. Are you sure you want to delete this $itemName?",
      confirmText: "Delete",
      cancelText: "Cancel",
      onConfirm: onDelete,
    );
  }

  /// Show logout confirmation dialog
  static void showLogoutConfirmation(BuildContext context, {required VoidCallback onLogout}) {
    showWarning(
      context,
      title: "Logout?",
      message: "Are you sure you want to logout from your account?",
      confirmText: "Logout",
      cancelText: "Cancel",
      onConfirm: onLogout,
    );
  }

  // ==================== INFO DIALOGS ====================
  
  /// Show info dialog with custom message
  static void showInfo(BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info, color: Colors.blue, size: 28),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: onPressed ?? () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonText ?? "OK"),
          ),
        ],
      ),
    );
  }

  /// Show feature coming soon dialog
  static void showComingSoon(BuildContext context, {required String featureName}) {
    showInfo(
      context,
      title: "Coming Soon! 🚀",
      message: "$featureName feature is currently under development. Stay tuned for updates!",
    );
  }

  // ==================== RATING DIALOGS ====================
  
  /// Show recipe rating dialog (simplified version)
  static void showRecipeRating(BuildContext context, {
    required String recipeName,
    required Function(double rating, String comment) onRatingSubmitted,
  }) {
    double selectedRating = 5.0;
    final TextEditingController commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            const Text(
              "Rate Recipe",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("How was your experience cooking $recipeName?"),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    selectedRating = index + 1.0;
                    (context as Element).markNeedsBuild();
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: "Comment (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRatingSubmitted(selectedRating, commentController.text);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Submit Rating"),
          ),
        ],
      ),
    );
  }

  /// Show app rating dialog (simplified version)
  static void showAppRating(BuildContext context) {
    double selectedRating = 5.0;
    final TextEditingController commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            const Text(
              "Rate Our App",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("If you enjoy using our app, please take a moment to rate it."),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    selectedRating = index + 1.0;
                    (context as Element).markNeedsBuild();
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: "Feedback (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              print('App rating: $selectedRating, comment: ${commentController.text}');
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Submit Rating"),
          ),
        ],
      ),
    );
  }

  // ==================== CUSTOM DIALOGS ====================
  
  /// Show loading dialog
  static void showLoading(BuildContext context, {required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoading(BuildContext context) {
    Navigator.pop(context);
  }

  // ==================== BOTTOM SHEETS ====================
  
  /// Show custom bottom sheet
  static void showCustomBottomSheet(BuildContext context, {
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    showModalBottomSheet(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: child,
      ),
    );
  }

  /// Show scan options bottom sheet
  static void showScanOptions(BuildContext context, {
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    showCustomBottomSheet(
      context,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Choose Image Source",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.camera_alt,
                    title: "Camera",
                    onTap: () {
                      Navigator.pop(context);
                      onCamera();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOptionButton(
                    icon: Icons.photo_library,
                    title: "Gallery",
                    onTap: () {
                      Navigator.pop(context);
                      onGallery();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}