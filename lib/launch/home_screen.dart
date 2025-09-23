// File: lib/launch/home_screen.dart
// Purpose: Landing screen showing four primary features (Scan & Protect, 
// Cyber Intel dashboard, Quiz Hub, Ask Ally chatbot). Manages background audio 
// and high‑level navigation.
// Key responsibilities:
// - Start/stop background soundtrack based on lifecycle/navigation
// - Animate and render the feature cards with neon style
// - Route to respective screens on tap
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers package
import '../main.dart'; // Import for route observer access
import 'content_detection_page.dart';
import 'cyber_trends_page.dart';
import 'scenario_knowledge_selection_page.dart'; // Import the ScenarioKnowledgeSelectionPage
import 'ask_ally_chatbot_page.dart'; // Add missing import for AskAllyChatbotPage

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  final AudioPlayer _audioPlayer = AudioPlayer(); // Initialize AudioPlayer
  late AnimationController _animationController;
  late AnimationController _sparkleController; // Add sparkle controller

  // Function to create blurred background for home screen
  Widget _buildBlurredHomeBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image - social media cyberbullying scene
        Image.asset(
          'assets/aftersplash/after_splash_bg.jpeg',
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
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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

  // Function to show exit confirmation dialog
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // User must tap button to close
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: const Color(0xFF00FF88).withOpacity(0.3),
                  width: 1,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00FF88), Color(0xFF00D4FF)],
                      ),
                    ),
                    child: const Icon(
                      Icons.exit_to_app,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Exit Trustify?',
                    style: TextStyle(
                      color: Color(0xFF00FF88),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Are you sure you want to exit the app? Your cyber protection mission will be paused.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              actions: [
                // No button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: const Text(
                    'Stay',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Yes button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    // Close the app completely
                    SystemNavigator.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Exit',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if dialog is dismissed
  }

  void _playStartJingle() async {
    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    await _audioPlayer.setVolume(1.0); // Loud for jingle
    await _audioPlayer.play(AssetSource('sounds/start_jingle.mp3'));
    // Loop background sound with lower volume after ~2.7s (approx jingle length)
    Future.delayed(const Duration(milliseconds: 2700), () async {
      if (mounted) {
        _startBackgroundMusic();
      }
    });
  }

  // Function to start/resume background music
  void _startBackgroundMusic() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setVolume(0.33);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/game_idle.mp3'));
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  // Function to stop background music
  void _stopBackgroundMusic() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('Error stopping background music: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )
      ..repeat();

    // Add sparkle controller for intro-style particles
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )
      ..repeat();

    // Start background music immediately when home screen loads
    _startBackgroundMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route as PageRoute);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _sparkleController.dispose(); // Dispose sparkle controller
    _stopBackgroundMusic();
    super.dispose();
  }

  @override
  void didPush() {
    // Called when this route is pushed onto the navigator
    // Start music when home screen appears
    _startBackgroundMusic();
  }

  @override
  void didPopNext() {
    // Called when a route that was pushed on top of this route is popped
    // This means we're coming back to the home screen
    _startBackgroundMusic();
  }

  // Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Resume background music when app comes back to foreground
      _startBackgroundMusic();
    } else if (state == AppLifecycleState.paused) {
      // Stop music when app goes to background
      _stopBackgroundMusic();
    }
  }

  @override
  void didPushNext() {
    _stopBackgroundMusic();
  }

  @override
  void didPop() {
    _startBackgroundMusic();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return await _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred colorful background
            _buildBlurredHomeBackground(),
            // Sparkle overlay
            SparkleOverlay(sparkleController: _sparkleController),
            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
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
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _GameCard(
                                              title: "🛡️ SCAN & PROTECT",
                                              subtitle: "AI-Powered Content Shield",
                                              gradientColors: const [
                                                Color(0xFF10B981),
                                                Color(0xFF10B981),
                                              ],
                                              iconData: Icons.security,
                                              onTap: () {
                                                _stopBackgroundMusic();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ContentDetectionPage(),
                                                  ),
                                                );
                                              },
                                              quote: "DETECT FAKE CONTENT LIKE A PRO! 🚀",
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _GameCard(
                                              title: "📊 CYBER INTEL",
                                              subtitle: "Victoria Threat Dashboard",
                                              gradientColors: const [
                                                Color(0xFF0A4C85),
                                                Color(0xFF0A4C85),
                                              ],
                                              iconData: Icons.analytics,
                                              onTap: () {
                                                _stopBackgroundMusic();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        CyberTrendsPage(),
                                                  ),
                                                );
                                              },
                                              quote: "STAY AHEAD OF ONLINE RISKS! 🔒",
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _GameCard(
                                              title: "🎯 WISE SWIPE",
                                              subtitle: "Interactive Cyberbullying Quiz Hub",
                                              gradientColors: const [
                                                Color(0xFFF3B11E),
                                                Color(0xFFF3B11E),
                                              ],
                                              iconData: Icons.question_answer,
                                              onTap: () {
                                                _stopBackgroundMusic();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                    const ScenarioKnowledgeSelectionPage(),
                                                  ),
                                                );
                                              },
                                              quote: "READY TO MASTER YOUR DIGITAL WORLD? ⚡️",
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _GameCard(
                                              title: "🤖 ASK ALLY",
                                              subtitle: "Conversational AI Mentor with Explainer Videos",
                                              gradientColors: const [
                                                Color(0xFF10B981),
                                                Color(0xFF10B981),
                                              ],
                                              iconData: Icons.smart_toy,
                                              onTap: () {
                                                _stopBackgroundMusic();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                    const AskAllyChatbotPage(),
                                                  ),
                                                );
                                              },
                                              quote: "YOUR AI COMPANION IS ALWAYS HERE! 💬",
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Small, subtle exit button in top-right corner
            Positioned(
              top: 20,
              right: 20,
              child: GestureDetector(
                onTap: () async {
                  final shouldExit = await _showExitConfirmationDialog(context);
                  if (shouldExit) {
                    SystemNavigator.pop();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.black.withOpacity(0.6),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
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
            padding: const EdgeInsets.all(14), // Increased from 10 to 14
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.black.withOpacity(0.92),
              border: Border.all(
                color: const Color(0xFF10B981), // Added teal border
                width: 2,
              ),
            ),
            child: ShaderMask(
              shaderCallback: (bounds) =>
                  LinearGradient(
                    colors: [
                      Color(0xFF10B981), // Teal
                      Color(0xFF0A4C85), // Blue
                      Color(0xFFF3B11E), // Yellow
                      Color(0xFFE18616), // Orange
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
              child: Text(
                'WELCOME CYBER WARRIOR, YOUR MISSION TO PROTECT YOURSELF STARTS!',
                style: TextStyle(
                  fontSize: 20,
                  // Increased from 18 to 20
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.0,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black,
                      offset: Offset(0, 2),
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
                      Color(0xFF10B981), // Teal
                      Color(0xFF0A4C85), // Blue
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.5),
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
                      Color(0xFFF3B11E), // Orange
                      Color(0xFFF7DC6F), // Yellow
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF3B11E).withOpacity(0.5),
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
                      Color(0xFF10B981), // Teal
                      Color(0xFF0A4C85), // Blue
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.5),
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
              color: const Color(0xFF10B981).withOpacity(0.2),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.4),
                width: 1,
              ),
            ),
            child: const Text(
              '🎮 LEVEL UP YOUR CYBER SKILLS 🛡️',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B981),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData iconData;
  final VoidCallback onTap;
  final String quote;

  const _GameCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.iconData,
    required this.onTap,
    required this.quote,
  }) : super(key: key);

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _showingQuote = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            if (!_showingQuote) {
              setState(() {
                _showingQuote = true;
              });
              AudioPlayer().play(AssetSource('sounds/lightning_crack.mp3'));
              Future.delayed(const Duration(seconds: 3), () {
                widget.onTap();
                setState(() {
                  _showingQuote = false;
                });
              });
            }
          },
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
                color: widget.gradientColors.first.withOpacity(0.8),
              ),
              boxShadow: [
                // Neon glow effect
                BoxShadow(
                  color: widget.gradientColors.first.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: widget.gradientColors.last.withOpacity(0.3),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.gradientColors.first.withOpacity(0.3),
                    widget.gradientColors.last.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                colors: widget.gradientColors),
                            boxShadow: [
                              BoxShadow(
                                color: widget.gradientColors.first.withOpacity(
                                    0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(widget.iconData, size: 28, color: Colors
                              .white),
                        ),
                        const SizedBox(height: 13),
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              LinearGradient(
                                colors: widget.gradientColors,
                              ).createShader(bounds),
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 13.3,
                            fontWeight: FontWeight.w600,
                            color: widget.gradientColors.first,
                            letterSpacing: 0.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                                colors: widget.gradientColors),
                            boxShadow: [
                              BoxShadow(
                                color: widget.gradientColors.first.withOpacity(
                                    0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
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
                ],
              ),
            ),
          ),
        ),
        if (_showingQuote)
          Container(
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
                color: widget.gradientColors.first.withOpacity(0.8),
              ),
              boxShadow: [
                // Neon glow effect
                BoxShadow(
                  color: widget.gradientColors.first.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: widget.gradientColors.last.withOpacity(0.3),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.gradientColors.first.withOpacity(0.3),
                    widget.gradientColors.last.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      LinearGradient(
                        colors: [
                          widget.gradientColors.first,
                          widget.gradientColors.last,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ).createShader(bounds),
                  child: Text(
                    widget.quote,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AskAllyComingSoonPage extends StatelessWidget {
  const AskAllyComingSoonPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new_rounded, color: Color(0xFF0A4C85)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Colors.white,
      body: const Center(
        child: Text(
          'ASK ALLY - AI CHATBOT COMING SOON',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w900,
            fontSize: 23,
            letterSpacing: 1.6,
            color: Color(0xFF0A4C85),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class SparkleOverlay extends StatefulWidget {
  final AnimationController sparkleController;

  const SparkleOverlay({Key? key, required this.sparkleController})
      : super(key: key);

  @override
  _SparkleOverlayState createState() => _SparkleOverlayState();
}

class _MovingEmoji {
  double x;
  double y;
  double speed;
  double size;
  String type;

  _MovingEmoji(
      {required this.x, required this.y, required this.speed, required this.size, required this.type});
}

class _SparkleOverlayState extends State<SparkleOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sparkleAnimation;
  final List<String> _emojiList = [
    '🛡️',
    '⚡',
    '💬',
    '👾',
    '🧑‍💻',
    '🏆',
  ];
  late List<_MovingEmoji> _emojis;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )
      ..addListener(() {
        setState(() {});
      })
      ..repeat();

    // Create animation for sparkle particles
    _sparkleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: widget.sparkleController, curve: Curves.linear),
    );

    _initEmojis();
  }

  void _initEmojis() {
    final w = WidgetsBinding.instance.window.physicalSize.width /
        WidgetsBinding.instance.window.devicePixelRatio;
    final h = WidgetsBinding.instance.window.physicalSize.height /
        WidgetsBinding.instance.window.devicePixelRatio;
    _emojis = List.generate(10, (i) {
      return _MovingEmoji(
        x: Random().nextDouble() * w,
        y: h - Random().nextDouble() * 64,
        speed: 80 + Random().nextDouble() * 140,
        size: 20 + Random().nextDouble() * 22,
        type: _emojiList[Random().nextInt(_emojiList.length)],
      );
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update emoji positions
    for (var i = 0; i < _emojis.length; i++) {
      _emojis[i].y -= _emojis[i].speed * 0.016;
      if (_emojis[i].y < -_emojis[i].size) {
        final w = WidgetsBinding.instance.window.physicalSize.width /
            WidgetsBinding.instance.window.devicePixelRatio;
        final h = WidgetsBinding.instance.window.physicalSize.height /
            WidgetsBinding.instance.window.devicePixelRatio;
        _emojis[i] = _MovingEmoji(
          x: Random().nextDouble() * w,
          y: h - Random().nextDouble() * 64,
          speed: 80 + Random().nextDouble() * 140,
          size: 20 + Random().nextDouble() * 22,
          type: _emojiList[Random().nextInt(_emojiList.length)],
        );
      }
    }

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_animationController, widget.sparkleController]),
      builder: (context, child) {
        return Stack(
          children: [
            // Intro-style sparkle particles
            ...List.generate(15, (index) {
              final offset = (_sparkleAnimation.value * 2 * 3.14159 +
                  index * 0.4) % (2 * 3.14159);
              return Positioned(
                left: 50 + (index % 5) * 80.0 + 30 * sin(offset),
                top: 100 + (index ~/ 5) * 150.0 + 20 * cos(offset * 1.5),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: [
                      const Color(0xFF176CB8), // electric blue
                      const Color(0xFF127C82), // teal
                      const Color(0xFFF3B11E), // yellow
                      const Color(0xFFE18616), // orange
                    ][index % 4].withOpacity(0.7 + 0.3 * sin(offset)),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
            // Existing emoji particles going up
            for (int i = 0; i < _emojis.length; i++)
              Positioned(
                left: _emojis[i].x,
                top: _emojis[i].y,
                child: Text(
                  _emojis[i].type,
                  style: TextStyle(
                    fontSize: _emojis[i].size,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}