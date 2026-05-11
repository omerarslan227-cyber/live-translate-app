import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingPromptService {
  static const _successfulCallsKey = 'rating_successful_calls_v1';
  static const _promptedKey = 'rating_prompted_v1';
  static const _lastPromptDateKey = 'rating_last_prompt_date_v1';
  static const int minSuccessfulCalls = 3;
  static const int cooldownDays = 120;

  static Future<bool> shouldAskAfterSuccessfulCall({
    required bool wasSuccessful,
  }) async {
    if (!wasSuccessful) return false;
    final prefs = await SharedPreferences.getInstance();
    final calls = (prefs.getInt(_successfulCallsKey) ?? 0) + 1;
    await prefs.setInt(_successfulCallsKey, calls);
    if (calls < minSuccessfulCalls) return false;

    final prompted = prefs.getBool(_promptedKey) ?? false;
    final lastPromptRaw = prefs.getString(_lastPromptDateKey);
    final lastPrompt = lastPromptRaw == null
        ? null
        : DateTime.tryParse(lastPromptRaw);
    if (prompted &&
        lastPrompt != null &&
        DateTime.now().difference(lastPrompt).inDays < cooldownDays) {
      return false;
    }
    return true;
  }

  static Future<bool> requestReviewIfAppropriate({
    required bool wasSuccessful,
  }) async {
    if (!await shouldAskAfterSuccessfulCall(wasSuccessful: wasSuccessful)) {
      return false;
    }
    try {
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return false;
      await review.requestReview();
      await markPrompted();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promptedKey, true);
    await prefs.setString(_lastPromptDateKey, DateTime.now().toIso8601String());
  }
}
