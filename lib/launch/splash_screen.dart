import 'dart:ui';
import 'package:flutter/material.dart';
import 'intro_screens.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Start animation
    _c.forward();

    // Schedule navigation with clean state management
    _scheduleNavigation();
  }

  void _scheduleNavigation() {
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted && !_navigated) {
        _navigated = true;
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation,
                secondaryAnimation) => const IntroScreensPageView(),
            transitionDuration: const Duration(milliseconds: 600),
            transitionsBuilder: (context, animation, secondaryAnimation,
                child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Function to create blurred background
  Widget _buildBlurredBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Use splash_bg.jpg directly since teen_cyberbullying_bg.jpg is corrupted
        Image.asset(
          'assets/splash/splash_bg.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to gradient background if image fails to load
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A8A), // Deep Blue
                    Color(0xFFEC4899), // Hot Pink
                    Color(0xFF10B981), // Emerald
                    Color(0xFFF59E0B), // Amber
                  ],
                ),
              ),
            );
          },
        ),

        // Progressive blur effect with gradient overlay - same intensity as home screen
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    final slideUp = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));

    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // Blurred background
        _buildBlurredBackground(),

        // Centered logo + funky Trustify text
        Center(
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slideUp,
              child: ScaleTransition(
                scale: scale,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Logo with glow effect
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2EC4B6).withOpacity(0.6),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFFFF6B35).withOpacity(0.4),
                          blurRadius: 50,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: const _Logo(size: 160),
                  ),
                  const SizedBox(height: 32),

                  // Funky "Trustify" text for teenagers with multiple effects
                  _FunkyTrustifyText(),

                  const SizedBox(height: 16),

                  // Subtitle for teens
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2EC4B6).withOpacity(0.8),
                          const Color(0xFF011627).withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Text(
                      'Stay Safe, Stay Smart 🛡️',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _FunkyTrustifyText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ShaderMask(
        shaderCallback: (bounds) =>
            const LinearGradient(
              colors: [
                Color(0xFFFF6B35), // Vibrant Orange
                Color(0xFFFF9F1C), // Golden Yellow
                Color(0xFFFFBF69), // Light Peach
                Color(0xFF2EC4B6), // Turquoise
                Color(0xFF6A4C93), // Purple
                Color(0xFFFF1744), // Hot Pink
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
            ).createShader(bounds),
        child: Text(
          'Trustify',
          style: TextStyle(
            fontSize: 58,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 4.0,
            shadows: [
              Shadow(
                blurRadius: 30,
                color: const Color(0xFF2EC4B6).withOpacity(0.8),
                offset: const Offset(-2, -2),
              ),
              Shadow(
                blurRadius: 30,
                color: const Color(0xFFFF6B35).withOpacity(0.8),
                offset: const Offset(2, 2),
              ),
              Shadow(
                blurRadius: 50,
                color: Colors.black.withOpacity(0.7),
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/icons/trustify_icon_circular_new.png',
        width: size, height: size);
  }
}