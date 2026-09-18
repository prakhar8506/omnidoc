# Launch setup — Cura

## Done

| Step | Status |
|------|--------|
| Cloud Supabase project | ✅ |
| Migrations + RLS + storage | ✅ |
| Edge Functions deployed | ✅ |
| Gemini live AI chat | ✅ |
| Gemini lab OCR (`interpret-lab`) | ✅ (redeploy after code changes) |
| `env/production.json` (gitignored) | ✅ |
| Demo mode off in release | ✅ |
| Brand: **Cura** + icons | ✅ |
| Privacy / Terms in-app | ✅ |
| Account deletion Edge Function + UI | ✅ |
| iOS HealthKit usage strings + PrivacyInfo | ✅ |
| Auth deep link scheme `cura://` | ✅ |
| Upload keystore for Play | ✅ |

## Remaining (manual / accounts)

1. Create Play Console listing + upload **AAB** (not APK)
2. Apple Developer + App Store Connect + TestFlight IPA
3. Host public Privacy Policy URL for store forms (in-app copy already ships)
4. Set Supabase Auth Site URL / redirect: `cura://auth-callback`
5. Optional SMTP for auth emails (avoid rate limits)
6. Optional `SENTRY_DSN` in production defines
7. Rotate any keys that were pasted in shell history

## Build commands

```bash
# Play Store
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=env/production.json

# App Store
flutter build ipa --release --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=env/production.json
```

## Redeploy AI / OCR functions

```bash
supabase functions deploy health-ai-chat --project-ref fpvcyxjatjajsaziblzg
supabase functions deploy interpret-lab --project-ref fpvcyxjatjajsaziblzg
supabase functions deploy delete-account --project-ref fpvcyxjatjajsaziblzg
```
