import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _completeKey = 'onboarding_complete_v1';

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completeKey) ?? false;
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completeKey, true);
  }
}
