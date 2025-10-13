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
import '../services/notification_service.dart';
import '../services/badge_service.dart';
import 'content_detection_page.dart';
import 'cyber_trends_page.dart';
import 'scenario_knowledge_selection_page.dart'; // Import the ScenarioKnowledgeSelectionPage
import 'ask_ally_chatbot_page.dart'; // Add missing import for AskAllyChatbotPage
import 'notifications_page.dart';
import 'randrisk_page.dart'; // Import the RandRiskPage

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
  final NotificationService _notificationService = NotificationService();
  final BadgeService _badgeService = BadgeService();

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
    )..repeat();

    // Add sparkle controller for intro-style particles
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

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
            // Main content with fixed top icons and bottom nav
            SafeArea(
              child: Column(
                children: [
                  // Fixed top icons row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _StreakIconWidget(badgeService: _badgeService),
                            const SizedBox(width: 10),
                            // gap between badge and streak box
                            ListenableBuilder(
                              listenable: _badgeService,
                              builder: (context, child) {
                                final badgeColor = Color(
                                    _badgeService.getColor());
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                        color: badgeColor, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: badgeColor.withOpacity(0.17),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${_badgeService.currentStreaks} streaks',
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        _NotificationBellWidget(
                            notificationService: _notificationService),
                      ],
                    ),
                  ),
                  // Scrollable content area
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                          16.0, 20.0, 16.0, 16.0),
                      child: SizedBox(
                        height: MediaQuery
                            .of(context)
                            .size
                            .height - 220,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Welcome Box
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.black.withOpacity(0.92),
                                border: Border.all(
                                  color: const Color(0xFF10B981),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(
                                        0.2),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Decorative line on top
                                  Container(
                                    height: 3,
                                    width: 80,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF176CB8),
                                          Color(0xFF127C82)
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Main heading with blue-teal gradient
                                  ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [
                                            Color(0xFF176CB8),
                                            Color(0xFF127C82)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ).createShader(bounds),
                                    child: const Text(
                                      'WELCOME CYBER WARRIOR, YOUR MISSION TO PROTECT YOURSELF STARTS!',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1.0,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  // Subtitle text in teal
                                  const Text(
                                    'Your digital shield, your learning arena, your power-up zone.\nHere you can level up your knowledge, unlock tips to stay safe, and equip yourself with tools to block out the bullies. Level up. Earn badges. Keep streaks.\nProtect your vibe, master your world',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF127C82),
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 28),
                                  // Green Scan & Protect Button (matching notification icon)
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF0D9D6F)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF10B981)
                                              .withOpacity(0.4),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        AudioPlayer().play(AssetSource(
                                            'sounds/lightning_crack.mp3'));
                                        _stopBackgroundMusic();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ContentDetectionPage(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 36,
                                          vertical: 18,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              15),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '🛡️',
                                            style: TextStyle(fontSize: 18),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'SCAN & PROTECT',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.8,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
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
                ],
              ),
            ),
            // Fixed bottom navigation bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.92),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavBarIcon(
                          icon: Icons.analytics,
                          label: 'Cyber Intel',
                          color: Color(0xFF176CB8),
                          onTap: () {
                            AudioPlayer().play(
                                AssetSource('sounds/lightning_crack.mp3'));
                            _stopBackgroundMusic();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CyberTrendsPage()),
                            );
                          },
                        ),
                        _NavBarIcon(
                          icon: Icons.question_answer,
                          label: 'Wise Swipe',
                          color: Color(0xFFF3B11E),
                          onTap: () {
                            AudioPlayer().play(
                                AssetSource('sounds/lightning_crack.mp3'));
                            _stopBackgroundMusic();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (
                                    _) => const ScenarioKnowledgeSelectionPage(),
                              ),
                            );
                          },
                        ),
                        _NavBarIcon(
                          icon: Icons.smart_toy,
                          label: 'Ask Ally',
                          color: Color(0xFF10B981),
                          onTap: () {
                            AudioPlayer().play(
                                AssetSource('sounds/lightning_crack.mp3'));
                            _stopBackgroundMusic();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AskAllyChatbotPage()),
                            );
                          },
                        ),
                        _NavBarIcon(
                          icon: Icons.shuffle,
                          label: 'RandRisk',
                          color: Color(0xFFE18616),
                          onTap: () {
                            AudioPlayer().play(
                                AssetSource('sounds/lightning_crack.mp3'));
                            _stopBackgroundMusic();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RandRiskPage()),
                            );
                          },
                        ),
                      ],
                    ),
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

class _NotificationBellWidget extends StatelessWidget {
  final NotificationService notificationService;

  const _NotificationBellWidget({Key? key, required this.notificationService})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) =>
              NotificationsPage(notificationService: notificationService)),
        );
      },
      child: ListenableBuilder(
        listenable: notificationService,
        builder: (context, child) {
          final unreadCount = notificationService.unreadCount;

          return Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF10B981), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFF10B981),
                  size: 28,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StreakIconWidget extends StatelessWidget {
  final BadgeService badgeService;

  const _StreakIconWidget({Key? key, required this.badgeService})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: badgeService,
      builder: (context, child) {
        final badgeColor = Color(badgeService.getColor());

        return GestureDetector(
          onTap: () {
            // Play lightning sound
            AudioPlayer().play(AssetSource('sounds/lightning_crack.mp3'));

            _showBadgeDialog(context, badgeService);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              shape: BoxShape.circle,
              border: Border.all(color: badgeColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: badgeColor.withOpacity(0.3),
                  blurRadius: 14,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.military_tech,
              color: badgeColor,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  void _showBadgeDialog(BuildContext context, BadgeService badgeService) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final badgeColor = Color(badgeService.getColor());

        return _SwipeableBadgeDialog(
            badgeService: badgeService, badgeColor: badgeColor);
      },
    );
  }

  Widget _buildBadgeLevel(String emoji, String name, String range,
      String description, Color color, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color : Colors.white.withOpacity(0.1),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$name: ',
                      style: TextStyle(
                        color: isActive ? color : Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      range,
                      style: TextStyle(
                        color: isActive ? color : Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white.withOpacity(
                        0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Icon(
              Icons.check_circle,
              color: color,
              size: 20,
            ),
        ],
      ),
    );
  }
}

// Swipeable badge dialog implementation
class _SwipeableBadgeDialog extends StatefulWidget {
  final BadgeService badgeService;
  final Color badgeColor;

  const _SwipeableBadgeDialog({
    Key? key,
    required this.badgeService,
    required this.badgeColor,
  }) : super(key: key);

  @override
  State<_SwipeableBadgeDialog> createState() => _SwipeableBadgeDialogState();
}

class _SwipeableBadgeDialogState extends State<_SwipeableBadgeDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildBadgeAchievementPage(BuildContext context) {
    final badgeService = widget.badgeService;
    final badgeColor = widget.badgeColor;

    // Get description color based on badge type
    Color getDescriptionColor() {
      switch (badgeService.currentBadge) {
        case BadgeType.bronze:
          return const Color(0xFFD4A574); // Warm golden (lighter bronze tone)
        case BadgeType.silver:
          return const Color(0xFFD4D4D4); // Light silver
        case BadgeType.gold:
          return const Color(
              0xFFF5C842); // Warm gold (slightly lighter gold tone)
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Badge icon
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [badgeColor, badgeColor.withOpacity(0.7)],
            ),
          ),
          child: Text(
            badgeService.getBadgeEmoji(),
            style: const TextStyle(fontSize: 40),
          ),
        ),
        const SizedBox(height: 20),

        // Heading - larger font
        Text(
          'You earned a ${badgeService.getBadgeName()} ${badgeService
              .getBadgeEmoji()}',
          style: TextStyle(
            color: badgeColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),

        // Highlighted streak count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: badgeColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            '${badgeService.currentStreaks} streaks earned',
            style: TextStyle(
              color: badgeColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 30),

        // Quick summary
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: badgeColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            'Keep scanning, completing quizzes, and learning to level up your badge and streaks!',
            style: TextStyle(
              color: getDescriptionColor(),
              fontWeight: FontWeight.w600,
              fontSize: 18,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 35),

        // Continue button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: badgeColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: const Text(
              'Continue Your Journey',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Add new page for streak breakdown by feature
  Widget _buildStreakBreakdownPage(BuildContext context) {
    final badgeService = widget.badgeService;
    final badgeColor = widget.badgeColor;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Lightning icon and heading
        Icon(Icons.flash_on, color: badgeColor, size: 34),
        const SizedBox(height: 6),
        Text('Streak Breakdown',
          style: TextStyle(
            color: badgeColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 36),
        _buildFeatureStreak(
            'Scan & Protect', badgeService.scanAndProtectStreaks,
            Color(0xFF10B981)),
        const SizedBox(height: 28),
        _buildFeatureStreak(
            'Wise Swipe', badgeService.wiseSwipeStreaks, Color(0xFFF3B11E)),
        const SizedBox(height: 28),
        _buildFeatureStreak(
            'RandRisk', badgeService.randriskStreaks, Color(0xFFE18616)),
        const SizedBox(height: 28),
        _buildFeatureStreak(
            'Ask Ally', badgeService.askAllyStreaks, Color(0xFF127C82)),
        const SizedBox(height: 60),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: badgeColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
            child: const Text(
              'Continue Your Journey',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Small widget helper for streak
  Widget _buildFeatureStreak(String name, int count, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text('$name',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: color,
            ),
          ),
        ),
        Text('${count < 0 ? 0 : count} streaks',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeDetailsPage(BuildContext context) {
    final badgeService = widget.badgeService;
    final badgeColor = widget.badgeColor;

    // Get description color based on badge type
    Color getDescriptionColor() {
      switch (badgeService.currentBadge) {
        case BadgeType.bronze:
          return const Color(0xFFD4A574); // Warm golden (lighter bronze tone)
        case BadgeType.silver:
          return const Color(0xFFD4D4D4); // Light silver
        case BadgeType.gold:
          return const Color(
              0xFFF5C842); // Warm gold (slightly lighter gold tone)
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main content
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: badgeColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    color: getDescriptionColor(),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your Progress Power‑Up!',
                      style: TextStyle(
                        color: getDescriptionColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                'Every time you scan & protect, watch a video, complete a quiz, or spot mistakes, you earn streaks! ⚡',
                style: TextStyle(
                  color: getDescriptionColor(),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              // Stack them up section
              Text(
                'Stack them up to unlock your badge:',
                style: TextStyle(
                  color: getDescriptionColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 14),

              // Badge levels as simple text - no boxes
              _buildSimpleBadgeLevel(
                  '🥇 Gold: 11+ streaks — You\'re a cyber-safety champion! 🌟',
                  const Color(0xFFF3B11E),
                  badgeService.currentBadge == BadgeType.gold
              ),
              const SizedBox(height: 8),
              _buildSimpleBadgeLevel(
                  '🥈 Silver: 6–10 streaks — You\'re on a roll!',
                  const Color(0xFFE8B340),
                  badgeService.currentBadge == BadgeType.silver
              ),
              const SizedBox(height: 8),
              _buildSimpleBadgeLevel(
                  '🥉 Bronze: 0–5 streaks — You\'re getting started!',
                  const Color(0xFFCD7F32),
                  badgeService.currentBadge == BadgeType.bronze
              ),

              const SizedBox(height: 18),
              // Footer message
              const SizedBox(height: 18),
              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: badgeColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Text(
                    'Continue Your Journey',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Removed the extra Continue Your Journey button
      ],
    );
  }

  // New simple badge level widget without boxes
  Widget _buildSimpleBadgeLevel(String text, Color color, bool isActive) {
    // Get description color based on current badge type
    Color getInactiveColor() {
      switch (widget.badgeService.currentBadge) {
        case BadgeType.bronze:
          return const Color(0xFFD4A574); // Warm golden (lighter bronze tone)
        case BadgeType.silver:
          return const Color(0xFFD4D4D4); // Light silver
        case BadgeType.gold:
          return const Color(
              0xFFF5C842); // Warm gold (slightly lighter gold tone)
      }
    }

    // Get contrasting highlight color for active badges
    Color getActiveHighlightColor() {
      switch (widget.badgeService.currentBadge) {
        case BadgeType.bronze:
          return const Color(0xFFCD7F32); // Bronze color
        case BadgeType.silver:
          return const Color(0xFFE8B340); // Silver color  
        case BadgeType.gold:
          return const Color(
              0xFF00D4FF); // Bright cyan - contrasts well with gold text
      }
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? getActiveHighlightColor() : getInactiveColor(),
              fontSize: 15,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              height: 1.3,
            ),
          ),
        ),
        if (isActive)
          Icon(
            Icons.check_circle,
            color: getActiveHighlightColor(),
            size: 18,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: widget.badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: MediaQuery
            .of(context)
            .size
            .width * 0.85,
        child: SizedBox(
          height: 620,
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildBadgeAchievementPage(context),
                    _buildStreakBreakdownPage(context),
                    // newly added page
                    _buildBadgeDetailsPage(context),
                    // previously 2nd, now 3rd page
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    width: _currentPage == i ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? widget.badgeColor
                          : Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavBarIcon({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
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

  _MovingEmoji({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.type,
  });
}

class _SparkleOverlayState extends State<SparkleOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sparkleAnimation;
  final List<String> _emojiList = ['🛡️', '⚡', '💬', '👾', '🧑‍💻', '🏆'];
  late List<_MovingEmoji> _emojis;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
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
    final w =
        WidgetsBinding.instance.window.physicalSize.width /
        WidgetsBinding.instance.window.devicePixelRatio;
    final h =
        WidgetsBinding.instance.window.physicalSize.height /
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
        final w =
            WidgetsBinding.instance.window.physicalSize.width /
            WidgetsBinding.instance.window.devicePixelRatio;
        final h =
            WidgetsBinding.instance.window.physicalSize.height /
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
      animation: Listenable.merge([
        _animationController,
        widget.sparkleController,
      ]),
      builder: (context, child) {
        return Stack(
          children: [
            // Intro-style sparkle particles
            ...List.generate(15, (index) {
              final offset =
                  (_sparkleAnimation.value * 2 * 3.14159 + index * 0.4) %
                  (2 * 3.14159);
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
