import 'dart:ui';
import 'package:flutter/material.dart';
import 'content_detection_page.dart';
import 'cyber_trends_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Function to create blurred background for home screen
  Widget _buildBlurredHomeBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image - social media cyberbullying scene
        Image.asset(
          'assets/splash/cyberbullying_social_bg.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Final fallback gradient background if image is not found
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

        // Same blur intensity as splash screen with matching overlay
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred colorful background
          _buildBlurredHomeBackground(),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cyber Warrior Welcome Message
                  _CyberWarriorWelcome(),

                  const SizedBox(height: 40),

                  // Two main feature cards arranged side by side
                  Expanded(
                    child: Column(
                      children: [
                        // First row of cards
                        Expanded(
                          child: Row(
                            children: [
                              // First Card: Harmful Content Detection
                              Expanded(
                                child: _GameCard(
                                  title: "🛡️ SCAN & PROTECT",
                                  subtitle: "AI-Powered Content Shield",
                                  gradientColors: const [
                                    Color(0xFF00FF88), // Neon Green
                                    Color(0xFF00D4FF), // Cyber Blue
                                  ],
                                  iconData: Icons.security,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (
                                            _) => const ContentDetectionPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Second Card: Cyber Trends Dashboard
                              Expanded(
                                child: _GameCard(
                                  title: "📊 CYBER INTEL",
                                  subtitle: "Victoria Threat Dashboard",
                                  gradientColors: const [
                                    Color(0xFFFF3366), // Electric Pink
                                    Color(0xFF9D4EDD), // Gaming Purple
                                  ],
                                  iconData: Icons.analytics,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const CyberTrendsPage(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Space for future cards (second row)
                        const SizedBox(height: 12),

                        // Placeholder for future cards
                        Expanded(
                          child: Container(
                            // This space is reserved for future cards
                            child: const SizedBox(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberWarriorWelcome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gamified tagline with modern gaming aesthetics
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.4),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF00FF88).withOpacity(0.6),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF88).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  const LinearGradient(
                    colors: [
                      Color(0xFF00FF88), // Neon Green
                      Color(0xFF00D4FF), // Cyber Blue
                      Color(0xFFFF3366), // Electric Pink
                      Color(0xFFFFDD00), // Electric Yellow
                      Color(0xFF9D4EDD), // Gaming Purple
                      Color(0xFF06FFA5), // Matrix Green
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                  ).createShader(bounds),
              child: const Text(
                'Welcome Cyber Warrior, Your mission to protect yourself starts!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  height: 1.3,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Color(0xFF00FF88),
                      offset: Offset(0, 0),
                    ),
                    Shadow(
                      blurRadius: 20,
                      color: Color(0xFF00D4FF),
                      offset: Offset(2, 2),
                    ),
                    Shadow(
                      blurRadius: 30,
                      color: Colors.black87,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Gaming-style decorative elements
          Row(
            children: [
              // Animated-style bars with gaming colors
              Container(
                width: 100,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00FF88), // Neon Green
                      Color(0xFF00D4FF), // Cyber Blue
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF88).withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 80,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF3366), // Electric Pink
                      Color(0xFF9D4EDD), // Gaming Purple
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3366).withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 60,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFFDD00), // Electric Yellow
                      Color(0xFF06FFA5), // Matrix Green
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFDD00).withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Gaming-style subtitle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: const Color(0xFF00FF88).withOpacity(0.2),
              border: Border.all(
                color: const Color(0xFF00FF88).withOpacity(0.4),
                width: 1,
              ),
            ),
            child: const Text(
              '🎮 LEVEL UP YOUR CYBER SKILLS 🛡️',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00FF88),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData iconData;
  final VoidCallback onTap;

  const _GameCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.iconData,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.6),
            ],
          ),
          border: Border.all(
            width: 3,
            color: gradientColors.first.withOpacity(0.8),
          ),
          boxShadow: [
            // Neon glow effect
            BoxShadow(
              color: gradientColors.first.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: gradientColors.last.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
            // Dark shadow for depth
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientColors.first.withOpacity(0.3),
                gradientColors.last.withOpacity(0.2),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with glow effect
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  iconData,
                  size: 32,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Title with gradient text
              ShaderMask(
                shaderCallback: (bounds) =>
                    LinearGradient(
                      colors: gradientColors,
                    ).createShader(bounds),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: gradientColors.first.withOpacity(0.9),
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Gaming-style "ENTER" button
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: gradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.first.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  "ENTER ⚡",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}