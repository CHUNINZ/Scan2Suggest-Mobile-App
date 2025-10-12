import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'splash_screen.dart';
import 'onboarding.dart';
import 'signin.dart';
import 'signup.dart';
import 'main_navigation_controller.dart';
import 'loading_transition.dart';
import 'camera_scan_page.dart';
import 'scan_results_page.dart';
import 'app_theme.dart';

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup error handling
  setupErrorHandling();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set custom error widget for release builds
  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
      return AppErrorWidget(errorDetails: errorDetails);
    };
  }
  
  runApp(const MyApp());
}

// Custom error handler setup
void setupErrorHandling() {
  // Handle Flutter framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      // In debug mode, show the error
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In release mode, log to crash reporting service
      // FirebaseCrashlytics.instance.recordFlutterError(details);
    }
  };

  // Handle errors outside of Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('Uncaught error: $error');
      print('Stack trace: $stack');
    } else {
      // Log to crash reporting service
      // FirebaseCrashlytics.instance.recordError(error, stack);
    }
    return true;
  };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set system UI overlay style for better status bar appearance
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.surfaceWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: AppTheme.surfaceWhite,
      ),
    );

    return MaterialApp(
      title: 'Start Cooking',
      debugShowCheckedModeBanner: false,
      
      // Use the custom theme from AppTheme
      theme: AppTheme.lightTheme,
      
      // Set initial route
      initialRoute: '/',
      
      // Define routes
      routes: {
        '/': (context) => const SplashScreen(),
        '/splash': (context) => const SplashScreen(),
        '/splash-post-signup': (context) => const SplashScreen(isPostSignup: true),
        '/onboarding': (context) => const Onboarding(),
        '/signin': (context) => const SignIn(),
        '/signup': (context) => const SignUp(),
        '/main': (context) => const MainNavigationController(),
        '/loading': (context) => const LoadingTransition(),
      },
      
      // Handle dynamic routes
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/scan':
            final args = settings.arguments as Map<String, dynamic>?;
            return _createRoute(
              CameraScanPage(
                scanType: args?['scanType'] ?? 'Ingredient',
              ),
            );
          case '/scan-results':
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              return _createRoute(
                ScanResultsPage(
                  scanType: args['scanType'] ?? 'Ingredient',
                  detectedItems: List<String>.from(args['detectedItems'] ?? []),
                ),
              );
            }
            return null;
          default:
            return null;
        }
      },
      
      // Handle unknown routes
      onUnknownRoute: (RouteSettings settings) {
        return _createRoute(
          Scaffold(
            backgroundColor: AppTheme.backgroundOffWhite,
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.error,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Page not found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'The requested page could not be found.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
      
      // Wrap the entire app with system UI configuration
      builder: (BuildContext context, Widget? child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: AppTheme.surfaceWhite,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: MediaQuery(
            // Ensure consistent text scaling
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
            ),
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      
      // Localization support (uncomment if needed)
      // localizationsDelegates: const [
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: const [
      //   Locale('en', ''), // English
      //   Locale('tl', ''), // Filipino/Tagalog
      // ],
    );
  }
  
  // Helper method to create consistent page routes
  static PageRoute _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Smooth fade transition
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}

// Error widget for development and production
class AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;
  
  const AppErrorWidget({
    super.key,
    required this.errorDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundOffWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.error,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please restart the app',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Force restart the app
                  SystemNavigator.pop();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Restart App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDarkGreen,
                  foregroundColor: AppTheme.surfaceWhite,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 32),
                const Text(
                  'Debug Information:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      errorDetails.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.error,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}