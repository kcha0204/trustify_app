import 'dart:ui';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_detection_service.dart';

const String kAnalyzerBaseUrl = 'https://oqjeucsmquvsitfqjsry.supabase.co/functions/v1';

class ContentDetectionPage extends StatefulWidget {
  const ContentDetectionPage({super.key});

  @override
  State<ContentDetectionPage> createState() => _ContentDetectionPageState();
}

class _ContentDetectionPageState extends State<ContentDetectionPage>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  late final AiDetectionService _aiService;

  File? _selectedImage;
  AiDetectionResult? _detectionResult;
  bool _isAnalyzing = false;
  bool _showResults = false;
  int _xp = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _aiService = AiDetectionService(kAnalyzerBaseUrl);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Home-style blur background
  Widget _buildBlurredBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/splash/cyberbullying_social_bg.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
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
            border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF88).withOpacity(0.3),
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
                    colors: [const Color(0xFF00FF88), const Color(0xFF00D4FF)],
                  ),
                  _buildSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    onTap: () => _selectImage(ImageSource.gallery),
                    colors: [const Color(0xFFFF3366), const Color(0xFF9D4EDD)],
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
          _xp += 10; // Small XP for uploading
          // Auto-clear results when image is uploaded to avoid confusion
          if (_showResults && _detectionResult != null) {
            _detectionResult = null;
            _showResults = false;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select image: $e')),
      );
    }
  }

  Future<void> _analyzeText() async {
    if (_textController.text
        .trim()
        .isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _showResults = false;
    });

    try {
      final result = await _aiService.analyzeText(_textController.text);

      setState(() {
        _isAnalyzing = false;
        _showResults = true;
        _detectionResult = result;
        _xp += 50;

        // Adjust streak based on result
        if (result.riskLevel == "Very Harmful") {
          _streak = 0; // Reset streak on high risk
        } else {
          _streak += 1;
        }
      });
      _autoHideResults();
    } catch (e) {
      print('[AI Text Detection] Error: ' + e.toString());
      setState(() {
        _isAnalyzing = false;
        _showResults = true;
        _detectionResult = null;
        _streak = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text analysis error: ${e.toString()}'),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
      _autoHideResults();
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _showResults = false;
    });

    try {
      final result = await _aiService.analyzeScreenshot(_selectedImage!);

      setState(() {
        _isAnalyzing = false;
        _showResults = true;
        _detectionResult = result;
        _xp += 50;

        // Adjust streak based on result
        if (result.riskLevel == "Very Harmful") {
          _streak = 0; // Reset streak on high risk
        } else {
          _streak += 1;
        }
      });
      _autoHideResults();
    } catch (e) {
      print('[AI Image Detection] Error: ' + e.toString());
      setState(() {
        _isAnalyzing = false;
        _showResults = true;
        _detectionResult = null;
        _streak = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image analysis error: ${e.toString()}'),
          backgroundColor: Colors.red.withOpacity(0.8),
        ),
      );
      _autoHideResults();
    }
  }

  Future<void> _analyzeContent() async {
    // This method is now unused - keeping for compatibility
    // Individual analyze methods are used instead
  }

  void _clearAll() {
    setState(() {
      _textController.clear();
      _selectedImage = null;
      _detectionResult = null;
      _showResults = false;
    });
  }

  void _clearText() {
    setState(() {
      _textController.clear();
      if (_detectionResult != null) {
        _detectionResult = null;
        _showResults = false;
      }
    });
  }

  void _clearImage() {
    setState(() {
      _selectedImage = null;
      if (_detectionResult != null) {
        _detectionResult = null;
        _showResults = false;
      }
    });
  }

  void _autoHideResults() {
    Timer(const Duration(seconds: 15), () {
      if (_showResults && mounted) {
        setState(() {
          _showResults = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: Size.zero,
        child: Container(),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBlurredBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: 8, right: 8, top: 10, bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(
                            Icons.arrow_back, color: Colors.white, size: 28),
                        splashRadius: 28,
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Back to Home',
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 6, right: 0),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFF00FF88),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FF88).withOpacity(0.3),
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                              BoxShadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 14,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) =>
                                const LinearGradient(
                                  colors: [
                                    Color(0xFF00FF88),
                                    Color(0xFF00D4FF),
                                    Color(0xFFFF3366),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds),
                            child: const Text(
                              'AI CONTENT SHIELD',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                      blurRadius: 10,
                                      color: Colors.black54,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),
                          // Paste Text and Upload Image Cards
                          _buildInputRow(context),
                          const SizedBox(height: 20),
                          _buildXPBar(),
                          if (_isAnalyzing)
                            Padding(
                              padding: const EdgeInsets.only(top: 22),
                              child: _buildScanBar(),
                            ),
                          if (_showResults)
                            Padding(
                              padding: const EdgeInsets.only(top: 22),
                              child: _buildResultCard(),
                            ),
                          const SizedBox(height: 60),
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
                  canAnalyzeText ? Colors.green : Colors.grey[700]),
              padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 18)),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: canAnalyzeText ? const Color(0xFF00FF88) : Colors
                      .transparent,
                  width: 2,
                ),
              )),
            ),
            onPressed: canAnalyzeText ? _analyzeText : null,
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
                colors: [Color(0xFF00FF88), Color(0xFF00D4FF)],
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
                  canAnalyzeImage ? Colors.green : Colors.grey[700]),
              padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 18)),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: canAnalyzeImage ? const Color(0xFFFF3366) : Colors
                      .transparent,
                  width: 2,
                ),
              )),
            ),
            onPressed: canAnalyzeImage ? _analyzeImage : null,
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
                colors: [Color(0xFFFF3366), Color(0xFF9D4EDD)],
              ),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.refresh, color: Colors.white, size: 18),
          ),
        ),
      ],
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
      colorA: const Color(0xFF00D4FF),
      colorB: const Color(0xFF0099CC),
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
                  ? const Color(0xFF00FF88).withOpacity(0.8)
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
                    color: const Color(0xFF00FF88),
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
      colorA: const Color(0xFFFF3366),
      colorB: const Color(0xFF9D4EDD),
    );
  }

  Widget _buildScanBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF00FF88).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withOpacity(0.3),
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
              color: Color(0xFF00FF88),
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

  Widget _buildResultCard() {
    final result = _detectionResult;
    final isError = result == null;
    List<Color> resultColors;
    String emoji;
    String title;
    String subtitle;
    String friendlyMessage = '';

    if (isError) {
      resultColors = [const Color(0xFFFFDD00), const Color(0xFF06FFA5)];
      emoji = '⚠️';
      title = 'ANALYSIS FAILED';
      subtitle = 'Connection error - try again';
      friendlyMessage = '';
    } else {
      // Use new model's user-friendly message for the headline
      friendlyMessage = result.message;
      // Color and icon based on the risk level
      if (result.riskLevel == 'Very Harmful') {
        resultColors = [Colors.red.shade700, Colors.red.shade900];
        emoji = '🛑';
        title = 'MAJOR HARMFUL CONTENT';
        subtitle = result.composedSummary;
      } else if (result.riskLevel == 'Harmful') {
        resultColors = [Colors.orange.shade700, Colors.orange.shade900];
        emoji = '⚠️';
        title = 'HARMFUL CONTENT FOUND';
        subtitle = result.composedSummary;
      } else if (result.riskLevel == 'Warning') {
        resultColors = [Colors.yellow.shade700, Colors.orange.shade400];
        emoji = '🟡';
        title = 'MILD RISK';
        subtitle = result.composedSummary;
      } else {
        resultColors = [Colors.green.shade400, Colors.green.shade700];
        emoji = '✅';
        title = 'SAFE CONTENT';
        subtitle = result.composedSummary;
      }
    }
    return _buildInfoCard(
      icon: isError ? Icons.error_outline : Icons.shield_rounded,
      title: '$emoji $title',
      subtitle: friendlyMessage,
      // put teen message as headline
      child: isError ? null :
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          subtitle.isNotEmpty ? subtitle : '',
          style: TextStyle(
            color: resultColors[0],
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      colorA: resultColors[0],
      colorB: resultColors[1],
    );
  }

  Widget _buildXPBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.6),
                ],
              ),
              border: Border.all(
                  color: const Color(0xFF00FF88).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                    Icons.emoji_events, color: Color(0xFF00FF88), size: 18),
                const SizedBox(width: 6),
                Text(
                  'XP: $_xp',
                  style: const TextStyle(
                    color: Color(0xFF00FF88),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.local_fire_department, size: 18,
                    color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  'Streak: $_streak',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
}