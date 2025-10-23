import 'package:flutter/material.dart';

class NavigationHelper {
  static int? _pendingTabIndex;
  
  static void navigateToTab(BuildContext context, int tabIndex) {
    // Store the desired tab index
    _pendingTabIndex = tabIndex;
    print('NavigationHelper: Storing pending tab index: $tabIndex');
    
    // Navigate back to main app
    Navigator.pop(context);
    
    // Use a small delay to ensure the pop completes
    Future.delayed(const Duration(milliseconds: 100), () {
      // Navigate to the main app
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/main',
        (route) => false,
      );
    });
  }
  
  static int? getPendingTabIndex() {
    final index = _pendingTabIndex;
    _pendingTabIndex = null; // Clear after getting
    return index;
  }
  
  static void navigateToHome(BuildContext context) {
    navigateToTab(context, 0);
  }
  
  static void navigateToDiscover(BuildContext context) {
    navigateToTab(context, 1);
  }
  
  static void navigateToUpload(BuildContext context) {
    navigateToTab(context, 3);
  }
  
  static void navigateToSettings(BuildContext context) {
    navigateToTab(context, 4);
  }
}
