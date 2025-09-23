// File: lib/launch/sexual_scenario_quiz_page.dart
// Purpose: Scenario quiz screen for Sexual content category.
// Notes: Role‑play choices with supportive corrective feedback.
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'ask_ally_chatbot_page.dart'; // new import

const Map<String, Color> optionColors = {
  'Report': Color(0xFFFF6B6B), // bright red
  'Ignore': Color(0xFF176CB8), // strong blue
  'Support': Color(0xFF10B89E), // teal
  'Encourage': Color(0xFFAB1FF5), // modern violet
};

class SexualScenarioQuizPage extends StatefulWidget {
  const SexualScenarioQuizPage({Key? key}) : super(key: key);

  @override
  State<SexualScenarioQuizPage> createState() => _SexualScenarioQuizPageState();
}

class _SexualScenarioQuizPageState extends State<SexualScenarioQuizPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _popupVisible = false;
  String _popupType = ""; // "correct" or "incorrect"
  String _popupReason = "";
  String _correctAnswer = "";
  bool _showCorrectFromIncorrect = false; // for incorrect->show correct
  Timer? _popupTimer;
  final AudioPlayer _quizAudioPlayer = AudioPlayer();
  bool _allCorrect = true;

  // All scenarios for "Sexual Abuse" category
  final List<Map<String, dynamic>> _scenarios = [
    {
      "prompt":
      "In a class group chat, someone shares a sexual joke meme. A few classmates laugh quietly, while most scroll past. One student notices a friend staring at the screen silently.",
      "options": ["Ignore", "Encourage", "Support", "Report"],
      "correct": "Support",
      "reason":
      "Supporting the friend addresses their discomfort directly without escalating."
    },
    {
      "prompt":
      "Priya receives a message from an unknown user offering “quick money” in exchange for meeting up. She doesn’t respond immediately, unsure what to do.",
      "options": ["Ignore", "Encourage", "Support", "Report"],
      "correct": "Report",
      "reason":
      "Reporting ensures safe intervention from authorities or the platform."
    },
    {
      "prompt":
      "Ella sees a pornographic link shared in a group chat. Some classmates are curious and click the link, others scroll past. Ella is uncertain if she should intervene.",
      "options": ["Ignore", "Encourage", "Support", "Report"],
      "correct": "Ignore",
      "reason": "Ignoring avoids escalating minor exposure among peers."
    },
    {
      "prompt":
      "During an online call, a student hears sexual comments directed at a peer. The peer stops talking for a while, and others continue with the activity quietly.",
      "options": ["Ignore", "Encourage", "Support", "Report"],
      "correct": "Support",
      "reason":
      "Offering support helps the peer feel safe without creating immediate conflict."
    },
    {
      "prompt":
      "Leo receives a suspicious message from an older stranger asking for inappropriate images. He feels unsure and considers what action to take.",
      "options": ["Ignore", "Encourage", "Support", "Report"],
      "correct": "Report",
      "reason":
      "Reporting is essential to prevent exploitation and involve trusted authorities."
    },
    {
      "prompt":
      "A stranger in a gaming chat asks Mia personal questions repeatedly, including her location and school. Some peers notice but do not respond.",
      "options": ["Ignore", "Encourage", "Support", "Report"],
      "correct": "Support",
      "reason":
      "Comforting or advising Mia helps her handle the situation safely while she decides next steps."
    },
  ];

  @override
  void dispose() {
    _popupTimer?.cancel();
    _pageController.dispose();
    _quizAudioPlayer.dispose();
    super.dispose();
  }

  void _showPopup(bool correct, String reason, String correctAnswer) {
    setState(() {
      _popupVisible = true;
      _popupType = correct ? "correct" : "incorrect";
      _popupReason = reason;
      _showCorrectFromIncorrect = false;
      _correctAnswer = correctAnswer;
    });
    _popupTimer?.cancel();
    _popupTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _popupVisible = false;
      });
    });
  }

  void _showCorrectPopupFromIncorrect(String reason, String correctAnswer) {
    setState(() {
      _popupVisible = true;
      _popupType = "correct";
      _popupReason = reason;
      _showCorrectFromIncorrect = true;
      _correctAnswer = correctAnswer;
    });
    _popupTimer?.cancel();
    _popupTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _popupVisible = false;
      });
    });
  }

  void _onSelectOption(String option, int q) {
    _quizAudioPlayer.play(AssetSource('sounds/tap.wav'));
    final scenario = _scenarios[q];
    final isCorrect = option == scenario["correct"];
    if (!isCorrect) _allCorrect = false;
    _showPopup(isCorrect, scenario["reason"], scenario["correct"]);
    if (q == _scenarios.length - 1 && _allCorrect) {
      Future.delayed(const Duration(milliseconds: 350), () async {
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) {
              _quizAudioPlayer.play(AssetSource('sounds/reward.wav'));
              Future.delayed(const Duration(milliseconds: 1000), () {
                if (Navigator.of(ctx, rootNavigator: true).canPop()) Navigator
                    .of(ctx, rootNavigator: true).pop();
              });
              return Center(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 30, horizontal: 34),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Wohooo! You nailed the streak! ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 19,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }
        );
      });
    }
  }

  void _onClosePopup() {
    _quizAudioPlayer.play(AssetSource('sounds/tap.wav'));
    setState(() {
      _popupVisible = false;
    });
  }

  void _onCheckCorrect(int q) {
    _quizAudioPlayer.play(AssetSource('sounds/tap.wav'));
    final scenario = _scenarios[q];
    _showCorrectPopupFromIncorrect(
        scenario["reason"], scenario["correct"]);
  }

  Widget _buildPopup(int q) {
    final isCorrect = _popupType == "correct";
    final correctAns = _scenarios[q]["correct"];
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
          decoration: BoxDecoration(
            color: isCorrect ? Colors.green[700] : Colors.red[700],
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.23),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          constraints: const BoxConstraints(minWidth: 290, maxWidth: 350),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCorrect || _showCorrectFromIncorrect) ...[
                    const Icon(
                        Icons.check_circle, color: Colors.white, size: 40),
                    const SizedBox(height: 6),
                    const Text(
                      "Correct!",
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Answer: $correctAns',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _popupReason,
                      style: const TextStyle(fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ] else
                    ...[
                      const Icon(Icons.error, color: Colors.white, size: 40),
                      const SizedBox(height: 6),
                      const Text(
                        "Incorrect answer",
                        style: TextStyle(fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 17),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFFFF6B6B),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            _quizAudioPlayer.play(
                                AssetSource('sounds/tap.wav'));
                            _onCheckCorrect(q);
                          },
                          child: const Text(
                            "Check correct answer",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF176CB8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true).pop();
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (
                                    _) => const AskAllyChatbotPage()));
                          },
                          child: const Text(
                            "Click here to know more",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: _onClosePopup,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScenarioPage(int q) {
    final scenario = _scenarios[q];
    // Upper row
    final option0 = scenario["options"][0];
    final option1 = scenario["options"][1];
    // Lower row
    final option2 = scenario["options"][2];
    final option3 = scenario["options"][3];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred background
        Image.asset('assets/splash/cyberbullying_social_bg.jpg',
            fit: BoxFit.cover),
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(),
            ),
          ),
        ),
        // QUADRANT GRID (fills whole screen, sharp corners)
        Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildAnswerButton(option0, q),
                  ),
                  Expanded(
                    child: _buildAnswerButton(option1, q),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildAnswerButton(option2, q),
                  ),
                  Expanded(
                    child: _buildAnswerButton(option3, q),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Scenario text in bold colored box
        Center(
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: BoxDecoration(
              color: const Color(0xFFF3B11E), // golden yellow
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.11),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              scenario["prompt"],
              style: const TextStyle(
                color: Color(0xFF0A4C85), // navy blue
                fontSize: 18,
                fontWeight: FontWeight.w900,
                fontFamily: 'Montserrat',
                height: 1.28,
                letterSpacing: 1.1,
                shadows: [
                  Shadow(
                      blurRadius: 6,
                      color: Colors.black26,
                      offset: Offset(0, 2)),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // Swipe chevron
        Positioned(
          bottom: 26,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity: _popupVisible ? 0 : 1,
            duration: const Duration(milliseconds: 180),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.keyboard_arrow_up,
                    color: Colors.white, size: 37),
                SizedBox(height: 2),
                Text('SWIPE UP',
                    style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1)),
              ],
            ),
          ),
        ),
        // Feedback popup overlay
        if (_popupVisible) _buildPopup(q),
        Positioned(
          top: 36,
          left: 18,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 28,
                color: Colors.white),
            onPressed: () async {
              await _quizAudioPlayer.play(AssetSource('sounds/tap.wav'));
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButton(String label, int q) {
    final Color fill = optionColors[label]!;
    final Color txt = (label == 'Report' || label == 'Ignore' ||
        label == 'Encourage')
        ? Colors.white
        : const Color(0xFF0A4C85); // navy text for 'Support'
    return GestureDetector(
      onTap: _popupVisible ? null : () => _onSelectOption(label, q),
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.zero,
        padding:
        const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        color: fill,
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w900,
            fontSize: 21,
            letterSpacing: 2.6,
            color: txt,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const BouncingScrollPhysics(),
        itemCount: _scenarios.length,
        onPageChanged: (i) {
          setState(() {
            _currentIndex = i;
            _popupVisible = false;
            _popupType = "";
            _showCorrectFromIncorrect = false;
          });
        },
        itemBuilder: (_, i) => _buildScenarioPage(i),
      ),
    );
  }
}
