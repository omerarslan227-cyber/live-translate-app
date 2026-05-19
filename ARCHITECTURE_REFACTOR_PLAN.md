# BridgeCall Production Refactor Plan

Last updated: 2026-05-19

## Current Risk

`lib/main.dart` still owns too many responsibilities: navigation, screens, WebRTC call flow, subtitles, socket state, history, and UI widgets. This does not block the current build, but it is a production maintainability risk.

## Target Folder Structure

```text
lib/
  config/
  core/
    error/
    logging/
    navigation/
  features/
    call/
      data/
      domain/
      presentation/
    home/
      presentation/
    onboarding/
      presentation/
    profile/
      data/
      presentation/
    subscription/
      data/
      presentation/
  models/
  providers/
  services/
  widgets/
```

## Migration Strategy

1. Move pure widgets first.
   - Keep behavior identical.
   - Prefer small files under `lib/widgets/` and feature `presentation/widgets/`.

2. Split screens second.
   - `HomeScreen` -> `features/home/presentation/home_screen.dart`
   - `CallScreen` -> `features/call/presentation/call_screen.dart`
   - `ProfileScreen` -> `features/profile/presentation/profile_screen.dart`
   - `HistoryScreen` -> `features/call/presentation/history_screen.dart`

3. Extract services third.
   - WebRTC orchestration -> `features/call/data/webrtc_call_service.dart`
   - Subtitle/STT transport -> `features/call/data/subtitle_pipeline_service.dart`
   - Translation socket -> existing `ReliableWebSocketClient` plus feature repository.
   - Permissions -> `services/permission_manager.dart`

4. Introduce dependency boundaries.
   - UI talks to controllers/repositories, not raw sockets or platform APIs.
   - RevenueCat, usage, rating, and growth remain isolated services.

5. Add tests after each slice.
   - Unit tests for room-code validation and config parsing.
   - Widget smoke tests for onboarding, paywall, and call controls.
   - Integration checklist for real-device WebRTC.

## Navigation Architecture

Use named routes only after screen extraction is complete:

```dart
Route<dynamic> onGenerateRoute(RouteSettings settings)
```

Keep call routes isolated so WebRTC state is created and disposed with the call screen only.

## Production Guardrails

- No behavior rewrite during file moves.
- One feature slice per commit.
- Run `flutter analyze` and a web/iOS build after each slice.
- Preserve current working STT, translation, TTS, RevenueCat, and WebRTC behavior.
