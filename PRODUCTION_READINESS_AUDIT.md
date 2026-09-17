# Production Readiness Audit — Health Companion — 2026-09-16

## Executive Summary

- **Overall assessment:** Health Companion is a polished interactive prototype / Recovery OS demo, not a production clinical app. Most screens render and accept local interactions, but identity, vitals, labs, AI, telehealth, SOS, insurance, community, and much of “wearable sync” are seeded, heuristic, or snackbar-only. Supabase is wired in code but optional and unused at fail-fast; the audited release APK and live web run both operate offline/local-only (or against `https://placeholder.supabase.co`). Shipping this to real users as-is would present false medical identity, simulated emergency SOS, fake lab “Verified” interpretation, and a hardcoded demo password in the binary.
- **Top 5 blockers:**
  1. Demo persona + seed clinical data (Daria Jenkins vitals, Medical ID, labs, family) load as if real (`app_state.dart`).
  2. Release APK embeds `password123` and “One-Tap Demo (Daria Jenkins)” with no Dart obfuscation.
  3. Emergency SOS and telehealth/directions/clipboard actions are simulations or snackbars only.
  4. Lab “interpretation” and Health AI are filename heuristics / keyword rules, not OCR/LLM — marketed as clinical features.
  5. Supabase is not required at startup (`AppEnv.validateRequired` never called); production can silently run local-only.
- **Rough split:** **1** fully functional (splash gate), **16** partial, **1** UI-only/mock (community), **6+** dummy CTAs, **1** broken layout (Fitness tab overflow), **0** truly end-to-end production-backed clinical features.

**Runtime verification note:** No Android emulator/device was available at audit start. System image install was still incomplete during this pass. The release APK was fully inspected (badging, signing, strings, R8 mapping, size). The same `lib/` codebase was exercised live via `flutter run -d chrome` (console: `[SupabaseRepository] Running in offline/local-only mode`). Findings below cite both source and runtime evidence where applicable.

---

## 1. Feature-by-Feature Inventory

| Screen / Feature | Status | Backend target | Evidence (file:line) | What's hardcoded/mocked | What's needed for production | Priority |
|---|---|---|---|---|---|---|
| SplashScreen | ✅ Fully functional | none | `splash_screen.dart:55-60`; `main.dart:83-93` | Marketing copy “Preparing daily telemetry…” | None for gate | P2 |
| SignInScreen | ⚠️ Partially functional | SharedPreferences + optional Supabase Auth | `sign_in_screen.dart:62-71,169-196`; `auth_service.dart:128-180` | One-Tap Demo button ships in UI | Remove demo from release; enforce remote auth | P0 |
| SignUpScreen | ⚠️ Partially functional | SharedPreferences + optional Supabase | `sign_up_screen.dart:43-54`; `auth_service.dart:68-126` | Offline fallback on remote signup failure | Fail closed when Supabase required; persist remote session user | P0 |
| Demo one-tap (Daria) | ❌ Dummy / non-functional (as product auth) | Local seed | `app_state.dart:489-517`; password `password123` at `:503` | Full demo account + rich seed | Strip from release builds | P0 |
| HomeScreen / Recovery OS | ⚠️ Partially functional | In-memory seed + EventStore demo events + local recovery math | `home_screen.dart`; `app_state.dart:54-100,438-440,954-1024,1142-1161`; runtime: demo home shows Daria / 75→52 recovery | Default vitals, stress highs/lows, weather copy, seed events | Empty real-user state; real wearable ingest; no seed | P0 |
| Home activity pill | ❌ Dummy | none | `home_screen.dart:794-803` | SnackBar claims Apple Health tracking | Wire Health Connect or hide | P1 |
| JournalFeelingScreen | ⚠️ Partially functional | In-memory (list not persisted) | `journal_feeling_screen.dart`; `app_state.dart:127-161,741-759` | Seed journal entries; static correlations | Persist journal; sync to Supabase `journal_entries` | P1 |
| JournalEntrySheet | ⚠️ Partially functional | In-memory | `journal_entry_sheet.dart:97-100,124-132` | “Voice” injects canned text | Real audio transcription or honest disable | P1 |
| TriageScreen | ⚠️ Partially functional | none (rule-based local) | `triage_screen.dart:31`; `app_state.dart:1264-1326` | Keyword urgency templates; audio toggle UI-only | Clinical protocol + disclaimers; persist check-ins | P1 |
| AppointmentsScreen | ⚠️ Partially functional | SharedPreferences (appts/family) | `appointments_screen.dart`; `app_state.dart:1181+` | Seed Dr. Priya visit | Scheduling backend | P1 |
| Join Video Call | ❌ Dummy | none | `appointments_screen.dart:573-581` | SnackBar only | Telehealth SDK/URL or remove | P0 |
| Get Directions | ❌ Dummy | none | `appointments_screen.dart:597-605` | SnackBar only | Maps deep link or remove | P1 |
| BookAppointmentModal | 🔶 UI-only / hardcoded data | Local Appointment object | `book_appointment_modal.dart:32-85` | Hardcoded doctors/slots; synthetic datetime | Real provider directory + booking API | P1 |
| FamilyMemberModal | ⚠️ Partially functional | SharedPreferences | family modal + `addFamilyMember` | Local only | Invite/backend sharing | P1 |
| TodaysMovementPanel | ⚠️ Partially functional | In-memory workouts | `todays_movement_panel.dart`; `app_state.dart:262-324` | Exercise library + kcal estimates | Persist workouts; optional fitness API | P2 |
| Appointments tab chrome | 🐛 Broken | n/a | Runtime screenshot Fitness tab: **OVERFLOWED BY 0.911 pixels** on Movement/Upcoming/Family row | Layout overflow on ~390px width | Fix Row/Tab constraints | P1 |
| LabReportsScreen | ⚠️ Partially functional | Local files + SharedPreferences metadata | `lab_reports_screen.dart`; seed CMP `app_state.dart:591-688` | Seed “Verified” ALT narrative | Real OCR/parser; no false Verified | P0 |
| UploadReportModal | ⚠️ Partially functional | Local FS + heuristics | `upload_report_modal.dart:167-187`; `report_interpreter_service.dart:50-120` | Fake progress delays; canned summaries by filename | Real document pipeline | P0 |
| DoctorQuestionsModal “Copy” | ❌ Dummy | none | `doctor_questions_modal.dart:130-139` | Success snackbar **without** `Clipboard.setData` | Call Clipboard API | P1 |
| AiChatSheet / Omni AI | ⚠️ Partially functional | none (local keyword router) | `ai_copilot_service.dart:51+`; `ai_chat_sheet.dart:106-111` | Artificial 600ms delay; template replies; mic canned ALT query | Real LLM + safety layer or relabel as FAQ | P0 |
| PermissionCenter / Consent | ⚠️ Partially functional | SharedPreferences intended but not hydrated | `consent_manager.dart:68-195`; `permission_center_screen.dart:270-271` | Defaults all-on; `initialize()` never called from hydrate | Call initialize; real OS permission bridge | P1 |
| FamilyConnectScreen | ⚠️ Partially functional | SharedPreferences | `family_connect_screen.dart`; seed `:632-658` | “for demo purposes” copy `:563`; snackbar Manage/QR/Resend | Real invites/QR/grants | P1 |
| NutritionHydrationScreen | ⚠️ Partially functional | In-memory (not in persist map) | `nutrition_hydration_screen.dart`; `app_state.dart:103-124` | Seed meals/hydration | Persist + optional nutrition DB | P1 |
| WomensHealthScreen | ⚠️ Partially functional | In-memory | `womens_health_screen.dart`; `app_state.dart:163-196` | Seed cycle day/phase/logs | Persist; empty defaults | P1 |
| PregnancyDashboardScreen | ⚠️ Partially functional | In-memory | pregnancy screen; `app_state.dart:198-253` | Seed due date, kicks, prenatal findings | Persist; clinical caution | P0 |
| PeriodLogModal | ⚠️ Partially functional | In-memory | `period_log_modal.dart:50` | Local only | Persist | P1 |
| ChronicCareScreen | ⚠️ Partially functional | In-memory histories | `chronic_care_screen.dart`; `app_state.dart:333-346,1376-1399` | Seed glucose/BP series | Persist histories; validate inputs | P1 |
| CommunityChallengesScreen | 🔶 UI-only / hardcoded data | none | `community_challenges_screen.dart:78+`; `joinChallenge` no-op `app_state.dart:1413-1415` | Seed challenges naming Daria/Elena/Jordan | Backend challenges or remove | P1 |
| InsuranceClaimsScreen | ⚠️ Partially functional | In-memory | `insurance_claims_screen.dart:147-347`; `app_state.dart:392-413` | BlueCross card, member ID, local 80/20 math | Real payer integration or clearly demo | P0 |
| EmergencySafetyScreen | ⚠️ Partially functional / simulated | Local toggles | `emergency_safety_screen.dart:290-308`; allergies `app_state.dart:416-419` | SOS snackbar: “Simulation: … Elena Jenkins!” | Real emergency contacts dial/SMS; empty Medical ID | P0 |
| DataPortabilityScreen | ⚠️ Partially functional | Local PDF from AppState | `data_portability_screen.dart:106-214`; `data_export_service.dart:14,156-337` | FHIR `generateFhirBundle` never called from UI; PDF status columns canned | Wire FHIR export; accurate status | P1 |
| OnboardingBaselineScreen | ⚠️ Partially functional | In-memory; skipped by default | `onboarding_baseline_screen.dart:62-74`; `app_state.dart:1120-1129` | `isOnboardingBaselineCompleted` defaults true; not in signup flow | Force onboarding for new users; persist | P1 |
| WearablePermissionsSheet | ⚠️ Partially functional | Simulated ingest | `wearable_permissions_sheet.dart:123-128`; `wearable_service.dart:28-212` | Always connects “Apple Watch Series 9”; simulated metrics | Real Health Connect reads; Android permissions | P0 |
| Wearable syncVitals | 🔶 UI-only / hardcoded data | Formula overwrite | `app_state.dart:1142-1157`; runtime snackbar “Vitals synchronized with Apple Health data.” | Mutates HR/steps/sleep with formulas after delay | Use `fetchLatestVitals` / ingest results | P0 |
| AuthService | ⚠️ Partially functional | SharedPreferences SHA-256; optional Supabase | `auth_service.dart:17-180` | Offline-first; remote session may lack local UserAccount | Harden session binding | P0 |
| SupabaseRepository / sync | ⚠️ Partially functional | Supabase if dart-define set; else none | `supabase_repository.dart:97-100`; `supabase_sync_service.dart:25-52`; `app_env.dart:20-27` unused | `pullRemoteEvents` / journal/score APIs unused by app | Require env in release; bidirectional sync | P0 |
| AnalyticsService | 🔶 UI-only | In-memory / debugPrint | `analytics_service.dart:47-77` | No production sink | Wire analytics vendor or strip claims | P2 |
| QuickActionSheet | ⚠️ Partially functional | Navigation only | `quick_action_sheet.dart` | N/A | Ensure targets are production-ready | P2 |
| Floating bottom nav / shell | ⚠️ Partially functional | Local tab index | `main.dart:110-149` | Triage tab index 2 hidden from dock | Expose or remove dead tab | P2 |

---

## 2. Hardcoded Data Inventory

| Item | Evidence | Should come from |
|---|---|---|
| Default display name `"Daria Jenkins"` / `"Daria"` | `app_state.dart:42-46` | Signed-in user profile only (empty if none) |
| Default vitals (HR 72, steps 8420, SpO2 98, Apple Watch Series 9, etc.) | `app_state.dart:54-100` | Wearables / user entry; start empty |
| `historicalDaysCount = 14` “Daria demo” | `app_state.dart:94` | Actual EventStore history length |
| Seed meals (salmon bowl, yogurt) | `app_state.dart:105-124` | User nutrition logs |
| Seed journal entries | `app_state.dart:127-161` | User journal |
| Seed menstrual cycle / pregnancy / prenatal findings | `app_state.dart:163-253` | User reproductive health data |
| Seed workouts | `app_state.dart:262-281` | User fitness logs |
| Seed glucose/BP histories | `app_state.dart:335-346` | Chronic-care logs |
| Seed preventive reminders | `app_state.dart:349-366` | Care guidelines + user plan |
| Seed community challenges + names | `app_state.dart:372-389` | Community backend |
| Seed insurance claims / BlueCross UI | `app_state.dart:392-413`; `insurance_claims_screen.dart:147-195` | Payer APIs |
| Seed allergies / conditions / emergency meds | `app_state.dart:416-419` | User Medical ID (empty until entered) |
| `seedDemoEvents(days: 14)` on every `AppState()` | `app_state.dart:438-440,1032-1058` | Real HealthKit/Connect events only |
| Demo email/password | `app_state.dart:494-504` | Remove from release |
| Hardcoded doctors/slots | `book_appointment_modal.dart:32-58` | Provider directory |
| Stress sparkline heights | `home_screen.dart:1004-1007` | Real stress series or remove |
| Weather “30 °C / Hot & Sunny” | `home_screen.dart:853-888` | Weather API or remove |
| Lab interpretation templates | `report_interpreter_service.dart:73-99` | OCR/LLM pipeline |
| AI reply templates | `ai_copilot_service.dart:51+` | LLM service |
| Simulated wearable metrics | `wearable_service.dart:113-120` | Device APIs |
| Journal voice canned text | `journal_entry_sheet.dart:97-100` | Speech-to-text |
| Pending invite “Robert Jenkins” UI | `family_connect_screen.dart:470-517` | Invite backend |
| `https://placeholder.supabase.co` in release APK strings | APK `strings` extraction | Real project URL via dart-define, or empty+fail-fast |

---

## 3. Dummy / Non-Functional Features

| Feature | Evidence | “Done” looks like |
|---|---|---|
| One-Tap Demo in production UI | `sign_in_screen.dart:169-196` | Removed behind `kDebugMode` / flavor |
| Join Video Call | `appointments_screen.dart:573-581` | Opens real telehealth session |
| Get Directions | `appointments_screen.dart:597-605` | Opens maps with clinic coords |
| Copy questions to clipboard | `doctor_questions_modal.dart:130-139` | `Clipboard.setData` then snackbar |
| Manage record grants | `family_connect_screen.dart:333-341` | Permission editor backed by server |
| Share via QR | `family_connect_screen.dart:438-446` | QR with signed invite token |
| Resend invite | `family_connect_screen.dart:523-527` | Email/SMS/push invite |
| Activity pill “Apple Health” | `home_screen.dart:794-803` | Opens Health Connect / settings |
| Emergency SOS | `emergency_safety_screen.dart:305-307` | Real call/SMS to contacts (with consent) |
| `joinChallenge` | `app_state.dart:1413-1415` | Mutates membership + backend |
| FHIR export button path | `generateFhirBundle` only at `data_export_service.dart:14` — zero UI call sites | Export/share FHIR JSON from Data Portability |
| Mic in AI sheet | `ai_chat_sheet.dart:332-336` | Real STT or disable |

---

## 4. Broken Flows

| Issue | Reproduction | Evidence |
|---|---|---|
| Fitness/Appointments segment row overflow | Sign in (demo) → Fitness tab on ~390×844 | Runtime: yellow/black **OVERFLOWED BY 0.911 pixels** between Movement / Upcoming Visits / Family |
| “Sync wearable” claims Apple Health success without real vitals | Home → Sync wearable | Runtime snackbar “Vitals synchronized with Apple Health data.”; code overwrites with formulas `app_state.dart:1145-1157` |
| Clipboard copy lies | Labs → doctor questions → Copy | Snackbar success; no `Clipboard.setData` (`doctor_questions_modal.dart:130-139`) |
| Consent prefs never load | Cold start → Permission Center | `ConsentManager.initialize()` never called (only definition); defaults reset |
| Remote auth session without local profile | Supabase sign-in path without prefs user | `auth_service.dart:147-161` vs `getSessionUser` `:47-55` |
| New users still see Daria defaults until overwritten | Register without clearing seeds | Constructor `seedDemoEvents` + field defaults `app_state.dart:42-100,438-440` |

---

## 5. Security & Secrets Findings

| Finding | Evidence | Severity |
|---|---|---|
| Demo password `password123` in release APK plaintext strings | `strings app-release.apk` contains `password123`; source `app_state.dart:503` | **P0** |
| Demo email / One-Tap Demo strings in APK | APK strings: `daria.jenkins@icloud.com`, `One-Tap Demo (Daria Jenkins)` | **P0** |
| Dart not obfuscated (`--obfuscate` not used) | Readable symbols in APK: `SignInScreen`, `AppState`, `seedDemoEvents` | **P1** |
| Placeholder Supabase URL baked into APK | `https://placeholder.supabase.co` (+ `/auth/v1`, `/rest/v1`, …) in APK strings | **P1** (misconfig; no live anon JWT found in strings) |
| `AppEnv.validateRequired()` never called | `app_env.dart:20-27`; only definition hit in repo | **P0** |
| Auth secrets stored as SHA-256 hashes in SharedPreferences (not encrypted at rest beyond OS) | `auth_service.dart` + `shared_preferences` | **P1** for health app |
| AndroidManifest lacks Health Connect / body sensors permissions despite `health` package | `android/app/src/main/AndroidManifest.xml` only INTERNET/CAMERA/media | **P1** |
| Cleartext HTTP disabled (good) | Manifest `usesCleartextTraffic="false"` | Positive |
| No committed live API keys in source | `env/production.json.example` placeholders only | Positive |
| Release APK signed as `CN=RecoveryOS, O=HealthCompanion` (not debug CN) | `apksigner verify --print-certs` | Positive for this artifact; `key.properties` not in repo (gitignored / absent now) |
| Medical ID / pregnancy / allergies seeded as if real | `app_state.dart:198-253,416-419` | **P0** clinical honesty / safety |

---

## 6. Performance & Stability Findings

| Finding | Evidence |
|---|---|
| Artificial delays (`Future.delayed`) for sync/AI/OCR UX | `app_state.dart:1145`; `ai_chat_sheet.dart:107`; `upload_report_modal.dart:167,187` |
| `firstWhere` without `orElse` on meds/family updates | `app_state.dart:1165`, `:1207` — crash if id missing |
| Seed + EventStore work on every cold start | `AppState()` ctor `seedDemoEvents` |
| Release APK **~58 MB** compressed; **~117 MB** uncompressed listing; ships **3 ABIs** (`arm64-v8a`, `armeabi-v7a`, `x86_64`) | `unzip -l` / `du` — consider ABI splits / App Bundle |
| R8 enabled for Android Java/Kotlin (Flutter Gradle sets release minify) | `mapping/release/mapping.txt` present (R8 9.0.32); FlutterPlugin sets `isMinifyEnabled = true` for release |
| Dart AOT not obfuscated | Contrast with R8: Dart symbols/strings remain readable in `libapp.so` |
| Layout overflow on Fitness tabs | Runtime overflow 0.911px |
| Analytics listeners in-memory only | Low leak risk; no dispose sink needed |
| SOS Timer in dialog | Minor dispose risk if route pops mid-countdown (`emergency_safety_screen.dart:290-312`) |

---

## 7. Backend Integration Status

```
┌─────────────────────────────────────────────────────────────────┐
│ Runtime observed (web): offline/local-only — missing credentials │
│ Release APK strings: placeholder.supabase.co (+ demo password)   │
└─────────────────────────────────────────────────────────────────┘

Legacy local server:     NOT USED in Dart (no localhost in lib/)
Mock / in-memory seed:   Home vitals, journal, nutrition, women's,
                         pregnancy, chronic, community, insurance,
                         emergency Medical ID, AI, lab interpretation,
                         wearable ingest formulas, triage rules
SharedPreferences:       Auth accounts, session, appointments, family,
                         meds, prescriptions metadata, subset of vitals
Supabase (optional):     Schema+RLS in supabase/migrations/*;
                         Auth signup/signin attempted if configured;
                         EventStore push via SupabaseSyncService;
                         pullRemoteEvents / journal/score/habit APIs
                         not wired from UI
None:                    Splash, many snackbar CTAs, community join
```

Per-screen backend is summarized in §1 “Backend target” column.

Migration status: **Supabase scaffolding has landed** (repository, sync service, SQL migrations) but **product features still run primarily on local seed + SharedPreferences**. Not a completed cutover.

---

## 8. Build Artifact Findings

| Check | Result |
|---|---|
| Artifact | `build/app/outputs/flutter-apk/app-release.apk` |
| Built | 2026-09-16 05:06 local time (debug APK earlier 01:46) |
| Type | **Release** APK (`aapt dump badging`) |
| Package | `com.healthcompanion.health_companion` |
| versionName / versionCode | **1.0.0 / 1** — matches `pubspec.yaml` `1.0.0+1` |
| minSdk / targetSdk | 26 / 36 |
| Size | **~58 MB** on disk; multi-ABI native libs dominate |
| R8 / shrinking | **Enabled** for Android layer (mapping.txt ~11M lines of mappings); app `build.gradle.kts` does not set minify explicitly — Flutter Gradle enables it for release |
| Dart obfuscation | **Not enabled** — demo strings & symbols readable |
| Leaked strings | `password123`, Daria demo copy, `https://placeholder.supabase.co/*` |
| Live secrets | No `eyJ…` JWT / `sk-` / Google `AIza` keys found in APK strings scan |
| Signing | Custom release cert `CN=RecoveryOS, OU=Mobile, O=HealthCompanion, L=Bangalore…` |
| APK install runtime | **Not completed** — no device/AVD ready; system-image download still in progress during audit. Equivalent UI/flows validated on Flutter web against same sources. |

---

## 9. Test Coverage Summary

| Suite | Result (this audit) | What it validates |
|---|---|---|
| `flutter test` | **42 passed** | Domain math, EventStore, in-memory Supabase mock, AppState basics, AI keyword stubs, auth widgets, visual verification |
| `test/domains/*` | Real logic | Baseline/recovery engines — strongest production-relevant tests |
| `test/network/supabase_repository_test.dart` | In-memory mock backend | Sync dedupe / offline — **does not** hit real Supabase |
| `test/ai_copilot_service_test.dart` | Stub AI | Would still pass if “AI” stayed keyword-only |
| `test/visual_verification_test.dart` | UI screenshots | Does not assert backend truthfulness |
| Feature screens (insurance, SOS, QR, video, clipboard, wearables simulation) | **Largely untested** | Gaps |
| iOS `RunnerTests.swift` | Empty placeholder | No coverage |

**Verdict:** Automated tests are useful for Recovery OS math and basic auth navigation, but they **do not** prove production clinical integrations. Several tests encode the demo/stub architecture as expected behavior.

---

## 10. Prioritized Path to Production

### P0 — Blocks release
1. **Remove demo mode from release** — gate `signInDemoAccount`, seed constructor data, and default Daria identity behind debug/flavor; scrub `password123` from binaries.
2. **Fail-fast on missing Supabase in release** — call `AppEnv.validateRequired()` (or equivalent) from `main()` for production flavors; stop shipping `placeholder.supabase.co`.
3. **Empty clinical defaults** — new accounts must start with empty Medical ID, vitals, pregnancy, labs, insurance; never seed allergies/conditions.
4. **Relabel or replace fake clinical engines** — lab interpreter, Health AI, wearable sync, and SOS must either be real integrations or explicitly marked non-clinical / disabled in store builds.
5. **Remove or implement emergency SOS** — simulation snackbar is unsafe adjacent to “Emergency” UX.
6. **Remove telehealth Join Video snackbar theater** (and similar high-trust CTAs).
7. **Enable `flutter build apk --obfuscate --split-debug-info=...`** (and prefer AAB + ABI splits).

### P1 — Before real users rely on it
1. Fix Fitness tab **0.911px overflow**.
2. Persist journal, nutrition, cycle, pregnancy, chronic histories, claims (or stop offering them).
3. Call `ConsentManager.initialize()` during hydrate; map toggles to OS permissions.
4. Add Android Health Connect permissions + real `health` plugin read path; stop formula `syncVitals`.
5. Fix clipboard copy; wire FHIR export UI or remove claim.
6. Harden auth session binding for remote users.
7. Replace snackbar-only family QR/invite/directions with real behavior or disabled states.
8. Expand tests for security-sensitive and clinical-honesty paths.

### P2 — Soon after
1. Production analytics sink.
2. Onboarding forced for new users.
3. Expose or remove hidden Triage tab.
4. Shrink APK via App Bundle / ABI splits.
5. Localize remaining hardcoded English clinical copy.

---

## Appendix A — Methodology checklist

- [x] Every route/screen from shell + pushes covered in §1  
- [x] Interactive elements traced (buttons/snackbars/modals)  
- [x] Repo-wide keyword search (mock/demo/TODO/localhost/secrets) investigated  
- [x] Backend target classified per screen  
- [x] Build artifact verification performed on `app-release.apk`  
- [x] `PRODUCTION_READINESS_AUDIT.md` at repo root  
- [x] No source files modified except this report  

## Appendix B — Runtime session notes

- Command: `flutter run -d chrome --web-port=8080`
- Console: `[SupabaseRepository] Running in offline/local-only mode: missing credentials.`
- Demo login → Home “Good morning, Daria” / Recovery OS with high-confidence scores
- Tabs exercised: Journal (Feeling Tracker), Fitness (overflow bug), Biology (seed CMP “Verified”)
- Sync wearable produced success snackbar claiming Apple Health
- `flutter test`: 42 passed
)
