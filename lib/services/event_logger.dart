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
    // TODO: Add Azure analytics/event logging implementation (or alternative).
  }

  /// Fetch the latest detection events for debugging or trend stats
  static Future<List<Map<String, dynamic>>> fetchRecentEvents(
      {int limit = 10}) async {
    // TODO: Add Azure analytics/event logging implementation (or alternative).
    return [];
  }
}
