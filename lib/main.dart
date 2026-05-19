import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'config/app_config.dart';
import 'core/app_logger.dart';
import 'models/language_option.dart';
import 'screens/onboarding_screen.dart';
import 'screens/paywall_screen.dart';
import 'services/growth_service.dart';
import 'services/onboarding_service.dart';
import 'services/rating_prompt_service.dart';
import 'services/revenuecat_service.dart';
import 'services/reliable_web_socket.dart';
import 'services/usage_service.dart';
import 'services/webrtc_config_service.dart';
import 'widgets/connection_status_pill.dart';
import 'widgets/glass_card.dart';

part 'core/app_data.dart';
part 'screens/home_screen.dart';
part 'screens/history_screen.dart';
part 'screens/voice_diagnostics_screen.dart';
part 'screens/profile_screen.dart';
part 'screens/call_screen.dart';
part 'widgets/app_form_widgets.dart';

final ValueNotifier<int> appRefresh = ValueNotifier<int>(0);

void triggerAppRefresh() => appRefresh.value++;

void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLogger.error('flutter', 'framework error', {}, details.exception);
      };
      unawaited(_configureStartupServices());
      runApp(const LiveTranslateApp());
    },
    (error, stackTrace) {
      AppLogger.error('startup', 'unhandled zone error', {}, error, stackTrace);
      WidgetsFlutterBinding.ensureInitialized();
      runApp(AppStartupFailed(error: error, stackTrace: stackTrace));
    },
  );
}

Future<void> _configureStartupServices() async {
  try {
    final result = await RevenueCatService.configure();
    if (!result.success) {
      AppLogger.warn('subscription', 'RevenueCat not ready', {
        'message': result.message,
      });
    }
  } catch (e, stackTrace) {
    AppLogger.error(
      'subscription',
      'RevenueCat startup failed',
      {},
      e,
      stackTrace,
    );
  }
}

Future<void> configureCallTts(FlutterTts tts) async {
  await _configureTtsAudio(tts, speakerPlayback: false);
}

Future<void> configureSpeakerTts(FlutterTts tts) async {
  await _configureTtsAudio(tts, speakerPlayback: true);
}

Future<void> _configureTtsAudio(
  FlutterTts tts, {
  required bool speakerPlayback,
}) async {
  await tts.setVolume(1.0);
  await tts.setPitch(1.0);
  await tts.setSpeechRate(0.50);

  if (!Platform.isIOS) return;

  try {
    await tts.setSharedInstance(true);
    await tts.autoStopSharedSession(false);
    await tts.setIosAudioCategory(
      speakerPlayback
          ? IosTextToSpeechAudioCategory.playback
          : IosTextToSpeechAudioCategory.playAndRecord,
      speakerPlayback
          ? [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            ]
          : [
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            ],
      speakerPlayback
          ? IosTextToSpeechAudioMode.moviePlayback
          : IosTextToSpeechAudioMode.voiceChat,
    );
  } catch (e) {
    debugPrint('[BridgeCallVoice] iOS TTS audio configuration failed: $e');
  }
}

class LiveTranslateApp extends StatelessWidget {
  const LiveTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BridgeCall',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050816),
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF4F8CFF),
          surface: Color(0xFF0B1224),
        ),
      ),
      home: FutureBuilder<bool>(
        future: OnboardingService.isComplete(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          const home = HomeShell();
          return snapshot.data == true
              ? home
              : const OnboardingScreen(next: home);
        },
      ),
    );
  }
}

class AppStartupFailed extends StatelessWidget {
  final Object error;
  final StackTrace? stackTrace;

  const AppStartupFailed({super.key, required this.error, this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.4)),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  'App startup failed:\\n$error',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
