import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AiDetectionResult {
  final bool isHarmful;
  final String riskLevel;
  final Map<String, dynamic> categories;
  final Map<String, dynamic> confidenceScores;
  final String? ocrText;
  final String provider;
  final String? error;

  AiDetectionResult({
    required this.isHarmful,
    required this.riskLevel,
    required this.categories,
    required this.confidenceScores,
    this.ocrText,
    required this.provider,
    this.error,
  });

  factory AiDetectionResult.fromJson(Map<String, dynamic> j) {
    return AiDetectionResult(
      isHarmful: j['is_harmful'] ?? false,
      riskLevel: j['risk_level'] ?? 'Safe',
      categories: Map<String, dynamic>.from(j['categories'] ?? {}),
      confidenceScores: Map<String, dynamic>.from(j['confidence_scores'] ?? {}),
      ocrText: j['ocr_text'],
      provider: j['provider'] ?? 'azure',
      error: j['error'],
    );
  }
}

class AiDetectionService {
  final String baseUrl;
  AiDetectionService(this.baseUrl);

  Future<AiDetectionResult> analyzeText(String text) async {
    final uri = Uri.parse('$baseUrl/analyze/text/enhanced');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
    if (res.statusCode != 200) {
      throw Exception('Analyze text failed: ${res.statusCode} ${res.body}');
    }
    return AiDetectionResult.fromJson(jsonDecode(res.body));
  }

  Future<AiDetectionResult> analyzeScreenshot(File imageFile) async {
    final uri = Uri.parse('$baseUrl/analyze/screenshot/enhanced');
    final req = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw Exception('Analyze screenshot failed: ${streamed.statusCode} $body');
    }
    return AiDetectionResult.fromJson(jsonDecode(body));
  }
}
