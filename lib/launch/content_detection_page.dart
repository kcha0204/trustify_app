import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/badge_service.dart';
import 'scan_image_page.dart';
import 'scan_text_page.dart';

class ContentDetectionPage extends StatefulWidget {
  const ContentDetectionPage({super.key});

  @override
  State<ContentDetectionPage> createState() => _ContentDetectionPageState();
}

class _ContentDetectionPageState extends State<ContentDetectionPage> {
  final BadgeService _badgeService = BadgeService();

  @override
  void initState() {
    super.initState();
    // Show info popup when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInfoPopup();
    });
  }

  void _showInfoPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with shield icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF10B981),
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    '🛡️',
                    style: TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Scan & Protect',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                const Text(
                  'Not sure if a text or image feels shady, mean, or just… off?\nDrop it here and let us do the checking!\nWe\'ll scan it, spot any threats, and give you the heads-up\nso you can stay in control of your space.\nOh, and here\'s the fun part: Every time you complete a scan, you get one Streak!',
                  style: TextStyle(
                    color: Color(0xFF127C82),
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Try Scanning button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      AudioPlayer().play(AssetSource('sounds/tap.wav'));
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Text(
                      'Try Scanning',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlurredBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/aftersplash/after_splash_bg.jpeg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF10B981),
                    Color(0xFFF59E0B),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.7),
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
          _buildBlurredBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header - matching notifications page style
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          AudioPlayer().play(AssetSource('sounds/tap.wav'));
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF10B981),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF10B981),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "SCAN 'n' PROTECT",
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Streak Card (emphasizing streaks)
                        ListenableBuilder(
                          listenable: _badgeService,
                          builder: (context, child) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(_badgeService.getColor())
                                      .withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(_badgeService.getColor())
                                        .withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(_badgeService.getColor())
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Color(_badgeService.getColor()),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _badgeService.getBadgeEmoji(),
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .start,
                                      children: [
                                        Text(
                                          '${_badgeService
                                              .scanAndProtectStreaks} Scan & Protect Streaks',
                                          style: TextStyle(
                                            color: Color(
                                                _badgeService.getColor()),
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_badgeService
                                              .getBadgeName()} Badge',
                                          style: TextStyle(
                                            color: Color(
                                                _badgeService.getColor()),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.trending_up,
                                    color: Color(_badgeService.getColor()),
                                    size: 28,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),

                        // Scan Options - Centered
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Scan Text Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    AudioPlayer().play(
                                        AssetSource('sounds/tap.wav'));

                                    // Removed streak addition - only add streak when actually scanning content
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ScanTextPage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFF176CB8)
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF176CB8)
                                              .withOpacity(0.2),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment
                                          .center,
                                      children: [
                                        Icon(
                                          Icons.text_fields,
                                          color: const Color(0xFF176CB8),
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'SCAN TEXT',
                                          style: TextStyle(
                                            color: const Color(0xFF176CB8),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Scan Image Button
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    AudioPlayer().play(
                                        AssetSource('sounds/tap.wav'));
                                    // NOTE: Streak addition is handled after actual scanning in ScanImagePage.
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ScanImagePage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFF59E0B)
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFF59E0B)
                                              .withOpacity(0.2),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment
                                          .center,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          color: const Color(0xFFF59E0B),
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'SCAN IMAGE',
                                          style: TextStyle(
                                            color: const Color(0xFFF59E0B),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

