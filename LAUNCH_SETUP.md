# Launch setup — current status

## Done on this machine (local)

| Step | Status |
|------|--------|
| Supabase CLI installed | ✅ |
| Local Supabase via Docker | ✅ `http://127.0.0.1:54321` |
| Migrations applied (schema, RLS, domain tables, storage, auth trigger) | ✅ |
| Storage buckets `lab-uploads`, `avatars`, `exports` | ✅ |
| Edge Functions served (`interpret-lab`, `health-ai-chat`, `delete-account`) | ✅ |
| Auth signup → profile auto-create verified | ✅ |
| AI function returns honest offline reply (no provider key yet) | ✅ |
| `env/local.json` + `env/local.android.json` written (gitignored) | ✅ |
| Debug cleartext HTTP for Android emulator | ✅ |
| Helper scripts `scripts/run_local.sh`, `scripts/deploy_cloud_supabase.sh` | ✅ |

### Run the app against local Supabase

```bash
# Terminal A — keep Supabase up
supabase start
supabase functions serve --env-file supabase/.env.local --no-verify-jwt

# Terminal B — Flutter
./scripts/run_local.sh
# or Android emulator:
flutter run -d <emulator-id> --dart-define-from-file=env/local.android.json
```

Studio UI: http://127.0.0.1:54323  
Mailpit (email confirmations): http://127.0.0.1:54324

---

## Hosted (Play/App Store) — needs your Supabase account

Cloud project creation requires **your** login (cannot be completed without browser auth).

1. Open https://supabase.com/dashboard and create a free project (a browser tab may already be open).
2. In this repo:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
./scripts/deploy_cloud_supabase.sh
```

3. Copy Project URL + `anon` `public` key into `env/production.json` (see `env/production.json.example`).
4. Optional AI:

```bash
supabase secrets set OPENAI_API_KEY=sk-...
# or
supabase secrets set GEMINI_API_KEY=...
```

5. Release build:

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=env/production.json
```

---

## AI provider note

No `OPENAI_API_KEY` / `GEMINI_API_KEY` was found in this environment. Lab OCR + live LLM stay in **honest offline mode** until you set those secrets. The app will not invent biomarkers.
