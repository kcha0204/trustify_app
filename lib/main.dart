// File: lib/main.dart
// Purpose: Flutter app entry point. Loads environment variables, sets theme and
// routes, and boots the initial splash/home navigation.
// Key responsibilities:
// - Loads .env for Azure Function endpoints/keys
// - Provides a global RouteObserver for screen analytics
// - Centralizes routing to Splash and Home screens
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'launch/splash_screen.dart';
import 'launch/home_screen.dart';
import 'services/notification_service.dart';
import 'services/badge_service.dart';

// Global route observer for navigation tracking
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

// Global navigation key for accessing navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: ".env");

  // Initialize services
  await NotificationService().initialize();
  await BadgeService().initialize();

  // Handle app launch from notification (when app was terminated)
  await _handleAppLaunchFromNotification();

  runApp(const TrustifyApp());
}

// Handle app launch when tapped from notification while app was terminated
Future<void> _handleAppLaunchFromNotification() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Check if app was launched from a notification
  final NotificationAppLaunchDetails? notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
    // App was launched from notification - we'll navigate to home after splash
    // The navigation logic will be handled in the TrustifyApp widget
  }
}

class TrustifyApp extends StatelessWidget {
  const TrustifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trustify',
      navigatorKey: navigatorKey,
      // Add global navigator key
      navigatorObservers: [routeObserver],
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF033C5A),
      ),
      // Always start with splash screen
      home: const SplashScreen(),
      // Add navigation route for better control
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }
}
