// File: lib/launch/content_detection_page.dart
// Purpose: Scan & Protect screen for text and images. Calls Azure Analysis
// Function for moderation, including SAS image upload + polling.
// Key responsibilities:
// - Validate input, trigger text analysis or image selection
// - Image flow: GET SAS → PUT to Blob → poll get_results
// - Render category risk cards and supportive guidance
import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/azure_api.dart';
import 'scenario_knowledge_selection_page.dart';
import 'scenario_category_page.dart';
import 'knowledge_category_page.dart';
import 'dart:convert';

class ContentDetectionPage extends StatefulWidget {
  const ContentDetectionPage({super.key});

  @override
  State<ContentDetectionPage> createState() => _ContentDetectionPageState();
}

class _ContentDetectionPageState extends State<ContentDetectionPage>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final AzureAnalysisApi _api;

  File? _selectedImage;
  dynamic _detectionResult;
  bool _isAnalyzing = false;
  bool _showResults = false;
  bool _resultDialogVisible = false;
  int _xp = 0;
  int _streakToday = 0;
  int _imageUploadToday = 0;
  DateTime? _lastUploadDate;
  Set<int> _todayStreaksRewarded = {};
  Set<int> _xpPopupShown = {};
  late AnimationController _sparkleController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _api = AzureAnalysisApi();
    _sparkleController = AnimationController(
        duration: const Duration(milliseconds: 3200), vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Widget _buildBlurredBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/aftersplash/after_splash_bg.jpeg',
          fit: BoxFit.cover,
        ),
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
                      Colors.black.withOpacity(0.22),
                      Colors.black.withOpacity(0.39),
                      Colors.black.withOpacity(0.63),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Sparkles top-to-bottom
        SparkleOverlayContent(sparkleController: _sparkleController)
      ],
    );
  }

  void _showMilestonePopup(String message, {required bool xpMilestone}) async {
    await _audioPlayer.play(AssetSource('sounds/reward.wav'));
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final Gradient bgGrad = xpMilestone
              ? const LinearGradient(
            colors: [Color(0xFF176CB8), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFF3B11E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          return Center(
            child: Material(
              color: Colors.transparent,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 340),
                scale: 1.11,
                curve: Curves.elasticOut,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                      vertical: 36, horizontal: 30),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF127C82).withOpacity(0.45),
                        blurRadius: 45,
                        spreadRadius: 7,
                      ),
                    ],
                    gradient: bgGrad,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                          Icons.emoji_events, color: Colors.white, size: 50),
                      const SizedBox(height: 18),
                      Text('Wohooo!', style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.91),
                        letterSpacing: 1.3,
                      )),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.white,
                          letterSpacing: 1.07,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (Navigator.of(context, rootNavigator: true).canPop()) Navigator.of(
          context, rootNavigator: true).pop();
    });
  }

  void _checkStreakMilestones() {
    if (_xp > 0 && _xp % 150 == 0 && !_xpPopupShown.contains(_xp)) {
      _xpPopupShown.add(_xp);
      _showMilestonePopup(
          'Awesome! $_xp XP milestone reached!', xpMilestone: true);
    }
  }

  Future<void> _analyzeText() async {
    if (_textController.text
        .trim()
        .isEmpty) return;
    setState(() {
      _isAnalyzing = true;
      _showResults = false;
      _resultDialogVisible = false;
    });
    try {
      final result = await _api.analyzeText(_textController.text);
      _isAnalyzing = false;
      // Risk-level classification logic (works for both text and image)
      final root = result['result'] ?? result;
      final confidenceMap = (root['confidence_scores'] ?? {}) as Map<
          String,
          dynamic>;
      final confidences = confidenceMap.values.whereType<num>().toList();
      bool harmful = confidences.any((v) => v > 0);
      int countOverZero = confidences
          .where((v) => v > 0)
          .length;
      bool anyOverThreshold = confidences.any((v) => v > 0.4);
      String riskLevel;
      String motivation;
      if (!harmful) {
        riskLevel = "SAFE CONTENT";
        motivation =
        "Awesome! You're totally in the clear. Keep being smart online!";
        // Make sure all categories have confidence = 0
        final categories = (root['confidence_scores'] ?? {}) as Map<
            String,
            dynamic>;
        categories.forEach((key, value) {
          categories[key] = 0;
        });
      } else if (countOverZero >= 2 || anyOverThreshold) {
        riskLevel = "MAJOR HARMFUL CONTENT DETECTED";
        motivation =
        "That's a red flag! Remember, never let hate or bullying bring you down – reach out and stand up!";
      } else {
        riskLevel = "HARMFUL CONTENT FOUND";
        motivation =
        "Stay alert! You're not alone – always speak up if something doesn't feel right online.";
      }
      final detSummary = (root['confidence_scores'] ?? {}).entries.map((e) =>
      '\u2022 ${e.key}: ${(e.value is num) ? (e.value * 100).toStringAsFixed(
          1) + '%' : e.value?.toString() ?? 'n/a'}').join("\n");

      setState(() {
        _detectionResult = {
          ...result,
          'composedSummary': detSummary,
          'motivation': motivation,
          'riskLevel': riskLevel,
        };
        _xp += 50;
      });

      // Place here, after riskLevel assignment
      if (riskLevel == 'SAFE CONTENT') {
        _audioPlayer.play(AssetSource('sounds/win.wav'));
      } else if (riskLevel == 'HARMFUL CONTENT FOUND' ||
          riskLevel == 'MAJOR HARMFUL CONTENT DETECTED') {
        _audioPlayer.play(AssetSource('sounds/loose.wav'));
      }

      bool needXpPopup = _xp > 0 && _xp % 150 == 0 &&
          !_xpPopupShown.contains(_xp);

      void showResultDialogAfterPopup() {
        setState(() {
          _showResults = true;
          _resultDialogVisible = true;
        });
      }

      if (needXpPopup) {
        _xpPopupShown.add(_xp);
        _showMilestonePopup(
            'Awesome! $_xp XP milestone reached!', xpMilestone: true);
        Future.delayed(
            const Duration(milliseconds: 1000), showResultDialogAfterPopup);
        return;
      } else {
        showResultDialogAfterPopup();
        return;
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _showResults = false;
        _detectionResult = null;
        _streakToday = 0;
        _resultDialogVisible = true;
        _errorMessage = 'Failed to analyze text: ${e.toString()}';
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    setState(() {
      _isAnalyzing = true;
      _showResults = false;
      _resultDialogVisible = false;
    });
    try {
      final result = await _api.analyzeImage(_selectedImage!);
      _isAnalyzing = false;
      // Risk-level classification logic (works for both text and image)
      final isImage = result != null && result['result'] != null;
      final root = isImage ? result['result'] as Map<String, dynamic> : result;
      final confidenceMap = (root['confidence_scores'] ?? {}) as Map<
          String,
          dynamic>;
      final confidences = confidenceMap.values.whereType<num>().toList();
      bool harmful = root['is_harmful'] == true || root['is_harmful'] == 'True';
      int nonzeroCount = confidences
          .where((v) => v > 0)
          .length;
      bool anyOverThreshold = confidences.any((v) => v > 0.4);
      String riskLevel;
      String motivation;
      if (!harmful) {
        riskLevel = 'SAFE CONTENT';
        motivation =
        "Awesome! You're totally in the clear. Keep being smart online!";
      } else if (nonzeroCount >= 2 || anyOverThreshold) {
        riskLevel = 'MAJOR HARMFUL CONTENT DETECTED';
        motivation =
        "That's a red flag! Remember, never let hate or bullying bring you down – reach out and stand up!";
      } else if (nonzeroCount == 1) {
        riskLevel = 'HARMFUL CONTENT FOUND';
        motivation =
        "Stay alert! You're not alone – always speak up if something doesn't feel right online.";
      } else {
        riskLevel = result == null ? 'UNKNOWN' : 'SAFE CONTENT';
        motivation =
        "Stay alert! You're not alone – always speak up if something doesn't feel right online.";
      }
      final detSummary = (root['confidence_scores'] ?? {}).entries.map((e) =>
      '\u2022 ${e.key}: ${(e.value is num) ? (e.value * 100).toStringAsFixed(
          1) + '%' : e.value?.toString() ?? 'n/a'}').join("\n");

      setState(() {
        _detectionResult = {
          ...result,
          'composedSummary': detSummary,
          'motivation': motivation,
          'riskLevel': riskLevel,
        };
        _xp += 50;
        _streakToday++;
        _imageUploadToday++;
      });

      // Place here, after riskLevel assignment
      if (riskLevel == 'SAFE CONTENT') {
        _audioPlayer.play(AssetSource('sounds/win.wav'));
      } else if (riskLevel == 'HARMFUL CONTENT FOUND' ||
          riskLevel == 'MAJOR HARMFUL CONTENT DETECTED') {
        _audioPlayer.play(AssetSource('sounds/loose.wav'));
      }

      bool needXpPopup = _xp > 0 && _xp % 150 == 0 &&
          !_xpPopupShown.contains(_xp);
      bool needStreakPopup = _imageUploadToday > 0 &&
          _imageUploadToday % 2 == 0 &&
          !_todayStreaksRewarded.contains(_imageUploadToday);

      void showResultDialogAfterRewardImg() {
        setState(() {
          _showResults = true;
          _resultDialogVisible = true;
        });
      }

      if (needXpPopup) {
        _xpPopupShown.add(_xp);
        _showMilestonePopup(
            'Awesome! $_xp XP milestone reached!', xpMilestone: true);
        Future.delayed(
            const Duration(milliseconds: 1000), showResultDialogAfterRewardImg);
      } else if (needStreakPopup) {
        _todayStreaksRewarded.add(_imageUploadToday);
        _showMilestonePopup(
            'You got $_imageUploadToday streaks today!\nWay to go champ!',
            xpMilestone: false);
        Future.delayed(
            const Duration(milliseconds: 1000), showResultDialogAfterRewardImg);
      } else {
        showResultDialogAfterRewardImg();
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _showResults = false;
        _detectionResult = null;
        _streakToday = 0;
        _resultDialogVisible = true;
        _errorMessage = 'Failed to analyze image: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back button + BANNER
        Padding(
          padding: const EdgeInsets.only(
              left: 5, bottom: 16, top: 34, right: 18),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                    Icons.arrow_back_ios_new_rounded, color: Color(0xFF127C82),
                    size: 27),
                splashRadius: 26,
                onPressed: () {
                  _audioPlayer.play(AssetSource('sounds/tap.wav'));
                  Navigator.of(context).pop();
                },
                tooltip: 'Back',
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 1, minHeight: 1),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 2, vertical: 0),
                  padding: const EdgeInsets.symmetric(
                      vertical: 17, horizontal: 11),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.92),
                    border: Border.all(
                      color: Color(0xFF10B981),
                      width: 2.2,
                    ),
                    borderRadius: BorderRadius.circular(19),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF10B981).withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 2.3,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "BULLYING? NOT TODAY",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                          color: Color(0xFF10B981),
                          letterSpacing: 0.7,
                          shadows: [
                            Shadow(
                              color: Color(0xFF10B981).withOpacity(0.77),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      ShaderMask(
                        shaderCallback: (Rect bounds) =>
                            LinearGradient(
                              colors: [Color(0xFF176CB8), Color(0xFF176CB8)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                        child: Text(
                          "Scan it, Spot it, Block it, Chill Out!",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            color: Colors.white,
                            letterSpacing: 0.7,
                            shadows: [
                              Shadow(color: Color(0xFF176CB8).withOpacity(0.85),
                                  blurRadius: 18),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
        // XP/STREAK BOX WITH GLOW
        Container(
          margin: const EdgeInsets.only(top: 13, bottom: 10, left: 2, right: 2),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 11),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.92),
            border: Border.all(
              color: Color(0xFF176CB8),
              width: 2.4,
            ),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF176CB8).withOpacity(0.5),
                blurRadius: 33,
                spreadRadius: 4.1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'XP: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                  color: Color(0xFF176CB8),
                  letterSpacing: 0.7,
                  shadows: [
                    Shadow(
                      color: Color(0xFF176CB8).withOpacity(0.65),
                      blurRadius: 15,
                    ),
                  ],
                ),
              ),
              Text(
                '$_xp',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: Color(0xFF176CB8),
                  letterSpacing: 0.8,
                  shadows: [
                    Shadow(
                      color: Color(0xFF176CB8).withOpacity(0.75),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              Text(
                'Streak: ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                  color: Color(0xFF10B981),
                  letterSpacing: 0.7,
                  shadows: [
                    Shadow(
                      color: Color(0xFF10B981).withOpacity(0.65),
                      blurRadius: 15,
                    ),
                  ],
                ),
              ),
              Text(
                '$_streakToday',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  color: Color(0xFF10B981),
                  letterSpacing: 0.8,
                  shadows: [
                    Shadow(
                      color: Color(0xFF10B981).withOpacity(0.69),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInputRow(context),
                  const SizedBox(height: 10),
                  if (_isAnalyzing)
                    Padding(
                      padding: const EdgeInsets.only(top: 22),
                      child: _buildScanBar(),
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (_showResults && _resultDialogVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_showResults && _resultDialogVisible) _showResultPopup(context);
      });
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(preferredSize: Size.zero, child: Container()),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBlurredBackground(),
          SafeArea(child: content)
        ],
      ),
    );
  }

  // Text scan button with refresh
  Widget _buildTextScanButton() {
    bool canAnalyzeText = _textController.text
        .trim()
        .isNotEmpty && !_isAnalyzing;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                  canAnalyzeText ? const Color(0xFF10B981) : Colors.grey[700]),
              padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 18)),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: canAnalyzeText ? const Color(0xFF10B981) : Colors
                      .transparent,
                  width: 2,
                ),
              )),
            ),
            onPressed: canAnalyzeText
                ? () {
              _audioPlayer.play(AssetSource('sounds/tap.wav'));
              _analyzeText();
            }
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isAnalyzing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                if (_isAnalyzing) const SizedBox(width: 12),
                Icon(_isAnalyzing ? Icons.security : Icons.shield,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  _isAnalyzing ? 'SCANNING TEXT...' : 'SCAN TEXT ⚡',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: !_isAnalyzing ? _clearText : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFFF3B11E)],
              ),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.refresh, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  // Image scan button with refresh
  Widget _buildImageScanButton() {
    bool canAnalyzeImage = _selectedImage != null && !_isAnalyzing;
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(
                  !canAnalyzeImage || _isAnalyzing ? Colors.grey[700] : Color(
                      0xFF176CB8)),
              padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 18)),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: !canAnalyzeImage || _isAnalyzing
                      ? Colors.transparent
                      : Color(0xFF176CB8),
                  width: 2,
                ),
              )),
            ),
            onPressed: (!canAnalyzeImage || _isAnalyzing)
                ? null
                : () {
              _audioPlayer.play(AssetSource('sounds/tap.wav'));
              _analyzeImage();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isAnalyzing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                if (_isAnalyzing) const SizedBox(width: 12),
                Icon(_isAnalyzing ? Icons.security : Icons.shield,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  _isAnalyzing ? 'SCANNING IMAGE...' : 'SCAN IMAGE ⚡',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: !_isAnalyzing ? _clearImage : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                colors: [Color(0xFF176CB8), Color(0xFFF3B11E)],
              ),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.refresh, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildInputRow(BuildContext context) {
    return Column(
      children: [
        // Text Input Section
        _buildInputCard(),
        const SizedBox(height: 12),
        _buildTextScanButton(),

        const SizedBox(height: 24),

        // Image Input Section  
        _buildUploadCard(),
        const SizedBox(height: 12),
        _buildImageScanButton(),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? child,
    required Color colorA,
    required Color colorB,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.82),
            Colors.black.withOpacity(0.6),
          ],
        ),
        border: Border.all(width: 3, color: colorA.withOpacity(0.8)),
        boxShadow: [
          BoxShadow(
            color: colorA.withOpacity(0.33),
            blurRadius: 20,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: colorB.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 7,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [colorA, colorB]),
              boxShadow: [
                BoxShadow(
                  color: colorA.withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Icon(icon, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (bounds) =>
                LinearGradient(colors: [colorA, colorB]).createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorA.withOpacity(0.9),
              letterSpacing: 0.7,
            ),
          ),
          if (child != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return _buildInfoCard(
      icon: Icons.chat_bubble_outline,
      title: '💬 PASTE TEXT',
      subtitle: 'Scan messages, comments, or posts',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white12),
        ),
        child: TextField(
          controller: _textController,
          maxLines: 4,
          onChanged: (value) {
            setState(() {
              // Auto-clear results when user starts typing to avoid confusion
              if (_showResults && value.isNotEmpty &&
                  _detectionResult != null) {
                _detectionResult = null;
                _showResults = false;
                _resultDialogVisible = false;
              }
            });
          },
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Paste suspicious text here...\nExample: "You\'re so stupid" or "I hate you"',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
            contentPadding: EdgeInsets.all(16),
          ),
        ),
      ),
      colorA: const Color(0xFF10B981),
      colorB: const Color(0xFFF3B11E),
    );
  }

  Widget _buildUploadCard() {
    return _buildInfoCard(
      icon: Icons.image_outlined,
      title: '📸 UPLOAD IMAGE',
      subtitle: 'Analyze screenshots and photos',
      child: GestureDetector(
        onTap: _selectImageSource,
        child: Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: _selectedImage != null
                  ? const Color(0xFF10B981).withOpacity(0.8)
                  : Colors.white12,
              width: 2,
            ),
          ),
          child: _selectedImage == null
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add_photo_alternate_outlined,
                  size: 40, color: Colors.white60),
              SizedBox(height: 8),
              Text('TAP TO UPLOAD',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  )),
              Text('Camera or Gallery',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          )
              : Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      colorA: const Color(0xFF176CB8),
      colorB: const Color(0xFFF3B11E), // blue + yellow for upload image
    );
  }

  Widget _buildScanBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              '🔍 AI ANALYZING...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showResultPopup(BuildContext context) async {
    // Only show one dialog at a time
    if (!_resultDialogVisible || !_showResults) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final result = _detectionResult;
        final isError = result == null;
        final isImage = result != null && result['result'] != null;
        final root = isImage ? result['result'] : result;
        final confidenceMap = (root['confidence_scores'] ?? {}) as Map<
            String,
            dynamic>;
        final confidences = confidenceMap.values.whereType<num>().toList();
        bool harmful = root['is_harmful'] == true ||
            root['is_harmful'] == 'True';
        int nonzeroCount = confidences
            .where((v) => v > 0)
            .length;
        bool anyOverThreshold = confidences.any((v) => v > 0.4);
        String riskLevel;
        if (!harmful) {
          riskLevel = 'SAFE CONTENT';
        } else if (nonzeroCount >= 2 || anyOverThreshold) {
          riskLevel = 'MAJOR HARMFUL CONTENT DETECTED';
        } else if (nonzeroCount == 1) {
          riskLevel = 'HARMFUL CONTENT FOUND';
        } else {
          riskLevel = result == null ? 'UNKNOWN' : 'SAFE CONTENT';
        }
        // Motivational quote (by riskLevel)
        String motivation = '';
        switch (riskLevel) {
          case 'MAJOR HARMFUL CONTENT DETECTED':
            motivation =
            "That's a red flag! Remember, never let hate or bullying bring you down – reach out and stand up!";
            break;
          case 'HARMFUL CONTENT FOUND':
            motivation =
            "Stay alert! You're not alone – always speak up if something doesn't feel right online.";
            break;
          case 'SAFE CONTENT':
            motivation =
            "Awesome! You're totally in the clear. Keep being smart online!";
            break;
        }
        bool soundPlayed = false;
        if (!soundPlayed) {
          if (riskLevel == 'SAFE CONTENT') {
            _audioPlayer.play(AssetSource('sounds/win.wav'));
          } else if (riskLevel == 'HARMFUL CONTENT FOUND' ||
              riskLevel == 'MAJOR HARMFUL CONTENT DETECTED') {
            _audioPlayer.play(AssetSource('sounds/loose.wav'));
          }
          soundPlayed = true;
        }
        final List<String> detectedCats = confidenceMap.entries.where((e) =>
        (e.value is num) ? e.value > 0 : false).map((e) => e.key).toList();
        final Widget categoriesWidget = detectedCats.isNotEmpty
            ? Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Text(
            'Detected Categories: ${detectedCats.join(', ')}',
            style: TextStyle(
                fontSize: 14, color: Colors.white, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        )
            : const SizedBox.shrink();
        Color riskColor;
        switch (riskLevel) {
          case "MAJOR HARMFUL CONTENT DETECTED":
            riskColor = Colors.red.shade700;
            break;
          case "HARMFUL CONTENT FOUND":
            riskColor = Colors.orange.shade700;
            break;
          case "SAFE CONTENT":
            riskColor = Color(0xFF00FF57); // Vibrant green neon
            break;
          default:
            riskColor = Colors.grey;
        }
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 25),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: riskColor,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: riskColor.withOpacity(0.23),
                        blurRadius: 30,
                        spreadRadius: 7,
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery
                        .of(context)
                        .size
                        .height * 0.85,
                    minWidth: 0,
                    maxWidth: 430,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        vertical: 22, horizontal: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                colors: [riskColor, riskColor]),
                            boxShadow: [
                              BoxShadow(
                                color: riskColor.withOpacity(0.62),
                                blurRadius: 22,
                                spreadRadius: 1.5,
                              )
                            ],
                          ),
                          child: Icon(
                            riskLevel == "MAJOR HARMFUL CONTENT DETECTED"
                                ? Icons.error
                                : riskLevel == "HARMFUL CONTENT FOUND"
                                ? Icons.warning
                                : Icons.check_circle,
                            color: Colors.white, size: 38,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          riskLevel.toUpperCase(),
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20.5,
                            letterSpacing: 1.1,
                            shadows: [
                              Shadow(blurRadius: 10,
                                  color: riskColor.withOpacity(0.45)),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          motivation,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16.7,
                            letterSpacing: 0.2,
                            shadows: [
                              Shadow(
                                  blurRadius: 4, color: Colors.black45)
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        categoriesWidget,
                        if (categoriesWidget !=
                            const SizedBox.shrink()) const SizedBox(
                            height: 7),
                        Text(
                          "Want to learn more about cyberbullying or strengthen your skills? Try a quiz now:",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.5,
                            fontWeight: FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: () {
                            _audioPlayer.play(AssetSource('sounds/tap.wav'));
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      KnowledgeCategoryPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            side: BorderSide(
                                color: Color(0xFF2196F3), width: 2),
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    17)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    LinearGradient(
                                        colors: [
                                          Color(0xFF2196F3),
                                          Color(0xFF2196F3)
                                        ])
                                        .createShader(bounds),
                                child: Text(
                                  'Knowledge-Based Quizzes ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(blurRadius: 13,
                                          color: Color(0xFF2196F3)),
                                    ],
                                  ),
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    LinearGradient(
                                        colors: [
                                          Color(0xFF2196F3),
                                          Color(0xFF2196F3)
                                        ])
                                        .createShader(bounds),
                                child: const Text('⚡', style: TextStyle(
                                    fontSize: 20, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            _audioPlayer.play(AssetSource('sounds/tap.wav'));
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      ScenarioCategoryPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            side: BorderSide(
                                color: Color(0xFF10B981), width: 2),
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    17)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF10B981)
                                        ])
                                        .createShader(bounds),
                                child: Text(
                                  'Scenario-Based Quizzes ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(blurRadius: 13,
                                          color: Color(0xFF10B981)),
                                    ],
                                  ),
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF10B981)
                                        ])
                                        .createShader(bounds),
                                child: const Text('⚡', style: TextStyle(
                                    fontSize: 20, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(
                          Icons.close_rounded, color: Colors.redAccent,
                          size: 29),
                      splashRadius: 22,
                      onPressed: () {
                        _audioPlayer.play(AssetSource('sounds/tap.wav'));
                        setState(() {
                          _showResults = false;
                          _resultDialogVisible = false;
                        });
                        Navigator
                            .of(ctx, rootNavigator: true)
                            .pop(); // ensures root modal is closed instantly
                      },
                      tooltip: 'Close',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
    Future.delayed(const Duration(seconds: 5), () {
      if (_resultDialogVisible && _showResults &&
          Navigator.of(context, rootNavigator: true).canPop()) {
        setState(() {
          _showResults = false;
          _resultDialogVisible = false;
        });
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  Future<void> _selectImageSource() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '📸 Choose Source',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    onTap: () => _selectImage(ImageSource.camera),
                    colors: [const Color(0xFF10B981), const Color(0xFFF3B11E)],
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _selectImage(ImageSource.gallery),
                    colors: [const Color(0xFF10B981), const Color(0xFFF3B11E)],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required List<Color> colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(colors: colors),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    Navigator.pop(context); // Close the bottom sheet
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          // Auto-clear results when image is uploaded to avoid confusion
          if (_showResults && _detectionResult != null) {
            _detectionResult = null;
            _showResults = false;
            _resultDialogVisible = false;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select image: $e')),
      );
    }
  }

  void _clearAll() {
    setState(() {
      _textController.clear();
      _selectedImage = null;
      _detectionResult = null;
      _showResults = false;
      _resultDialogVisible = false;
    });
  }

  void _clearText() {
    setState(() {
      _textController.clear();
      if (_detectionResult != null) {
        _detectionResult = null;
        _showResults = false;
        _resultDialogVisible = false;
      }
    });
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      if (_detectionResult != null) {
        _detectionResult = null;
        _showResults = false;
        _resultDialogVisible = false;
      }
    });
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }
}

class SparkleOverlayContent extends StatelessWidget {
  final AnimationController sparkleController;

  const SparkleOverlayContent({Key? key, required this.sparkleController})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sparkleAnimation = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: sparkleController, curve: Curves.linear));
    return AnimatedBuilder(
      animation: sparkleAnimation,
      builder: (context, _) {
        return Stack(
          children: List.generate(15, (index) {
            final offset = (sparkleAnimation.value * 2 * 3.14159 +
                index * 0.4) % (2 * 3.14159);
            // Sparkles flow top to bottom
            final screenH = MediaQuery
                .of(context)
                .size
                .height;
            return Positioned(
              left: 50 + (index % 5) * 70.0 + 20 * sin(offset),
              top: ((sparkleAnimation.value + index * 0.07) % 1.0) *
                  (screenH - 40) + 15,
              child: Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                  color: [
                    const Color(0xFF176CB8), // electric blue
                    const Color(0xFF127C82), // teal
                    const Color(0xFFF3B11E), // yellow
                    const Color(0xFFE18616), // orange
                  ][index % 4].withOpacity(0.67 + 0.18 * sin(offset)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}