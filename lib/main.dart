import 'package:flutter/material.dart';
import 'launch/splash_screen.dart';

void main() => runApp(const TrustifyApp());

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
