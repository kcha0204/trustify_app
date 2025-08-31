import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({super.key, required this.next});
  final Widget next;

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  late final Animation<double> _scale =
  CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
  late final Animation<double> _fade =
  CurvedAnimation(parent: _c, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    _c.forward();
    // Keep splash visible for ~3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.next),
        );
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // 1) Background image
        Image.asset('assets/splash/splash_bg.jpg', fit: BoxFit.cover),

        // 2) Strong blur over the bg
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: const SizedBox.shrink(),
          ),
        ),

        // 3) Logo + name pop & fade in
        Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/trustify_icon.png',
                    width: 148, height: 148,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Trustify',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
