# Health Companion

Serene Clinical health companion app built with Flutter — vitals, symptom triage, appointments/family sharing, lab interpretation, and an on-device AI copilot.

## Run locally

```bash
flutter pub get
flutter run
```

Demo sign-in: any valid email + password (6+ characters). Prefill: `sarah.jenkins@email.com` / `demo1234`.

## Platforms

| Platform | Status |
|----------|--------|
| Android  | Ready (`android/`) — `com.healthcompanion.health_companion` |
| iOS      | Ready (`ios/`) — bundle from Flutter org |
| Web      | Supported (`web/`) |

```bash
# Android release APK / App Bundle
flutter build appbundle --release

# iOS (macOS + Xcode required)
flutter build ipa --release
```

## Store launch checklist

1. Create Apple Developer + Google Play Console accounts
2. Replace debug signing with release keystores / certificates
3. Customize app icons (replace default Flutter icons under `android/.../mipmap-*` and `ios/Runner/Assets.xcassets/AppIcon.appiconset`)
4. Host a Privacy Policy URL and add it in store listings
5. Complete App Store medical/disclaimer questionnaire (this app is **not** a medical device)
6. Submit screenshots from device / simulator for phone sizes

## Important product notes

- Data is **local demo state** (session persisted with SharedPreferences). There is no production backend, billing, or real clinical auth yet.
- Triage / lab / AI features are **guidance simulations**, not diagnoses.
- Do not claim HIPAA / FDA clearance until you have real infrastructure and legal review.
