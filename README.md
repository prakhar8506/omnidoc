# Cura

Quiet care for everyday health — Recovery OS, labs, appointments, wearables, and AI guidance.

**Not a medical device.** Outputs are informational; always confirm with a clinician.

## Run locally

```bash
flutter pub get
./scripts/run_local.sh
# or against cloud:
flutter run --dart-define-from-file=env/production.json
```

## Production Android (Play Store)

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=env/production.json
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.
Keep `android/key.properties` + `android/app/upload-keystore.jks` backed up.

## Production iOS (App Store)

```bash
flutter build ipa --release --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=env/production.json
```

Requires Apple Developer Program, Team ID, and HealthKit capability enabled in Xcode.

## Store checklist

1. Google Play Console + Apple Developer accounts
2. Host Privacy Policy / Terms (also available in-app under Profile)
3. Screenshots for phone sizes
4. Data Safety / Privacy Nutrition Labels (health data)
5. Medical disclaimer: not a medical device
6. Configure Supabase Auth redirect URL: `cura://auth-callback`
7. Optional: set `SENTRY_DSN` in `env/production.json`

## Backend

See `LAUNCH_SETUP.md` for Supabase migrations, Edge Functions (`health-ai-chat`, `interpret-lab`, `delete-account`), and Gemini secrets.
