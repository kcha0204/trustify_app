import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiCategorySeverity {
  final String category;
  final int severity; // 0-7
  final String level; // safe, low, medium, high
  final String severityLabel; // Very Harmful, Harmful, Warning, Safe
  final String emoji; // 🛑, ⚠️, 🟡, ✅

  AiCategorySeverity(
      {required this.category, required this.severity, required this.level, required this.severityLabel, required this.emoji});
}

class AiDetectionResult {
  final bool isHarmful;
  final String message; // Main friendly summary for user
  final String riskLevel;
  final List<AiCategorySeverity> severities;
  final String composedSummary; // Extra info for developer/debug
  final String error;

  AiDetectionResult(
      {required this.isHarmful, required this.message, required this.riskLevel, required this.severities, required this.composedSummary, required this.error});

  factory AiDetectionResult.fromJson(Map<String, dynamic> j) {
    // Handle different response structures:
    // 1. Text moderation: { "raw": { "categoriesAnalysis": [...] } }
    // 2. Screenshot: { "moderation": { "raw": { "categoriesAnalysis": [...] } } }
    // 3. Screenshot with no text: { "moderation": null }

    Map<String, dynamic> raw = {};
    if (j.containsKey('moderation') && j['moderation'] != null) {
      // Screenshot response structure
      raw = j['moderation']['raw'] ?? {};
    } else if (j.containsKey('raw')) {
      // Text moderation response structure
      raw = j['raw'] ?? {};
    }
    // If neither exists, raw remains empty (no moderation data)

    final categoriesAnalysis = raw['categoriesAnalysis'] ?? [];
    List<String> high = [],
        medium = [],
        low = [],
        safe = [],
        allCats = [];
    List<AiCategorySeverity> list = [];

    // Handle case where there's no categoriesAnalysis (e.g., image with no text)
    if (categoriesAnalysis.isEmpty) {
      return AiDetectionResult(
        isHarmful: false,
        message: "✅ No text found in this image to analyze. The image itself appears to be safe!",
        riskLevel: "Safe Content",
        severities: [],
        composedSummary: "No text content detected for analysis.",
        error: (j['error'] ?? '').toString(),
      );
    }

    for (final c in categoriesAnalysis) {
      final s = c['severity'] ?? 0;
      final cat = (c['category'] ?? '').toString();
      allCats.add(cat);
      if ([4, 5, 6, 7].contains(s))
        high.add(cat);
      else if ([2, 3].contains(s))
        medium.add(cat);
      else if (s == 1)
        low.add(cat);
      else
        safe.add(cat);

      final _sev = _mapSeverityToText(s);
      list.add(AiCategorySeverity(
        category: cat,
        severity: s,
        level: _sev['level'] ?? '',
        severityLabel: _sev['label'] ?? '',
        emoji: _sev['emoji'] ?? '',
      ));
    }

    String friendlyMessage = '';
    if (high.isNotEmpty) {
      friendlyMessage =
      "Whoa, serious alert 🚨 There's some really intense stuff here about ${high
          .join(
          ', ')}. If this content makes you feel upset, please talk to someone you trust—you're not alone.";
    } else if (medium.isNotEmpty) {
      friendlyMessage =
      "Heads up ⚠️! There's a bit of heavy stuff here about ${medium.join(
          ', ')}. Stay sharp and remember, it's totally okay to click away or speak up if it feels off.";
    } else if (low.isNotEmpty) {
      friendlyMessage =
      "Just an FYI! 🟡 There might be some slightly touchy topics about ${low
          .join(
          ', ')}. It's probably nothing major, but trust your own feelings.";
    } else {
      friendlyMessage =
      "All good! ✅ This content looks totally safe. No red flags here—enjoy and scroll on. 🙌";
      if (allCats.isNotEmpty) {
        friendlyMessage += " For reference, we checked: ${allCats.join(', ')}.";
      }
    }

    String riskLevel = "Safe Content";
    if (high.isNotEmpty)
      riskLevel = "Very Harmful";
    else if (medium.isNotEmpty)
      riskLevel = "Harmful";
    else if (low.isNotEmpty) riskLevel = "Warning";

    final composedSummary = high.isNotEmpty
        ? "High severity categories: ${high.join(", ")}"
        : medium.isNotEmpty
        ? "Medium severity categories: ${medium.join(", ")}"
        : low.isNotEmpty
        ? "Low severity categories: ${low.join(", ")}"
        : "No harmful category detected.";

    return AiDetectionResult(
      isHarmful: high.isNotEmpty || medium.isNotEmpty,
      message: friendlyMessage,
      riskLevel: riskLevel,
      severities: list,
      composedSummary: composedSummary,
      error: (j['error'] ?? '').toString(),
    );
  }
}

// Helper to map severity integer (Azure/CS) to our label
Map<String, String> _mapSeverityToText(int severity) {
  if ([4, 5, 6, 7].contains(severity))
    return {'level': 'high', 'label': 'Very Harmful', 'emoji': '🛑'};
  if ([2, 3].contains(severity))
    return {'level': 'medium', 'label': 'Harmful', 'emoji': '⚠️'};
  if ([1].contains(severity))
    return {'level': 'low', 'label': 'Warning', 'emoji': '🟡'};
  return {'level': 'safe', 'label': 'Safe Content', 'emoji': '✅'};
}

class AiDetectionService {
  final String baseUrl;
  final Uuid _uuid = Uuid();
  AiDetectionService(this.baseUrl);

  Future<AiDetectionResult> analyzeText(String text) async {
    final uri = Uri.parse('$baseUrl/moderate-text');
    final reportId = _uuid.v4();
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    print('DEBUG: analyzeText called');
    print('DEBUG: URI = $uri');
    print('DEBUG: Content-Type = application/json');
    print('DEBUG: Text length = ${text.length}');

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $supabaseAnonKey',
      },
      body: jsonEncode({
        'report_id': reportId,
        'text': text,
      }),
    );

    print('DEBUG: Response status = ${res.statusCode}');
    print('DEBUG: Response body = ${res.body}');

    if (res.statusCode != 200) {
      throw Exception('Analyze text failed: ${res.statusCode} ${res.body}');
    }
    return AiDetectionResult.fromJson(jsonDecode(res.body));
  }

  Future<AiDetectionResult> analyzeScreenshot(File imageFile) async {
    final uri = Uri.parse('$baseUrl/process-screenshot');
    final reportId = _uuid.v4();
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    print('DEBUG: analyzeScreenshot called');
    print('DEBUG: URI = $uri');
    print('DEBUG: Content-Type = multipart/form-data');
    print('DEBUG: Image path = ${imageFile.path}');

    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $supabaseAnonKey';
    req.fields['report_id'] = reportId;
    req.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();

    print('DEBUG: Response status = ${streamed.statusCode}');
    print('DEBUG: Response body = $body');

    if (streamed.statusCode != 200) {
      throw Exception(
        'Analyze screenshot failed: ${streamed.statusCode} $body',
      );
    }
    return AiDetectionResult.fromJson(jsonDecode(body));
  }
}
