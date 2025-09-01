import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'launch/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qxwcbteqvxvtycstlxgm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4d2NidGVxdnh2dHljc3RseGdtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1ODc1NDksImV4cCI6MjA3MjE2MzU0OX0.I0NerJjitnmGJwTXeZ79ipUZ7n790DIKJuExxYYJX4o',
  );
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
      home: const SplashScreen(),
    );
  }
}
