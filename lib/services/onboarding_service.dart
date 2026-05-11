import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const _completeKey = 'onboarding_complete_v1';
  static const _profileKey = 'profile_v1';

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completeKey) ?? false;
  }

  static Future<void> markComplete({
    String sourceLanguage = 'Türkçe',
    String targetLanguage = 'İngilizce',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existingRaw = prefs.getString(_profileKey);
    final profile = existingRaw == null || existingRaw.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(existingRaw) as Map<String, dynamic>);
    profile['preferredSourceLanguage'] = sourceLanguage;
    profile['preferredTargetLanguage'] = targetLanguage;
    profile['displayName'] = (profile['displayName'] ?? '').toString();
    profile['about'] = (profile['about'] ?? '').toString();
    profile['avatarMode'] = profile['avatarMode'] == true;
    await prefs.setString(_profileKey, jsonEncode(profile));
    await prefs.setBool(_completeKey, true);
  }
}
