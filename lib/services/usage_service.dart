import 'package:shared_preferences/shared_preferences.dart';

class UsageSnapshot {
  final bool isPro;
  final int usedSeconds;
  final int freeLimitSeconds;

  const UsageSnapshot({
    required this.isPro,
    required this.usedSeconds,
    required this.freeLimitSeconds,
  });

  int get remainingSeconds => isPro
      ? 1 << 30
      : (freeLimitSeconds - usedSeconds).clamp(0, freeLimitSeconds);
  bool get canStartCall => isPro || remainingSeconds > 0;
  String get remainingLabel {
    if (isPro) return 'Pro sınırsız';
    final minutes = (remainingSeconds / 60).ceil();
    return '$minutes dk ücretsiz kaldı';
  }
}

class UsageService {
  static const int freeDailySeconds = 180;
  static const _dateKey = 'usage_date_v1';
  static const _secondsKey = 'usage_seconds_v1';
  static const _proKey = 'subscription_pro_v1';

  static Future<UsageSnapshot> snapshot() async {
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    return UsageSnapshot(
      isPro: prefs.getBool(_proKey) ?? false,
      usedSeconds: prefs.getInt(_secondsKey) ?? 0,
      freeLimitSeconds: freeDailySeconds,
    );
  }

  static Future<bool> canStartCall() async => (await snapshot()).canStartCall;

  static Future<void> addCallSeconds(int seconds) async {
    if (seconds <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    await _resetIfNewDay(prefs);
    if (prefs.getBool(_proKey) ?? false) return;
    final current = prefs.getInt(_secondsKey) ?? 0;
    await prefs.setInt(_secondsKey, current + seconds);
  }

  static Future<void> setDebugPro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, value);
  }

  static Future<void> _resetIfNewDay(SharedPreferences prefs) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString(_dateKey) == today) return;
    await prefs.setString(_dateKey, today);
    await prefs.setInt(_secondsKey, 0);
  }
}
