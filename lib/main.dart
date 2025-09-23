// File: lib/main.dart
// Purpose: Flutter app entry point. Loads environment variables, sets theme and
// routes, and boots the initial splash/home navigation.
// Key responsibilities:
// - Loads .env for Azure Function endpoints/keys
// - Provides a global RouteObserver for screen analytics
// - Centralizes routing to Splash and Home screens
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'launch/splash_screen.dart';
import 'launch/home_screen.dart';

// Global route observer for navigation tracking
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: ".env");

  runApp(const TrustifyApp());
}

class TrustifyApp extends StatelessWidget {
  const TrustifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
