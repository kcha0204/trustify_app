import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class EventLogger {
  static String sessionId = _generateSessionId();

  static String _generateSessionId() {
    final rand = Random();
    final time = DateTime
        .now()
        .millisecondsSinceEpoch
        .remainder(10000000)
        .toInt();
    final randNum = rand.nextInt(99999);
    return '$time-$randNum';
  }

  /// Insert a new detection event for later analytics/quiz
  static Future<void> logDetectionEvent({
    required String type, // 'text' or 'image'
    required String preview,
    required String aiLabel,
    required double aiScore,
    required String category,
    List<double>? embedding,
  }) async {
    final data = {
      'content_type': type,
      'preview': preview,
      'ai_label': aiLabel,
      'ai_score': aiScore,
      'category': category,
      'session_id': sessionId,
      if (embedding != null) 'embedding': embedding,
    };
    final res = await Supabase.instance.client.from('content_events').insert(
        data);
    if (res.error != null) {
      throw Exception('Failed to log event: ${res.error!.message}');
    }
    // You can return the id or whatever if you like
  }

  /// Fetch the latest detection events for debugging or trend stats
  static Future<List<Map<String, dynamic>>> fetchRecentEvents(
      {int limit = 10}) async {
    final res = await Supabase.instance.client
        .from('content_events')
        .select()
        .order('inserted_at', ascending: false)
        .limit(limit)
        .execute();
    if (res.error != null) {
      throw Exception('Failed to fetch events: ${res.error!.message}');
    }
    return List<Map<String, dynamic>>.from(res.data);
  }
}
