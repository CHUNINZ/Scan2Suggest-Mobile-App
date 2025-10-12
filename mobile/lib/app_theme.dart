import 'package:flutter/material.dart';

class AppTheme {
  // Primary color palette from color.png
  static const Color primaryDarkGreen = Color(0xFF00412E);
  static const Color secondaryLightGreen = Color(0xFF96BF8A);
  static const Color backgroundOffWhite = Color(0xFFE8EAE5);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  
  // Additional supporting colors
  static const Color textPrimary = Color(0xFF2D3D5C);
  static const Color textSecondary = Color(0xFF9FA5C0);
  static const Color textDisabled = Color(0xFFD0DAE9);
  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  
  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDarkGreen, secondaryLightGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      backgroundOffWhite,
      surfaceWhite,
    ],
  );

  // Theme data configuration
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: _createMaterialColor(primaryDarkGreen),
      primaryColor: primaryDarkGreen,
      scaffoldBackgroundColor: backgroundOffWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryDarkGreen,
        secondary: secondaryLightGreen,
        surface: surfaceWhite,
        background: backgroundOffWhite,
        error: error,
        onPrimary: surfaceWhite,
        onSecondary: primaryDarkGreen,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: surfaceWhite,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: primaryDarkGreen),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 8,
        shadowColor: primaryDarkGreen.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: textDisabled),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: textDisabled),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: primaryDarkGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(
          color: textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDarkGreen,
          foregroundColor: surfaceWhite,
          elevation: 8,
          shadowColor: primaryDarkGreen.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(vertical: 19),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDarkGreen,
          side: const BorderSide(color: primaryDarkGreen, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDarkGreen,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryDarkGreen,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        backgroundColor: surfaceWhite,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDarkGreen,
        foregroundColor: surfaceWhite,
        elevation: 8,
        focusElevation: 12,
        hoverElevation: 12,
        highlightElevation: 16,
      ),
      
      // Chip Theme
      chipTheme: const ChipThemeData(
        selectedColor: primaryDarkGreen,
        backgroundColor: surfaceWhite,
        disabledColor: textDisabled,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: surfaceWhite,
        ),
        brightness: Brightness.light,
      ),
      
      // Snack Bar Theme
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: primaryDarkGreen,
        contentTextStyle: TextStyle(
          color: surfaceWhite,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryDarkGreen,
        linearTrackColor: textDisabled,
        circularTrackColor: textDisabled,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: primaryDarkGreen,
        size: 24,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: 0.50,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          letterSpacing: 0.50,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textPrimary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          height: 1.67,
          letterSpacing: 0.50,
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: surfaceWhite,
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),
    );
  }
  
  // Helper method to create MaterialColor from Color
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
  
  // Utility methods for common styling
  static BoxDecoration cardDecoration({double elevation = 8}) {
    return BoxDecoration(
      color: surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: primaryDarkGreen.withOpacity(0.1),
          blurRadius: elevation,
          offset: Offset(0, elevation / 2),
        ),
      ],
    );
  }
  
  static BoxDecoration primaryGradientDecoration({
    BorderRadius? borderRadius,
    double elevation = 8,
  }) {
    return BoxDecoration(
      gradient: primaryGradient,
      borderRadius: borderRadius ?? BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
          color: primaryDarkGreen.withOpacity(0.4),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }
  
  static BoxDecoration backgroundGradientDecoration() {
    return const BoxDecoration(
      gradient: backgroundGradient,
    );
  }
}