# BridgeCall App Store Release Checklist

## Required Metadata

- Privacy Policy URL: `https://bridgecall.tech/privacy`
- Support URL: `https://bridgecall.tech`
- Subscription entitlement: `pro`
- RevenueCat products configured and approved in App Store Connect.
- Microphone/camera permission copy reviewed in Xcode.

## Screenshots

- iPhone 6.9-inch: onboarding, create room, live call, captions, diagnostics, paywall.
- iPhone 6.5-inch fallback screenshots if App Store Connect requests them.
- Avoid debug banners, localhost URLs, raw logs, or test credentials in screenshots.

## Production Build Flags

```bash
flutter build ipa --release \
  --dart-define=WS_URL=wss://api.bridgecall.tech \
  --dart-define=BACKEND_HTTP_URL=https://api.bridgecall.tech \
  --dart-define=REVENUECAT_IOS_API_KEY=$REVENUECAT_IOS_API_KEY \
  --dart-define=TWILIO_TURN_URLS=$TWILIO_TURN_URLS \
  --dart-define=TWILIO_TURN_USERNAME=$TWILIO_TURN_USERNAME \
  --dart-define=TWILIO_TURN_PASSWORD=$TWILIO_TURN_PASSWORD
```

## Release Risks To Verify

- Two-device TestFlight call over WiFi.
- Two-device TestFlight call over mobile data.
- WiFi to mobile-data handoff during an active call.
- TURN relay path by enabling `WEBRTC_FORCE_RELAY=true`.
- RevenueCat purchase and restore.
- Paywall products visible for the App Store region.
- Backend websocket ping/pong and reconnect logs healthy.
