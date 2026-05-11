import 'package:shared_preferences/shared_preferences.dart';

class RatingPromptService {
  static const _successfulCallsKey = 'rating_successful_calls_v1';
  static const _promptedKey = 'rating_prompted_v1';

  static Future<bool> shouldAskAfterSuccessfulCall() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_promptedKey) ?? false) return false;
    final calls = (prefs.getInt(_successfulCallsKey) ?? 0) + 1;
    await prefs.setInt(_successfulCallsKey, calls);
    return calls >= 1;
  }

  static Future<void> markPrompted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promptedKey, true);
  }
}
