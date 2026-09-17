# Antigravity Prompt — Bring Health Companion to Full Production Life

> **Paste this entire document into Antigravity (Gemini Flash 3.8 / equivalent) as the master task.**  
> **Companion inputs (read first, do not ignore):**  
> - `PRODUCTION_READINESS_AUDIT.md` — evidence of every hardcoded/dummy/broken path  
> - `APP_FEATURES_WORKFLOWS_AND_UI_SPEC.md` — intended UX (keep UI; replace fake backends)  
> - `env/production.json.example` — secret injection pattern  
> - `supabase/migrations/*.sql` — extend; do not throw away  

---

## 0. ROLE, GOAL, AND HARD RULES

You are a senior Flutter + mobile platform + backend engineer. Your job is to transform **Health Companion** from a demo/prototype into a **store-ready production app** that real people can install from the **Google Play Store** and **Apple App Store**, sign in with real accounts, connect real wearables, upload real lab reports (camera/gallery), get real AI insights, and never see fabricated clinical data.

### Absolute rules
1. **No false data in release builds.** Zero seed personas (Daria Jenkins), zero fake vitals, zero fake labs, zero simulated SOS success, zero snackbar-only “success” for actions that did not happen.
2. **Empty state is correct.** New users see empty dashboards with clear CTAs (“Connect a watch”, “Upload a lab”, “Complete Medical ID”) — never pre-filled demo values.
3. **Demo mode is debug-only.** Gate behind `kDebugMode` or a `demo` flavor. Release flavors must not compile demo password/`signInDemoAccount` into the binary if avoidable; at minimum strip UI and dead-strip seeds with `assert`/`kReleaseMode` guards.
4. **Preserve the existing UI language** (glass, Recovery OS home, tabs). Replace internals; do not redesign unless required for store compliance or accessibility.
5. **Work in phases.** Ship vertical slices that compile and pass tests after each phase. Commit-sized chunks. Do not leave half-migrated `AppState` with both seeds and real paths fighting.
6. **Cite files you change.** Prefer extending existing services (`AuthService`, `WearableService`, `ReportInterpreterService`, `AiCopilotService`, `SupabaseRepository`, `EventStore`) over parallel dead code.
7. **Secrets never in source.** Use `--dart-define-from-file=env/production.json` (and CI secrets). Expand `AppEnv` for every new key. Call `AppEnv.validateRequired()` in release `main()`.
8. **Honesty in product copy.** If a feature cannot ship for v1 (e.g. full insurance adjudication, multi-vendor telehealth), **remove or disable with “Coming in a later version”** — do not fake it.
9. **Regulatory posture:** This is a **wellness / information** app, not a medical device diagnosing disease. Keep disclaimers; never claim “Verified diagnosis”. Lab AI = “patient-friendly explanation to discuss with your clinician”.
10. **Definition of done for this whole program:** A release build with real Supabase auth, empty new-user state, real HealthKit/Health Connect sync, real lab OCR→AI pipeline, real LLM chat, real SOS dial/SMS (with consent), no audit P0 leftovers, and a written store-submission checklist completed.

---

## 1. CURRENT REALITY (DO NOT REDISCOVER — FIX THIS)

From `PRODUCTION_READINESS_AUDIT.md`:

| Area | Today | Must become |
|------|--------|-------------|
| Auth | SharedPreferences + optional Supabase; One-Tap Demo `password123` | Supabase Auth only in release; email/password + (optional) Apple/Google |
| Home / Recovery | Seeded vitals + `seedDemoEvents(14)` | Real `health_events` from watch/phone; empty if none |
| Wearables | Simulated metrics; formulas in `syncVitals()` | HealthKit (iOS) + Health Connect (Android); optional BLE HR |
| Labs | Filename heuristics, fake “Verified” | Camera/gallery → OCR → structured biomarkers → AI summary |
| AI Copilot | Keyword templates + fake latency | Real LLM API via secure backend (Edge Function) |
| SOS | Snackbar “Simulation…” | Real `tel:` / SMS to user-entered contacts |
| Telehealth / Directions | Snackbar only | Real video URL or maps deep link — or remove for v1 |
| Community / Insurance | Hardcoded BlueCross / challenges | Real tables **or** hide from v1 store build |
| Persistence | Many lists never saved | All user data in Supabase (+ local cache) |
| Consent | `ConsentManager.initialize()` never called | Hydrate + map to OS permissions |
| Build | Placeholder Supabase URL, no Dart obfuscation | Real env, `--obfuscate`, AAB + iOS archive |

**Primary god-object to detox:** `lib/core/state/app_state.dart` — remove all seed lists/defaults/`seedDemoEvents`/`signInDemoAccount` from release paths.

---

## 2. TARGET ARCHITECTURE

```
┌──────────────────────────────┐
│ Flutter App (iOS / Android)  │
│  UI → AppState / repositories│
└──────────────┬───────────────┘
               │ HTTPS only
               ▼
┌──────────────────────────────┐
│ Supabase                     │
│  Auth · Postgres · Storage   │
│  Edge Functions (AI, OCR)    │
│  Realtime (optional)         │
└──────────────┬───────────────┘
               │
     ┌─────────┴──────────┐
     ▼                    ▼
 HealthKit /          LLM + OCR
 Health Connect       providers
 (+ BLE GATT HR)      (keys server-side only)
```

### Why not “Bluetooth to any smartwatch”?
Explain this in code comments and in-app Wearables help:

1. **Apple Watch** does **not** expose arbitrary BLE GATT to third-party iOS apps for full health data. The supported path is **HealthKit** (user grants read types). Watch → Health app → your app.
2. **Galaxy Watch / Pixel Watch / many Android wearables** sync into **Health Connect**. Your app reads Health Connect — not each watch’s proprietary BLE protocol.
3. **Generic BLE heart-rate belts / some watches** that implement **Bluetooth SIG Heart Rate Service (UUID 0x180D)** *can* connect via Flutter BLE for HR only.
4. **Fitbit / Garmin / Whoop / Oura** often require **OAuth + vendor cloud APIs**, not raw BLE. For v1, support HealthKit + Health Connect first; add vendor OAuth as Phase 2+.

**v1 wearable strategy (mandatory):** HealthKit + Health Connect as primary.  
**v1 BLE (optional stretch):** Connect standard HR monitors via `flutter_blue_plus` / `ble_peripheral` patterns.  
**Do not** claim “any smartwatch via Bluetooth” in store listing unless you implement vendor integrations.

---

## 3. PHASED IMPLEMENTATION PLAN

Execute in order. After each phase: `flutter analyze`, relevant tests, manual smoke on iOS Simulator + Android device/emulator.

---

### PHASE 0 — Production foundation (P0, 1–2 days)

**Goal:** Release builds cannot run without real config; demo poison removed; empty defaults.

#### 0.1 Environment & fail-fast
- Expand `lib/core/env/app_env.dart`:
  - `SUPABASE_URL`, `SUPABASE_ANON_KEY` (existing)
  - `AI_GATEWAY_URL` or use Supabase Functions URL
  - `SENTRY_DSN` (optional)
  - `ENABLE_DEMO` default `false`; only true in debug defines
- In `main.dart` for **release**:
  ```dart
  if (kReleaseMode) {
    AppEnv.validateRequired();
  }
  ```
- Update `env/production.json.example` with all keys (placeholders only).
- Document build:
  ```bash
  flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
    --dart-define-from-file=env/production.json
  flutter build ipa --release --obfuscate --split-debug-info=build/symbols \
    --dart-define-from-file=env/production.json
  ```

#### 0.2 Kill demo & seeds
In `app_state.dart` and auth UI:
- Remove or `#if`/`kDebugMode`-gate: `signInDemoAccount`, One-Tap Demo button (`sign_in_screen.dart`), `_ensureRichSeedData`, `seedDemoEvents`.
- Replace defaults:
  - `userName` → `''` or `'User'` only when signed in with empty profile — never `'Daria Jenkins'`.
  - All vitals → nullable / `null` meaning “no data yet”.
  - Lists → `[]`.
  - `isWearableConnected = false`, device name empty.
  - `isOnboardingBaselineCompleted = false` for new users.
  - `historicalDaysCount` derived from EventStore, not `14`.
- Delete hardcoded allergies/conditions/meds/claims/challenges/pregnancy/cycle seeds.

#### 0.3 Auth becomes Supabase-first
- Refactor `AuthService` so release path **requires** Supabase session.
- On sign-up: create `auth.users` + `profiles` row (trigger or client upsert).
- On sign-in: load profile; hydrate AppState from Supabase, not seeds.
- Persist session via `supabase_flutter` local storage; remove dual SHA-256 offline accounts from **release** (keep offline only for debug if needed).
- Email confirmation: enable in Supabase dashboard; handle “check your email” UI.
- Optional: `sign_in_with_apple`, Google Sign-In via Supabase providers.

#### 0.4 Onboarding gate
- After first successful signup (or if profile incomplete): force `OnboardingBaselineScreen` before shell.
- Persist height/weight/sex/DOB/goals to `profiles` (+ new columns via migration).

#### 0.5 Quick wins from audit
- Fix Fitness tab overflow (`OVERFLOWED BY 0.911 pixels`) — wrap segment chips in `FittedBox`/`Flexible`/`SingleChildScrollView`.
- Fix clipboard: `Clipboard.setData` in `doctor_questions_modal.dart`.
- Call `consentManager.initialize()` in `AppState.hydrate()`.

**Exit criteria:** Fresh install → Sign up → empty Home with CTAs; no Daria; release without dart-define fails at startup.

---

### PHASE 1 — Supabase data model & sync (P0, 2–4 days)

**Goal:** Every user-owned datum has a table, RLS, and app read/write.

#### 1.1 Extend migrations (new files under `supabase/migrations/`)
Keep existing tables; add:

```text
profiles          — extend: height_cm, weight_kg, sex, dob, onboarding_completed,
                    avatar_url, emergency_notes, blood_type (exists)
medical_id        — allergies[], conditions[], medications_emergency[], blood_type
family_members    — name, relation, permissions jsonb, invite_status, invite_token
appointments      — doctor, clinic, starts_at, location_lat/lng, video_url, status
medications       — name, dose, schedule, is_taken_today
lab_documents     — storage_path, status, ocr_text, structured_json, ai_summary
biomarker_results — document_id, name, value, unit, ref_low, ref_high, flag
journal_entries   — already exists; wire UI
check_ins         — already exists; wire UI
habit_logs        — already exists
nutrition_logs    — meals, hydration_ml, logged_at
cycle_logs        — period days, flow, symptoms
pregnancy_profiles / pregnancy_logs / prenatal_scans
chronic_readings  — glucose, bp_sys, bp_dia, recorded_at
workouts          — type, duration, kcal, hr_avg
challenges        — optional v1.1
claims            — optional defer
consent_settings  — per-user category booleans
wearable_connections — platform, device_display_name, last_sync_at
```

RLS: `user_id = auth.uid()` on all user tables (mirror `20260916000001_row_level_security.sql` patterns).

#### 1.2 Storage buckets
- `lab-uploads` (private): user can upload/read own objects.
- `avatars` (private or public read).
- `exports` for PDF/FHIR.

#### 1.3 Repository layer
- Expand `SupabaseRepository` / add focused repositories.
- Bidirectional sync:
  - Push: local EventStore → `health_events` (already sketched).
  - Pull: `pullRemoteEvents` **must be called** on hydrate and on resume.
- Wire `saveJournalEntry`, `recordCheckIn`, `upsertScore`, `recordHabitLog` from AppState mutations.
- Replace SharedPreferences-as-source-of-truth with: **Supabase primary + local cache** (SharedPreferences/Hive/Isar for offline queue).

#### 1.4 Empty-state UI
Every screen: if list empty → illustration + CTA. Never show seed rows.

**Exit criteria:** Two devices, same account, journal entry created on A appears on B after sync.

---

### PHASE 2 — Real wearables (HealthKit + Health Connect + BLE) (P0, 4–7 days)

**Goal:** Home Recovery scores use real user physiology or show “Insufficient data”.

#### 2.1 Permissions & manifests

**iOS `Info.plist`:**
- `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription` (if write)
- Background modes if needed for updates (careful with review)
- HealthKit capability in Xcode

**Android `AndroidManifest.xml` + Health Connect:**
Declare read permissions used by `health` package, e.g.:
- `android.permission.health.READ_HEART_RATE`
- `READ_RESTING_HEART_RATE`, `READ_HEART_RATE_VARIABILITY`
- `READ_STEPS`, `READ_SLEEP`, `READ_OXYGEN_SATURATION`
- `READ_BLOOD_PRESSURE`, `READ_BLOOD_GLUCOSE` (if used)
- `ACTIVITY_RECOGNITION`, etc. as required by SDK version
- Intent for Health Connect permissions rationale activity
- Follow [Health Connect permissions](https://developer.android.com/health-and-fitness/guides/health-connect) for API 34+

Package already depends on `health: ^13.3.2` — **use it for real**, delete `_generateSimulatedMetrics()` from release paths.

#### 2.2 Rewrite `WearableService`
```text
requestAuthorization()
  → platform HealthKit / Health Connect permission UI
  → return false on deny (show honest UI; do NOT fake success)

fetchLatestVitals() / ingestEvents()
  → read HR, RHR, HRV, steps, sleep stages, SpO2, workouts
  → map to HealthEvent(source: apple_health | health_connect, source_record_id: stable id)
  → NEVER invent values

connectWearable(displayName, source)
  → only after successful auth + at least one successful read OR explicit “linked” state
```

#### 2.3 Fix `AppState.syncVitals()`
- Remove `Future.delayed` fake wait and formula mutations (`restingHeartRate = 70 + steps%4` etc.).
- Flow: authorize if needed → `ingestEvents` → `eventStore.recordEvents` → recalculate recovery from EventStore/baselines → update UI fields **from events** → sync to Supabase.
- Snackbar text must match reality: “Synced N samples from Health Connect” / “No new data” / “Permission denied”.

#### 2.4 Wearables UX sheet
- Show platform-correct instructions:
  - iOS: “Install/open Health; wear Apple Watch; grant Health Companion read access.”
  - Android: “Open Health Connect; allow Health Companion; ensure your watch app syncs to Health Connect (Galaxy Wearable, etc.).”
- List connected sources from Health Connect/HealthKit, not hardcoded “Apple Watch Series 9”.

#### 2.5 Optional BLE module (`lib/features/wearables/ble/`)
Implement for **standard Heart Rate Service**:
1. Add `flutter_blue_plus` (or equivalent maintained package).
2. Permissions: iOS `NSBluetoothAlwaysUsageDescription`; Android `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, location if required by OS version.
3. Scan → filter devices advertising HR service → connect → subscribe to HR measurement characteristic → stream bpm into EventStore as `source: ble_hr`.
4. Handle disconnect, bond failures, and battery.
5. UI: “Add Bluetooth heart rate monitor” separate from Health Connect — do not pretend this equals full Apple Watch sync.

#### 2.6 Recovery engine honesty
- Keep `BaselineEngine` / `RecoveryModel` (they have real tests).
- If `< N` days of data: show **provisional** badge (already in UI tests) — do not invent 14-day history.

**Exit criteria:** Physical Android phone with Health Connect test data (or iPhone + Health) shows non-seed HR/steps; denying permission shows empty/error, not fake 72 bpm.

---

### PHASE 3 — Lab reports: camera → OCR → structure → AI (P0, 4–6 days)

**Goal:** User photographs or picks a lab PDF/image; app extracts text and biomarkers; AI explains in plain language with disclaimer; no “Verified” unless clinician-verified flag exists (default false).

#### 3.1 Capture pipeline
Keep `image_picker` / `file_picker` / camera permissions.
Flow in `UploadReportModal`:
1. Pick camera | gallery | PDF.
2. Upload bytes to Supabase Storage `lab-uploads/{user_id}/{uuid}`.
3. Insert `lab_documents` row `status=uploaded`.
4. Invoke Edge Function `interpret-lab`.

#### 3.2 Edge Function `interpret-lab` (server-side secrets)
Pseudo-pipeline:
1. Download file from Storage (service role).
2. **OCR:**
   - Images: Google Cloud Vision / AWS Textract / Azure Document Intelligence / Apple Vision **via server**, or on-device ML Kit as optimization.
   - PDFs: extract text layer first; if scanned PDF, rasterize pages then OCR.
3. **Structure:** LLM with JSON schema prompt:
   ```json
   {
     "tests": [{"name":"ALT","value":48,"unit":"U/L","ref_low":7,"ref_high":35,"flag":"high"}],
     "collection_date": "ISO-8601|null",
     "lab_name": "string|null",
     "confidence": 0.0-1.0
   }
   ```
4. Persist `ocr_text`, `structured_json`, biomarker rows.
5. Generate `ai_summary` + `doctor_questions` with strict system prompt: non-diagnostic, urge clinician review.
6. Return to app; UI shows confidence + disclaimer. **Never** show green “Verified” unless `clinician_verified=true`.

#### 3.3 Replace `ReportInterpreterService` heuristics
- Client becomes thin: upload + poll/subscribe status.
- Delete filename-based canned ALT stories from release.

#### 3.4 Doctor questions
- From AI output; Copy uses real clipboard (Phase 0).

**Exit criteria:** Photo of a sample CMP (test fixture) produces structured ALT and a summary; random photo of a cat produces low-confidence / failure UI, not fake labs.

---

### PHASE 4 — Real AI Copilot (P0, 2–4 days)

**Goal:** `AiChatSheet` talks to a real model with user context, safely.

#### 4.1 Backend-only API keys
- Supabase Edge Function `health-ai-chat`.
- Provider options (pick one, document in README): OpenAI / Anthropic / Google Gemini / Groq via Vercel AI Gateway.
- App sends: user message + **authorized context bundle** (recent scores, labs summary, meds names — only if consent allows).
- System prompt: wellness coach; refuse emergencies (“call local emergency services”); no dosing changes; cite that labs are informational.

#### 4.2 Client changes
- Replace `AiCopilotService` keyword router with repository calling Edge Function.
- Streaming optional (SSE/websocket).
- Remove fake `Future.delayed(600ms)` as the only “thinking”; show real network states.
- Mic: wire `speech_to_text` **or** hide mic button until ready.

#### 4.3 Safety & cost
- Rate limit per user in Edge Function.
- Log prompts server-side without storing unnecessary PHI longer than policy.
- Redact if needed.

**Exit criteria:** Ask “What does high ALT mean?” with a real uploaded lab → contextual answer; with no labs → asks user to upload; offline → error UI.

---

### PHASE 5 — Make remaining features real or remove for v1 (P0–P1)

Apply the audit table ruthlessly.

| Feature | v1 production decision |
|---------|------------------------|
| Journal / mood | Persist + Supabase `journal_entries`; real STT or hide voice |
| Triage | Keep rule engine **or** AI-assisted with strong emergency disclaimer; persist `check_ins`; audio toggle real or remove |
| Appointments | CRUD in Supabase; **Get Directions** via `url_launcher` maps query; **Join Video** only if `video_url` set — else hide button |
| Book appointment | User-entered clinician OR defer provider marketplace to v1.1 (remove hardcoded doctors) |
| Family | Invite via email magic link + QR token table; permissions stored server-side; remove “demo purposes” copy |
| Nutrition / hydration | Persist `nutrition_logs` |
| Women’s health / pregnancy | Persist; empty defaults; extra sensitivity copy for pregnancy |
| Chronic care | Persist readings; validate numbers; charts from real series |
| Emergency Medical ID | User-edited only; SOS: `url_launcher` `tel:` + SMS (`telephony`/`flutter_sms` with permissions) to contacts **user added**; remove simulation snackbar; fall detection: use platform APIs if available or label “experimental” / remove |
| Data portability | Wire FHIR JSON export button; PDF from real data only |
| Community challenges | Implement Supabase tables **or hide entry points in v1** |
| Insurance claims | **Hide in v1** unless you have a real partner API — do not ship fake BlueCross |
| Weather on home | Real weather API by lat/lon **or remove** |
| Analytics | Sentry + privacy-safe product analytics (PostHog/Amplitude) with consent |

**Exit criteria:** No snackbar claims success for no-ops; no insurance/community fake data visible in release.

---

### PHASE 6 — Security, privacy, store compliance (P0, ongoing)

#### 6.1 Security
- Obfuscate Dart; keep symbols private.
- Certificate pinning optional later.
- Encrypt sensitive local caches if retained (e.g. `flutter_secure_storage` for tokens — Supabase handles session).
- RLS verified with automated tests against real project (service role vs user JWT).
- No PHI in crash logs.

#### 6.2 Privacy artifacts (required for stores)
Create/update:
- Privacy Policy URL (hosted)
- Terms of Use
- In-app consent for health data + AI processing
- Data deletion: Settings → Delete account (Supabase admin/Edge Function deletes storage + rows)
- Account export: FHIR/PDF already planned

#### 6.3 Play Store
- App signing by Play / upload key
- `flutter build appbundle`
- Data safety form: health info collected, shared with Supabase/LLM processor, encrypted in transit
- Health Connect declaration if using health permissions
- Photos/Camera permissions justified
- Target API level per current Play policy
- Content rating questionnaire

#### 6.4 App Store
- HealthKit entitlement review notes (“read HR/HRV/sleep/steps to compute recovery scores; not for diagnosis”)
- Sign in with Apple if you offer other third-party social login
- App Privacy “Nutrition Label”
- Export compliance / encryption answers
- Reviewer notes + demo account **only if Apple asks** — prefer reviewer sandbox with empty data + TestFlight notes explaining Health grant steps

#### 6.5 Clinical / legal copy
- Every AI and lab screen: “Not a diagnosis. Not emergency care.”
- SOS: confirm dialog before calling.

---

### PHASE 7 — QA, tests, launch checklist

#### 7.1 Tests to add/replace
- Remove/alter tests that assume Daria seeds if they encode demo as truth.
- Integration tests: auth signup, empty home, lab upload mock Edge Function, wearable ingest with fake Health plugin.
- Golden tests may need empty-state baselines.

#### 7.2 Manual QA matrix
1. Fresh install release build with real env  
2. Sign up / sign in / sign out / delete account  
3. Deny health permissions → empty recovery  
4. Grant permissions → sync real samples  
5. BLE HR belt (if implemented)  
6. Upload lab photo + PDF  
7. AI chat with and without context  
8. SOS calls correct number on device  
9. Family invite accept on second account  
10. Offline: queue writes; sync on reconnect  
11. Both platforms

#### 7.3 Launch checklist (tick before submit)
- [ ] No demo button in release  
- [ ] `strings` on AAB/IPA has no `password123` / Daria seed  
- [ ] Privacy policy + support URL live  
- [ ] Screenshots from real empty + populated states (not fake BlueCross)  
- [ ] Crash-free on 10-device internal test  
- [ ] Supabase backups + RLS audit  
- [ ] LLM spend alerts  
- [ ] Store listings localized if needed  

---

## 4. DETAILED IMPLEMENTATION GUIDES (COPY-LEVEL)

### 4.1 Real auth login screen
1. Remove One-Tap Demo from release UI.
2. Fields: email, password, forgot password (`supabase.auth.resetPasswordForEmail`), create account.
3. Errors: map Supabase error codes to human text.
4. On success: `hydrateFromRemote(userId)` loading profile, events, journals — show splash/skeleton until done.
5. Optional social buttons wired to Supabase OAuth redirect / iOS URL schemes.

### 4.2 Smartwatch / phone health integration (primary path)

**User journey (Android example):**
1. User installs Galaxy Wearable (or Google Watch app) and syncs watch → Health Connect.
2. In Health Companion → Connect wearable → system Health Connect permission screen.
3. App reads last 7–30 days of HRV/RHR/steps/sleep.
4. Events stored locally + upserted to `health_events`.
5. Recovery model computes score; Home updates.
6. Pull-to-refresh / periodic sync (Workmanager / background fetch — respect OS limits).

**User journey (iOS):**
1. Apple Watch paired; data in Apple Health.
2. Health Companion requests HealthKit read types.
3. Same event pipeline with `source=apple_healthkit`.

**Code touchpoints:**
- `lib/features/wearables/services/wearable_service.dart` — rewrite
- `lib/features/wearables/widgets/wearable_permissions_sheet.dart` — honest UX
- `lib/core/state/app_state.dart` `syncVitals` — no formulas
- AndroidManifest + Info.plist permissions
- Consent categories gate which metrics are read

### 4.3 Bluetooth (secondary path — standard HR)

Implement a dedicated screen “Bluetooth heart rate monitor”:
1. Request BT permissions.
2. Scan 10s for devices with service `180d`.
3. Show list (name + RSSI).
4. On connect, parse HR measurement characteristic (see Bluetooth SIG HR profile).
5. Write `HealthEvent(metric: 'hr', source: 'ble_hr', ...)`.
6. Persist connection preference (device id) for autoconnect.

Document limitations in UI: “Full Apple Watch / Galaxy metrics use Health permissions above — Bluetooth is for compatible HR straps and watches that expose standard HR service.”

### 4.4 Lab camera → understanding pipeline
1. UI already has camera/gallery — keep.
2. Show real progress stages bound to backend job status: `uploaded → ocr → structuring → summarizing → ready | failed`.
3. Display extracted table editable by user (correct OCR mistakes) before saving final.
4. Link AI chat context to selected document id.

### 4.5 AI insights
1. Edge Function holds provider key.
2. Context builder in Dart: serialize last recovery drivers, latest lab summary, meds — respect consent flags.
3. Store chat threads in `ai_messages` table (optional) for history.
4. Streaming UX preferred.

### 4.6 Emergency SOS (real)
1. User must add ≥1 contact with phone number in Medical ID.
2. Long-press SOS → countdown (keep) → on complete:
   - `launchUrl(Uri.parse('tel:$number'))` and/or SMS with GPS link if location permission granted.
3. Never say “dispatched” unless a real emergency API is integrated (those are region-specific and regulated — **do not fake**).

---

## 5. FILE-BY-FILE HIT LIST (START HERE)

| File | Action |
|------|--------|
| `lib/core/state/app_state.dart` | Remove seeds/demo; nullable vitals; wire repositories |
| `lib/core/services/auth_service.dart` | Supabase-only release auth |
| `lib/core/env/app_env.dart` | Expand + validateRequired in main |
| `lib/main.dart` | Fail-fast; onboarding gate; no demo |
| `lib/features/auth/screens/sign_in_screen.dart` | Remove demo CTA in release |
| `lib/features/wearables/services/wearable_service.dart` | Real Health + optional BLE |
| `lib/core/services/report_interpreter_service.dart` | Client for Edge OCR/AI |
| `lib/features/ai_assistant/services/ai_copilot_service.dart` | Edge LLM client |
| `lib/core/network/supabase_repository.dart` | Full CRUD + pull |
| `lib/core/data/supabase_sync_service.dart` | Bidirectional |
| `lib/features/emergency/screens/emergency_safety_screen.dart` | Real tel/SMS |
| `lib/features/appointments/screens/appointments_screen.dart` | Maps/video real or hide |
| `lib/features/insurance/*` | Hide or real API |
| `lib/features/community/*` | Hide or real API |
| `android/app/src/main/AndroidManifest.xml` | Health Connect + BT perms |
| `ios/Runner/Info.plist` | HealthKit + BT usage strings |
| `supabase/migrations/*` | New tables + RLS |
| `supabase/functions/*` | `interpret-lab`, `health-ai-chat`, `delete-account` |
| `test/*` | Update for empty defaults; add integration |

---

## 6. SUGGESTED v1 SCOPE vs DEFER

**Must ship (store v1):** Auth, onboarding, empty-safe Recovery Home, HealthKit/Health Connect sync, journal, lab upload+OCR+AI summary, AI chat, Medical ID + real SOS call, appointments CRUD + directions, family invite basic, data export PDF, privacy/delete account, consent center.

**Defer (hide entry points):** Insurance adjudication, community challenges social graph, marketplace doctor booking, full telehealth SDK, multi-vendor OAuth (Fitbit/Garmin), fall detection ML.

---

## 7. HOW YOU SHOULD WORK IN ANTIGRAVITY

1. Read `PRODUCTION_READINESS_AUDIT.md` end-to-end.  
2. Create a working branch / checklist from Phases 0→7.  
3. Implement Phase 0 completely before wearables/AI.  
4. After each phase, run analyzer + tests; fix overflow and regressions.  
5. Do not leave dual code paths where release still seeds Daria “just in case”.  
6. When uncertain (e.g. telehealth), **hide the control** rather than shipping a snackbar lie.  
7. Produce a final `LAUNCH_READINESS.md` with store form answers, env vars, and QA evidence.

---

## 8. SUCCESS METRIC

A stranger installs the app from TestFlight/Internal Testing:
- Creates their own account (not Daria).
- Sees empty Recovery until they connect Health / watch.
- Syncs real steps/HR.
- Photographs a lab report and gets a structured, disclaimer-heavy explanation.
- Asks the AI a question grounded in their data.
- Can dial an emergency contact they entered.
- Finds **no** fabricated claims, BlueCross cards, or “Simulation: SOS dispatched”.

When that is true, and Play/App Store listings + privacy policy match actual behavior, the app is ready to submit.

---

*End of Antigravity production-launch prompt. Execute phases in order. Prefer honest incomplete features over polished fakes.*
