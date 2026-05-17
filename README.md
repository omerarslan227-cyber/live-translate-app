# BridgeCall

Live video-call translation with low-latency subtitles, spoken translation, and private rooms.

## App Store Release Checklist

- Configure RevenueCat products and the `pro` entitlement.
- Configure production backend and WebRTC environment variables:
  - Required: `--dart-define=WS_URL=wss://api.bridgecall.tech`
  - Optional: `--dart-define=BACKEND_HTTP_URL=https://api.bridgecall.tech`
  - Twilio TURN: `--dart-define=TWILIO_TURN_URLS=turn:...`
  - Twilio TURN credentials: `TWILIO_TURN_USERNAME`, `TWILIO_TURN_PASSWORD`
  - Fallback TURN: `TURN_URLS`, `TURN_USERNAME`, `TURN_PASSWORD`
  - Emergency relay-only mode: `--dart-define=WEBRTC_FORCE_RELAY=true`
- Build with RevenueCat keys:
  - `--dart-define=REVENUECAT_IOS_API_KEY=...`
  - `--dart-define=REVENUECAT_ANDROID_API_KEY=...`
  - Optional: `--dart-define=REVENUECAT_ENTITLEMENT_ID=pro`
- Add the required Privacy Policy URL in App Store Connect metadata:
  - `https://bridgecall.tech/privacy`
- Verify the in-app Privacy Policy link opens from Profile.
- Run a two-device iPhone TestFlight call before release.
- Capture App Store screenshots from onboarding, room creation, live call, captions, and Pro paywall.
- Capture iPhone 6.9-inch screenshots for onboarding, call room, live captions, diagnostics, and Pro paywall.
- Confirm production logs do not expose TURN credentials, purchase tokens, or raw audio payloads.

## Local Checks

```bash
flutter pub get
flutter test
flutter analyze lib/main.dart lib/config lib/core lib/models lib/services lib/screens lib/widgets
```

`flutter analyze` still reports legacy lint/deprecated warnings in the large `main.dart`; these are not new build-breaking errors.

## Codemagic Required Variables

Create a secure Codemagic environment group named `bridgecall` and store:

- `WS_URL`
- `BACKEND_HTTP_URL`
- `REVENUECAT_IOS_API_KEY`
- `TWILIO_TURN_URLS`
- `TWILIO_TURN_USERNAME`
- `TWILIO_TURN_PASSWORD`
- `TURN_URLS`
- `TURN_USERNAME`
- `TURN_PASSWORD`
