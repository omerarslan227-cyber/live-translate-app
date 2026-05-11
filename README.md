# BridgeCall

Live video-call translation with low-latency subtitles, spoken translation, and private rooms.

## App Store Release Checklist

- Configure RevenueCat products and the `pro` entitlement.
- Build with RevenueCat keys:
  - `--dart-define=REVENUECAT_IOS_API_KEY=...`
  - `--dart-define=REVENUECAT_ANDROID_API_KEY=...`
  - Optional: `--dart-define=REVENUECAT_ENTITLEMENT_ID=pro`
- Add the required Privacy Policy URL in App Store Connect metadata:
  - `https://bridgecall.tech/privacy`
- Verify the in-app Privacy Policy link opens from Profile.
- Run a two-device iPhone TestFlight call before release.
- Capture App Store screenshots from onboarding, room creation, live call, captions, and Pro paywall.

## Local Checks

```bash
flutter pub get
flutter test
flutter analyze lib/main.dart lib/models lib/services lib/screens lib/widgets
```

`flutter analyze` still reports legacy lint/deprecated warnings in the large `main.dart`; these are not new build-breaking errors.
