# Cura — Current Process, Tech Stack, and Global Production Scale

> **Product:** Cura (package `health_companion`)  
> **Tagline:** Quiet care for everyday health  
> **Legal posture:** Wellness / information app — **not a medical device**. Outputs are informational; users must confirm with a clinician.  
> **Audience for this file:** Engineering, launch, and ops. Use it to understand how we work today and what to keep, replace, or add before a global Play Store + App Store release.  
> **Date:** 2026-09-19

Related docs (do not duplicate; link instead):

| Document | Role |
|----------|------|
| `README.md` | Short run / build commands |
| `LAUNCH_SETUP.md` | Live cloud checklist (what is already deployed) |
| `PRODUCTION_READINESS_AUDIT.md` | Historical honesty audit of demo/fake paths (2026-09-16) |
| `ANTIGRAVITY_PRODUCTION_LAUNCH_PROMPT.md` | Phased implementation program (0–7) |
| `APP_FEATURES_WORKFLOWS_AND_UI_SPEC.md` | Intended UX and navigation |
| `env/production.json.example` | Secret injection pattern (placeholders only) |

---

## 1. Product identity (as shipped in code)

| Item | Value |
|------|--------|
| Display name | Cura |
| Legal entity (in-app) | Cura Health |
| Support email (in-app) | `support@cura.health` |
| Android application ID | `com.healthcompanion.health_companion` |
| iOS bundle ID | `com.healthcompanion.health_companion` |
| Version | `1.0.0+1` (`pubspec.yaml`) |
| Auth deep link | `cura://auth-callback` (also `cura://auth`) |
| Android min / target SDK | 26 / Flutter current target (36 at last audit) |
| Locales | English + Hindi (`AppLocalizations`) |
| Default timezone in schema | `Asia/Kolkata` |

Release builds **fail fast** if `SUPABASE_URL` and `SUPABASE_ANON_KEY` are missing (`AppEnv.validateRequired()` in `main.dart`). Demo persona is gated: `ENABLE_DEMO` only works in debug (`kDebugMode`).

---

## 2. Current process (how we actually build and ship)

This is the operating loop used so far. Global production should keep the same shape and add CI, store accounts, and region-ready policy.

```text
  Developer machine
        │
        ├─ flutter pub get
        ├─ flutter analyze / flutter test
        └─ ./scripts/run_local.sh          ← local Supabase + Edge Functions
                    │
                    ▼
        Cloud cutover (one-time + as schema changes)
                    │
                    ├─ supabase login / link
                    ├─ ./scripts/deploy_cloud_supabase.sh
                    │     • db push (migrations + RLS + storage)
                    │     • functions deploy (health-ai-chat, interpret-lab, delete-account)
                    ├─ supabase secrets set GEMINI_API_KEY=…  (or OPENAI_API_KEY)
                    └─ write env/production.json  (gitignored)
                    │
                    ▼
        Store artifacts
                    │
                    ├─ Android: flutter build appbundle --release --obfuscate …
                    └─ iOS:     flutter build ipa --release --obfuscate …
                    │
                    ▼
        Play Console / App Store Connect  (manual — not automated yet)
```

### 2.1 Day-to-day development

1. Install Flutter (Dart SDK `>=3.0.0 <4.0.0`) and platform toolchains (Xcode on macOS, Android SDK).
2. Copy env templates; never commit real keys (`env/*.json` is gitignored except `*.example`).
3. Start the local backend (or let the helper script do it):
   ```bash
   supabase start
   ./scripts/run_local.sh
   # Android emulator: ./scripts/run_local.sh -d emulator-5554
   # Cloud backend:    flutter run --dart-define-from-file=env/production.json
   ```
4. `run_local.sh` checks `http://127.0.0.1:54321/auth/v1/health`, starts Supabase if needed, and best-effort serves Edge Functions with `supabase/.env.local`.
5. Quality gate before merge-quality work:
   ```bash
   flutter analyze
   flutter test
   ```
6. There is **no GitHub Actions / CI pipeline yet**. All analysis, tests, and store builds are run on developer machines.

### 2.2 Configuration injection

Secrets and project URLs are compile-time Dart defines, not checked into source:

| Key | Required in release | Purpose |
|-----|---------------------|---------|
| `SUPABASE_URL` | Yes | Hosted Postgres + Auth + Storage |
| `SUPABASE_ANON_KEY` | Yes | Public client key (RLS still applies) |
| `AI_GATEWAY_URL` | No | Override Edge Function base; default `$SUPABASE_URL/functions/v1` |
| `SENTRY_DSN` | No | Crash reporting; skipped if empty |
| `ENABLE_DEMO` | Must be `false` in store builds | Debug-only demo persona |

Pattern:

```bash
flutter run  --dart-define-from-file=env/local.json
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=env/production.json
```

LLM provider keys (`GEMINI_API_KEY` / `OPENAI_API_KEY`) live **only** as Supabase Function secrets — never in the Flutter binary.

### 2.3 Backend change process

Schema is versioned SQL under `supabase/migrations/`. Apply order:

| Migration | What it adds |
|-----------|----------------|
| `20260916000000_recovery_os_schema.sql` | `profiles`, `health_events`, `scores`, `habit_logs`, `journal_entries`, `check_ins` |
| `20260916000001_row_level_security.sql` | RLS on Recovery OS tables |
| `20260916000002_profiles_extension.sql` | Profile extras |
| `20260918000000_production_domain_tables.sql` | Medical ID, family, appointments, labs, nutrition, cycle, pregnancy, chronic, workouts, consent, wearables, … |
| `20260918000001_storage_buckets.sql` | Private buckets `lab-uploads`, `avatars`, `exports` |
| `20260918000002_auth_profile_trigger.sql` | Create `profiles` row on signup |

After SQL or function edits:

```bash
supabase db push
supabase functions deploy health-ai-chat --project-ref <REF>
supabase functions deploy interpret-lab --project-ref <REF>
supabase functions deploy delete-account --project-ref <REF>
```

Live project status and deploy notes: `LAUNCH_SETUP.md`.

### 2.4 Mobile release process (current)

**Android (Play Store) — artifact is AAB, not APK**

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=env/production.json
```

- Output: `build/app/outputs/bundle/release/app-release.aab`
- Signing: `android/key.properties` + `android/app/upload-keystore.jks` (gitignored). Keep a sealed backup of both; losing the upload key blocks updates.
- R8 minify is on for the Android layer (Flutter Gradle release default). Dart obfuscation is **opt-in** via `--obfuscate`; store the `build/symbols` folder for crash symbolication.

**iOS (App Store)**

```bash
flutter build ipa --release --obfuscate --split-debug-info=build/symbols \
  --dart-define-from-file=env/production.json
```

Requires Apple Developer Program, Team ID, HealthKit capability (already in `ios/Runner/Runner.entitlements`), and Privacy Nutrition Labels for health data.

**Web (not the global store path)**

Used for local UX verification (`flutter run -d chrome` / `web-server`). Wearables and HealthKit/Health Connect **do not run on web**. Do not treat web as the production distribution channel for v1.

### 2.5 Design and product process used so far

- UI language: luminous glassmorphism, holographic backgrounds, obsidian vitals tiles, editorial type (Newsreader + Plus Jakarta Sans via `google_fonts`).
- Spec-first: `APP_FEATURES_WORKFLOWS_AND_UI_SPEC.md` and `serene_clinical/DESIGN.md`.
- Production cutover rule: **keep the UI, replace fake backends**. Empty state is correct; never ship seeded clinical identity in release.
- Honesty rule: if a feature cannot be real for v1 (insurance adjudication, marketplace telehealth, community social graph), **hide or label “later version”** — do not snackbar-fake success.

---

## 3. Tech stack (what we use today)

### 3.1 Client

| Layer | Choice | Notes |
|-------|--------|--------|
| Framework | Flutter 3.x | iOS, Android, web, macOS targets exist |
| Language | Dart 3 | `sdk: '>=3.0.0 <4.0.0'` |
| UI | Material + custom glass widgets | `lib/core/theme`, `lib/core/widgets` |
| State | In-memory `AppState` (`ChangeNotifier`) | God-object; hydrate from local cache + Supabase |
| Local cache | `shared_preferences` | Auth session cache, per-user profile JSON |
| Navigation | Custom shell + 5-slot dock | Home, Journal, Appointments/Fitness, Labs; Triage is in-app |
| Localization | Hand-rolled `AppLocalizations` | `en`, `hi` — not ARB/`intl` codegen yet |
| Crash reporting | `sentry_flutter` | Optional DSN |
| Deep links | `app_links` | Auth callback scheme `cura://` |
| HTTP | `http` | Edge Function calls |
| Backend SDK | `supabase_flutter` | Auth session, Storage, REST |

**Feature packages already in `pubspec.yaml`:**

| Package | Used for |
|---------|----------|
| `health` | HealthKit (iOS) + Health Connect (Android) |
| `image_picker` / `file_picker` | Lab/prescription capture |
| `path_provider` / `path` | Local upload copies |
| `pdf` | Clinical PDF export |
| `uuid` / `crypto` | IDs; debug-only password hashing |
| `url_launcher` | Maps, `tel:`, https |
| `intl` | Dates |
| `google_fonts` | Brand type |

Not in the app yet (called out as next-scale tools): `flutter_secure_storage`, `workmanager` / background fetch, `speech_to_text`, `flutter_blue_plus` (BLE HR), CI, product analytics (PostHog / Amplitude).

### 3.2 Backend

| Layer | Choice |
|-------|--------|
| BaaS | Supabase (hosted + local CLI) |
| Database | PostgreSQL 17 (local `config.toml`) |
| Auth | Supabase Auth (email/password; deep-link session restore) |
| Authorization | Row Level Security (`auth.uid()`) |
| Files | Supabase Storage (private buckets) |
| Server logic | Supabase Edge Functions (Deno / TypeScript) |
| Local stack | Docker via `supabase start` — API `54321`, DB `54322` |

**Edge Functions (`supabase/functions/`):**

| Function | Job | Auth |
|----------|-----|------|
| `health-ai-chat` | Wellness coach LLM. Gemini or OpenAI. Refuses diagnosis/dosing; redirects emergencies. | JWT |
| `interpret-lab` | Vision/OCR → structured biomarkers + non-diagnostic summary + doctor questions. Persists to `lab_documents`. | JWT |
| `delete-account` | Cascading delete of user rows + storage + Auth user (service role). | JWT |

### 3.3 AI / OCR

| Concern | Current approach |
|---------|------------------|
| Chat | Edge Function → Gemini (`GEMINI_API_KEY`) **or** OpenAI (`OPENAI_API_KEY`) |
| Lab extraction | Same providers, vision JSON schema; never invent missing biomarkers |
| Client fallback | Keyword / template copilot **only if** functions URL is empty (debug/offline) |
| Keys | Server-side only |

### 3.4 Wearables and health data

| Platform | Path |
|----------|------|
| iOS | Apple HealthKit read types (HR, RHR, HRV, SpO2, steps, sleep). Entitlement + usage strings + `PrivacyInfo.xcprivacy` present. |
| Android | Health Connect read permissions + `ACTIVITY_RECOGNITION` + permission-rationale activity-alias. |
| Strategy | Watch → Health / Health Connect → Cura. **Not** proprietary BLE to every watch. |
| Honesty | `WearableService` does not invent vitals. Web is unsupported. |
| Not in v1 | Fitbit / Garmin / Whoop / Oura OAuth; generic BLE HR straps |

### 3.5 Domain engines (on-device)

These are real math with tests — they must be fed **real events**, not seeds:

- `lib/core/domains/baseline_engine.dart`
- `lib/core/domains/recovery_model.dart`
- `lib/core/domains/data_quality_service.dart`
- `lib/core/data/event_store.dart` (canonical health events + dedupe)

### 3.6 Platforms and store surfaces

| Surface | Status |
|---------|--------|
| Android Play Store | Primary v1. Upload keystore exists (`LAUNCH_SETUP.md`). Listing + AAB upload remaining. |
| Apple App Store | Primary v1. HealthKit capability present. Developer account + TestFlight remaining. |
| Flutter web | Dev / screenshot / QA aid. Not a global consumer launch channel. |
| macOS | Flutter desktop target exists; not a store v1. |

---

## 4. Tools used so far

### 4.1 Engineering

| Tool | Role |
|------|------|
| Flutter / Dart SDK | App framework and AOT compiler |
| Android Studio / Android SDK / Gradle (Kotlin DSL) | Android builds, Java 17, R8 |
| Xcode | iOS archive, HealthKit, signing, PrivacyInfo |
| Cursor / IDE | Day-to-day implementation |
| Git | Source of truth (do not commit `env/*.json`, keystores, `.jks`) |
| `flutter analyze` + `flutter_lints` | Static analysis |
| `flutter test` | Unit / widget / domain tests under `test/` |
| `flutter build appbundle` / `ipa` | Store artifacts with `--obfuscate` |

### 4.2 Backend and AI

| Tool | Role |
|------|------|
| Supabase CLI | `start`, `db push`, `functions serve/deploy`, `secrets set`, project link |
| Docker | Local Supabase stack |
| Hosted Supabase project | Production Auth, Postgres, Storage, Functions |
| Google Gemini and/or OpenAI | Chat + lab vision (function secrets) |
| Deno (Edge runtime) | Function execution |

### 4.3 Quality, privacy, crash

| Tool | Role |
|------|------|
| Sentry (`sentry_flutter`) | Optional production crashes |
| In-app Privacy Policy + Terms | `lib/features/legal/screens/` |
| iOS `PrivacyInfo.xcprivacy` | Privacy Nutrition / required reason APIs |
| Android `usesCleartextTraffic=false` | HTTPS only |
| In-app consent manager | Category toggles; must stay hydrated on launch |

### 4.4 Design and branding

| Tool / asset | Role |
|--------------|------|
| Custom glass / holographic widgets | Visual system |
| `assets/branding/cura_icon_1024.png` | Source icon |
| Android mipmaps + iOS AppIcon set + web icons | Store / launcher |
| `serene_clinical/DESIGN.md` | Design notes |

### 4.5 Not in the toolchain yet (needed to scale globally)

| Gap | Why it matters |
|-----|----------------|
| CI/CD (GitHub Actions, Codemagic, or Fastlane) | Repeatable signed builds, tests on every PR, no laptop-only releases |
| Fastlane / `fastlane match` | iOS certs, metadata, TestFlight upload |
| Play Console API / Gradle Play Publisher | Automated AAB upload to internal testing |
| Hosted public Privacy / Terms URL | Store forms require a URL, not only in-app copy |
| Product analytics with consent | Funnel, crash-free sessions, LLM cost correlation |
| Secret manager in CI | Inject `production.json` without copying files |
| Status / uptime for Edge Functions | LLM and OCR outages are user-visible |
| Translation pipeline | `en`/`hi` hardcoded maps will not scale to more locales |
| Device farm / TestFlight + Play internal testers | Health permissions behave differently per OEM |

---

## 5. Architecture as built

```text
┌─────────────────────────────────────────────────────────────┐
│  Flutter app (iOS / Android)                                │
│  UI (glass shell) → AppState → services / EventStore        │
│  Local cache: SharedPreferences                             │
└────────────────────────────┬────────────────────────────────┘
                             │ HTTPS only
                             ▼
┌─────────────────────────────────────────────────────────────┐
│  Supabase                                                   │
│  Auth · Postgres + RLS · Storage                            │
│  Edge: health-ai-chat · interpret-lab · delete-account      │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
               ▼                              ▼
     HealthKit / Health Connect         Gemini or OpenAI
     (user-granted reads)               (keys on the server)
```

**Data path for vitals:** HealthKit / Health Connect → `WearableService` → `HealthEvent` → `EventStore` → `SupabaseSyncService` → `health_events` → Recovery / Baseline engines → Home UI.

**Data path for labs:** Camera / files → local copy + Storage `lab-uploads/{user_id}/…` → `interpret-lab` → structured JSON + `biomarker_results` → Biology tab + AI context.

**Auth path:** Email/password via Supabase; deep link restores session. Release requires a configured backend. Debug may still use local accounts when `ENABLE_DEMO` is on.

---

## 6. Feature inventory vs production honesty

Use this when deciding what to **scale**, **hide**, or **finish** before a global listing. UI exists for a wide suite; store v1 should only claim what is real.

| Module | Path | Production stance |
|--------|------|-------------------|
| Splash, shell, branding | `features/splash`, `main.dart` | Ready |
| Sign in / sign up | `features/auth` | Supabase-first in release |
| Onboarding baseline | `features/onboarding` | Persist height/weight/sex/DOB/goals to `profiles` |
| Recovery Home | `features/home` + domain engines | Empty until real events exist |
| Journal | `features/journal` | Wire to `journal_entries`; hide voice until STT exists |
| Symptom triage | `features/triage` | Rule engine + emergency disclaimer; not diagnosis |
| Appointments / family | `features/appointments`, `features/family` | CRUD + maps/`tel:`; hide Join Video unless `video_url` |
| Labs + OCR/AI | `features/lab_reports` | Edge Function; no false “Verified” |
| Health AI chat | `features/ai_assistant` | Edge Function; wellness coach only |
| Wearables | `features/wearables` | HealthKit / Health Connect only |
| Nutrition, cycle, pregnancy, chronic | respective `features/*` | Persist or hide; empty defaults |
| Emergency Medical ID / SOS | `features/emergency` | User-entered data; real `tel:`/`sms:` only |
| Data export PDF / FHIR | `features/data_portability` | Export **user** data only |
| Privacy / Terms / delete account | `features/legal` + `delete-account` | Required for stores |
| Community challenges | `features/community` | **Defer / hide** unless backed |
| Insurance claims | `features/insurance` | **Defer / hide** unless a payer API exists |

Must-ship store v1 (from the launch program): auth, onboarding, empty-safe Recovery Home, wearable sync, journal, lab upload + AI summary, AI chat, Medical ID + real SOS call, appointments + directions, basic family, PDF export, privacy + account deletion, consent.

---

## 7. Scaling this process for a global production publish

Keep the current stack. Scale **process, compliance, regions, and automation** around it.

### 7.1 Distribution (stores)

1. **Google Play**
   - Create Play Console app with package `com.healthcompanion.health_companion`.
   - Upload **AAB** from the obfuscated release command.
   - Enroll Play App Signing; backup upload keystore.
   - Data Safety form: health data collected, processed by Supabase + LLM, encrypted in transit, account deletion offered.
   - Declare Health Connect permissions and camera/photos justification.
   - Content rating; target API per current Play policy.
   - Tracks: internal → closed → production. Use staged rollout (e.g. 10% → 50% → 100%).
2. **Apple App Store**
   - App Store Connect record; same bundle ID.
   - HealthKit review notes: read HR/HRV/sleep/steps for recovery trends; not diagnosis; no write of clinical diagnoses.
   - Privacy Nutrition Labels; export compliance.
   - Sign in with Apple **if** any other third-party social login is added.
   - TestFlight first; reviewer notes for Health permission steps. Prefer empty reviewer account over a seeded demo identity.
3. **Listing copy**
   - Do not claim “any smartwatch via Bluetooth”, “verified diagnosis”, “SOS dispatched”, or insurance adjudication.
   - Host a **public** Privacy Policy and Terms URL (in-app copy already exists; stores need a URL).
   - Screenshots from empty + honestly populated states.

### 7.2 Backend scale

| Topic | Current | Global next step |
|-------|---------|------------------|
| Region | Single Supabase project | Confirm project region vs primary users; plan read-replicas / extra project only if latency or data-residency requires it |
| Auth | Email/password | Optional Apple / Google via Supabase; SMTP for auth email (avoid rate limits) |
| Redirect | `cura://auth-callback` | Set Site URL + additional redirect URLs in Supabase Auth |
| RLS | Present on domain tables | Periodic audit with a second test user; never use service role in the app |
| Storage | 50 MB labs, 5 MB avatars | Quotas, virus/content scan, lifecycle for old exports |
| Functions | Three Deno functions | Rate limits per `auth.uid()`, spend alerts on Gemini/OpenAI, timeouts, structured logs without PHI |
| Backups | Supabase defaults | PITR on paid plan; tested restore drill |
| Delete | `delete-account` function | Align with Play/Apple account-deletion policy |

### 7.3 App scale

| Topic | Current | Global next step |
|-------|---------|------------------|
| Versioning | `1.0.0+1` | Semver + monotonic `versionCode` / `CFBundleVersion` per store upload |
| Obfuscation | Documented; use on every store build | Archive `build/symbols` per version for Sentry |
| ABI / size | Fat APK historically ~58 MB | Always AAB (Play splits ABIs); watch iOS bitcode/dSYM upload |
| Offline | Event store + prefs | Explicit outbox queue; conflict policy already unique on `(user_id, source, source_record_id)` |
| Background sync | Foreground hydrate | `workmanager` (Android) / background fetch (iOS) within OS limits |
| Analytics | `debugPrint` / in-memory | Sentry + consented product analytics |
| i18n | `en` + `hi` maps | Move to ARB; add store locales independently of in-app strings |
| Timezones | Schema default IST | Always store UTC; render in `profiles.timezone` |
| Secure local storage | SharedPreferences | Session is in Supabase SDK; avoid leftover SHA-256 password stores in release |

### 7.4 CI/CD to add (recommended shape)

No CI exists today. For global publish, add a pipeline that:

1. On PR: `flutter pub get` → `flutter analyze` → `flutter test`.
2. On tag / main: build AAB + IPA with `--dart-define-from-file` from CI secrets.
3. Upload symbols to Sentry.
4. Optional: internal Play track + TestFlight via Fastlane.
5. Never print env files or keystores in logs.

Codemagic or GitHub Actions with macOS + Android runners both fit a Flutter + iOS repo.

### 7.5 Compliance and clinical honesty (non-negotiable for global)

- Keep “not a medical device / not a diagnosis / not emergency care” on AI, labs, triage, and store listings.
- SOS may **dial or SMS contacts the user entered**. Do not claim dispatch or emergency-service integration (those are regulated and country-specific).
- Lab AI must not show clinician-“Verified” unless a real clinician flag exists.
- Health data in crash logs: strip PHI.
- GDPR / similar: export (PDF/FHIR path) + delete account already sketched — test them end-to-end before EU listing.
- Data residency: if you later sell in the EU/UK, confirm Supabase region and subprocessors (LLM provider) in the Privacy Policy.

### 7.6 Suggested operating cadence after launch

1. **Weekly:** crash-free rate (Sentry), LLM spend, Edge Function errors, store review replies.
2. **Per release:** bump version, obfuscated AAB/IPA, symbol archive, migration if schema changed, function deploy, staged rollout.
3. **Schema rule:** additive migrations only; never rewrite history on the hosted project.
4. **Feature rule:** new high-trust CTA ships with a real backend or stays hidden.

---

## 8. Launch checklist (global v1)

Copy into the release ticket. Tick only with evidence.

**Build & secrets**

- [ ] `env/production.json` on the build machine / CI only (not git)
- [ ] Release start fails without Supabase defines
- [ ] `ENABLE_DEMO=false`; no One-Tap Demo in the binary
- [ ] `strings` / binary scan: no `password123`, no seed persona, no `placeholder.supabase.co`
- [ ] `--obfuscate --split-debug-info=build/symbols` used; symbols archived
- [ ] Upload keystore + `key.properties` backed up offline
- [ ] Gemini/OpenAI keys set as Function secrets; spend cap enabled

**Backend**

- [ ] All migrations applied on the hosted project
- [ ] RLS verified with two real accounts
- [ ] Auth Site URL + `cura://auth-callback`
- [ ] Functions deployed: `health-ai-chat`, `interpret-lab`, `delete-account`
- [ ] Storage buckets private; folder = `auth.uid()`
- [ ] Account deletion removes rows + Auth user
- [ ] Backups / PITR on

**Product honesty**

- [ ] Fresh signup → empty Home, empty Medical ID
- [ ] Deny Health permissions → empty recovery, not fake vitals
- [ ] Grant permissions → real samples labeled HealthKit / Health Connect
- [ ] Lab photo of a real report → structured + disclaimer; garbage image → failure, not fake ALT
- [ ] AI chat uses Edge Function when online
- [ ] SOS opens `tel:`/`sms:` for a user-entered number
- [ ] Directions opens maps; Join Video hidden without `video_url`
- [ ] Community / insurance hidden or clearly non-live
- [ ] Privacy, Terms, delete account reachable from Profile

**Stores**

- [ ] Public Privacy Policy + Terms URLs
- [ ] Play Data Safety + Health Connect declarations
- [ ] App Privacy Nutrition Label + HealthKit notes
- [ ] Phone screenshots (empty + real data)
- [ ] Support email monitored (`support@cura.health` or replacement)
- [ ] Internal testing (Play) + TestFlight on physical devices
- [ ] Medical-device claims absent from listing

**QA matrix (minimum)**

1. Fresh install of the **release** artifact with production env  
2. Sign up / confirm email / sign in / sign out / delete  
3. Health permission deny vs grant  
4. Lab image + PDF upload  
5. AI with and without lab context; airplane mode error UI  
6. SOS on a real device  
7. Offline write then sync  
8. Second device, same account  
9. Hindi toggle smoke  
10. Both Android and iOS  

---

## 9. Repository map

```text
lib/
  main.dart                          App bootstrap, Sentry, deep links, fail-fast
  core/env/app_env.dart              Dart-define config
  core/branding/app_brand.dart       Cura constants
  core/state/app_state.dart          Session + domain state
  core/network/supabase_repository.dart
  core/data/event_store.dart + supabase_sync_service.dart
  core/domains/                      Recovery / baseline / quality
  core/services/                     Auth, lab interpreter, user cache
  features/                          Screens by product area
supabase/
  migrations/                        Postgres + RLS + storage
  functions/                         Deno Edge Functions
  config.toml                        Local stack
env/production.json.example          Placeholder defines
scripts/run_local.sh                 Local Flutter + Supabase
scripts/deploy_cloud_supabase.sh     Cloud migrate + deploy
android/ … ios/ … web/               Platform shells, icons, entitlements
test/                                Domain, network mock, widget tests
```

---

## 10. How to use this file

- **New engineer:** Read §2–§5, then `LAUNCH_SETUP.md`, then run `./scripts/run_local.sh`.
- **Before a store upload:** Walk §8 with the release AAB/IPA, not a debug APK.
- **Before adding a vendor (Fitbit, telehealth, insurance):** Decide hide vs real API; do not extend snackbar theater.
- **When the audit and the app disagree:** Prefer current code + `LAUNCH_SETUP.md`. The 2026-09-16 audit is a snapshot from before the production cutover; many P0 items have since been addressed in source (fail-fast env, Health Connect permissions, Edge Functions, Cura branding, legal screens). Re-scan binaries before each submit.

This process and stack are enough to publish globally **if** store listings, hosted legal URLs, CI, and the honesty checklist above stay aligned with what the binary actually does.
