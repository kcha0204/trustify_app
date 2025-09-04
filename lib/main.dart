import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'launch/splash_screen.dart';
import 'launch/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: ".env");

  try {
    await Supabase.initialize(
      url:
          dotenv.env['SUPABASE_URL'] ??
          'https://qxwcbteqvxvtycstlxgm.supabase.co',
      anonKey:
          dotenv.env['SUPABASE_ANON_KEY'] ??
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4d2NidGVxdnh2dHljc3RseGdtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1ODc1NDksImV4cCI6MjA3MjE2MzU0OX0.I0NerJjitnmGJwTXeZ79ipUZ7n790DIKJuExxYYJX4o',
    );
  } catch (e) {
    // Continue even if Supabase fails to initialize
    print('Supabase initialization failed: $e');
  }

  runApp(const TrustifyApp());
}

class TrustifyApp extends StatelessWidget {
  const TrustifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
