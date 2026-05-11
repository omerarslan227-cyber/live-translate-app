# BridgeCall App Store Beta Plan

## Positioning

BridgeCall is a live video-call translator focused on fast subtitles and spoken translation during real conversations.

Short description:
Live video calls with fast AI translation, subtitles, and voice playback.

Value message:
Talk across languages with faster live translation, readable subtitles, and simple private rooms.

## Suggested Keywords

live translator, video call translator, voice translation, AI interpreter, subtitle translation, Turkish English translator, phone translator, travel translator, language call, speech to text

## Screenshot Flow

1. Onboarding: live translation promise.
2. Create room: Turkish to English default setup.
3. Call screen: premium video call UI with live voice status.
4. Caption panel: original and translated subtitles visible.
5. Paywall: Pro unlimited live translation.

## Monetization

Freemium beta model:
- Daily 3 minutes free.
- Pro unlocks unlimited usage.
- RevenueCat product placeholders:
  - `bridgecall_pro_monthly`
  - `bridgecall_pro_yearly`
  - entitlement: `pro`

## Viral Loop

Current prepared flows:
- Room invite link.
- Transcript share message.
- Referral copy placeholder: invite a friend, both receive 1 week Pro.

## Remaining App Store Work

1. Create RevenueCat project, products, offering, and entitlement `pro`.
2. Build with `--dart-define=REVENUECAT_IOS_API_KEY=...` and `--dart-define=REVENUECAT_ANDROID_API_KEY=...`.
3. Add Privacy Policy URL to App Store Connect metadata. Apple requires this URL for submission.
4. Keep the in-app Privacy Policy link pointing to the same public URL: `https://bridgecall.tech/privacy`.
5. Produce clean iPhone screenshots from the demo flow.
6. Run real two-device call tests before TestFlight.
