import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'launch/splash_screen.dart';
import 'launch/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qxwcbteqvxvtycstlxgm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4d2NidGVxdnh2dHljc3RseGdtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1ODc1NDksImV4cCI6MjA3MjE2MzU0OX0.I0NerJjitnmGJwTXeZ79ipUZ7n790DIKJuExxYYJX4o',
  );
  runApp(const TrustifyApp());
}

class TrustifyApp extends StatefulWidget {
  const TrustifyApp({super.key});

  @override
  State<TrustifyApp> createState() => _TrustifyAppState();
}

class _TrustifyAppState extends State<TrustifyApp> {
  bool _showSplash = true;
  bool _appInitialized = false;

  @override
  void initState() {
    super.initState();
    // Ensure splash shows for at least a minimum duration
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _appInitialized = true;
        });
      }
    });
  }

  void _hideSplash() {
    if (_appInitialized && mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF033C5A),
      ),
      home: _showSplash
          ? SplashScreen(onComplete: _hideSplash)
          : const HomeScreen(),
    );
  }
}
