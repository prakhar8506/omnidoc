# Cura — App Store & Play Store Publish-Readiness Audit

**Audit date:** 28 September 2026
**Scope:** `/Users/prakharjain/Documents/health companion` (working tree, uncommitted changes included)
**Mode:** Read-only audit. No application code was modified. This file is the only artifact created.

---

## 1. Executive summary

### Verdict: **NOT READY**

Cura is a feature-rich app with genuinely good foundations — real Supabase auth, in-app Privacy Policy and Terms, an account-deletion edge function, medical disclaimers on most health surfaces, a privacy manifest, no tracking SDKs, and no monetization to complicate review. But it cannot be submitted to either store today, for three independent classes of reason.

**First, the signup path is wired to an edge function that appears to have never been deployed.** In release builds, `AuthService.register` throws `Unable to create account. Please try again.` whenever `prepareAccount` returns null (`lib/core/services/auth_service.dart:137-139`), and `prepareAccount` returns null on any failure to invoke the `welcome-email` function (`lib/core/network/supabase_repository.dart:158-185`). Deployment of that function was blocked by an expired Supabase access token in the prior work session, and no Resend key is configured, so the "greeting email" the signup screen promises also cannot send. If the function is not live in the hosted project, **no new user can create an account in a store build** — a guaranteed "app is broken on launch" rejection under Apple 2.1 and Play's minimum-functionality policy.

**Second, iOS will crash and has never been built.** Three code paths start Apple speech recognition (journal, AI chat, meal logging) but `ios/Runner/Info.plist` has no `NSSpeechRecognitionUsageDescription`, which terminates the app on iOS the moment dictation starts. There is also no committed `Podfile`/`Podfile.lock` and no `DEVELOPMENT_TEAM` in the Xcode project, so no iOS archive has ever been produced or validated.

**Third, the app presents fabricated content as real.** A "Demo clinic directory" of invented doctors (`Dr. Priya Sharma, MD`, `Metro Center Health Pavilion`) is reachable from Quick Actions and from Home → Book Specialist and is presented as bookable clinicians; a hardcoded nine-person "India activity board" (`Meera · Bengaluru`, 4860 pts …) is presented to users as "Public movement ranks"; and Family Connect ships release UI literally labelled `Create Local Invite (Demo)` and `Show Demo QR Code`. Fake practitioner data in a health app is among the most reliable ways to get rejected by both stores, and it is compounded by an account-deletion dialog that promises to erase local health data but does not.

Nothing here is architecturally hard to fix — the blockers are one deployment, one plist key, removal of demo data, and honest error/deletion handling. Realistically this is **one to two focused work sessions from "ready with minor fixes" on Android**, plus a first iOS build-and-test cycle before iOS can be assessed at all.

### Readiness by track

| Track | Verdict | Gating reason |
|---|---|---|
| Google Play | **Not ready** | Signup dependency unverified; fake clinician/leaderboard data; Data Safety mismatch; `allowBackup` defaults to true for health data |
| Apple App Store | **Not ready** | Guaranteed iOS crash (missing speech usage string); no iOS build ever produced; same content and privacy issues as Play |

---

## 2. Step 0 — Orientation

| Aspect | Finding | Evidence |
|---|---|---|
| Framework | Flutter (Dart), not a web wrapper. 85 Dart files under `lib/`. No WebView, Capacitor, or Cordova anywhere. | `pubspec.yaml:1-44`; native UI throughout `lib/features/` |
| Flutter / Dart | Flutter 3.44.6 stable, Dart 3.12.2 | `flutter --version` |
| Navigation | No routing library. Single `MaterialApp` with a state-driven `home:` and imperative `Navigator.push(MaterialPageRoute(...))` for sub-screens; tabs are an `AnimatedSwitcher` keyed on `appState.currentTabIndex`. | `lib/main.dart:121-296` |
| State management | One large `ChangeNotifier` (`AppState`, ~1740 lines) consumed via `ListenableBuilder`, persisted to `SharedPreferences` per user. | `lib/core/state/app_state.dart`; `lib/main.dart:118-120` |
| Backend | Supabase (`supabase_flutter`) for auth, Postgres `health_events`, and Storage (`lab-uploads`). Four Deno edge functions: `welcome-email`, `interpret-lab`, `health-ai-chat`, `delete-account`. LLM calls prefer OpenAI, fall back to Gemini. | `lib/core/network/supabase_repository.dart`; `supabase/functions/*/index.ts` |
| Other integrations | Apple Health / Health Connect via `health`; Sentry crash reporting; ML Kit on-device OCR; `speech_to_text`; `url_launcher` to Google Maps and `tel:`; `share_plus`; `app_links` for `cura://` deep links. | `pubspec.yaml:14-34` |
| Min / target OS | Android `minSdk 26` (Android 8.0), `targetSdk`/`compileSdk` 36 via Flutter defaults — satisfies Play's current target-API requirement. iOS `IPHONEOS_DEPLOYMENT_TARGET = 13.0`. | `android/app/build.gradle.kts:29-33`; Flutter `FlutterExtension.kt:22-34`; `ios/Runner.xcodeproj/project.pbxproj` |
| Orientation | Locked to portrait at runtime; `Info.plist` still permits all four orientations on iPad. | `lib/main.dart:35-38`; `ios/Runner/Info.plist:88-94` |
| Lint / analysis | `flutter analyze`: **22 issues, 0 errors** — 1 warning (unused import) and 21 infos. Clean enough to ship. | run in audit; see §3 |
| Automated tests | 12 test files, 52 tests. **1 failing**, and CI runs `flutter test` on every push to `main`, so **CI is currently red**. | `flutter test`; `.github/workflows/flutter_ci.yml:20` |
| Runtime verification | The app was built and run on a physical OnePlus Nord CE (Android 15, device `09359d98`) during this session's prior work, so Android runtime behaviour is partly observed. **iOS was never built or run** — no simulator/device run was possible, so all iOS findings below are static. | — |

### What I could not verify (stated explicitly)

1. Whether `welcome-email`, `delete-account`, `interpret-lab`, and `health-ai-chat` are actually **deployed** to the hosted Supabase project, and their `verify_jwt` settings — no valid Supabase access token is available in this environment.
2. Whether `RESEND_API_KEY` is set server-side (it was not, as of the previous session), so whether any email sends at all.
3. Real-device iOS behaviour, including the speech-recognition crash, HealthKit prompts, and whether `FilePicker.saveFile` needs `NSPhotoLibraryAddUsageDescription`.
4. The merged Android manifest (plugin-contributed permissions) — only the app-level manifest was read.
5. Contents of untracked `env/production.json` and `android/key.properties` (present locally, correctly gitignored; not inspected for secrets).
6. Behaviour of a genuinely hung network socket (the indefinite-splash risk in §5 is reasoned from code, not reproduced).

---

## 3. Section 1 — UI smoothness & polish

| # | Status | Issue | Reference | Severity | Suggested fix |
|---|---|---|---|---|---|
| 1.1 | **Warning** | No in-flight UI on triage submit. `_submitSymptom` awaits an AI round trip (up to 45 s) while "Run Clinical Assessment" stays enabled — double-submit is possible. A placeholder assessment card does appear, so it isn't a frozen screen, but there's no spinner or disable. | `lib/features/triage/screens/triage_screen.dart:30-44`, `:596`; placeholder at `lib/core/state/app_state.dart:1474-1499` | Major | Add `_isSubmitting`, disable the button, show a spinner. |
| 1.2 | **Warning** | Wearable sync has no in-flight indicator from Quick Actions or the Home activity pill — the user taps, nothing happens visually, then a SnackBar appears. `AppState.isSyncingVitals` already exists and is used elsewhere; these two call sites ignore it. | `lib/core/widgets/quick_action_sheet.dart:262-265`; `lib/features/home/screens/home_screen.dart:884-888`; flag at `lib/core/state/app_state.dart:1227-1229` | Major | Bind both call sites to `isSyncingVitals`. |
| 1.3 | **Warning** | Delete Account has no loading state during a network call with a 60 s timeout — the dialog closes and the UI looks idle. | `lib/core/widgets/glass_app_bar.dart:367-372`; timeout at `lib/core/state/app_state.dart:422` | Major | Show a blocking progress state until it resolves. |
| 1.4 | **Warning** | Image picking (lab upload, meal log, journal, onboarding photo) has no loading state and swallows failures in empty `catch (_) {}` blocks — a failed pick is indistinguishable from a no-op. | `lib/features/journal/widgets/journal_entry_sheet.dart:80-89`; `lib/features/nutrition/widgets/log_meal_sheet.dart:81-84`; `lib/features/onboarding/screens/onboarding_baseline_screen.dart:52-59` | Minor | Surface a message on failure. |
| 1.5 | **Fail** | **Raw exception text shown to users.** Four user-visible paths render exception objects or HTTP response bodies: delete-account SnackBar `Text('Could not delete account: $e')`; release sign-in `AuthException('Unable to sign in: $e')`; vitals `lastSyncMessage = 'Sync failed: $e'`; and a failed lab interpretation stores `e.toString()` into `detailedExplanation`, which is then rendered as report body text. | `lib/core/widgets/glass_app_bar.dart:387`; `lib/core/services/auth_service.dart:224`; `lib/core/state/app_state.dart:1290-1292` (surfaced at `home_screen.dart:892`, `quick_action_sheet.dart:268`); `lib/core/services/report_interpreter_service.dart:325` rendered at `lib/features/lab_reports/screens/lab_reports_screen.dart:220-224` | **Blocker** | Map to human copy; log the raw error to Sentry only. Also `StateError('Delete failed (${response.statusCode}): ${response.body}')` at `app_state.dart:425` puts a raw server body on the path to the UI. |
| 1.6 | **Warning** | Silent network failures in the AI copilot: HTTP errors `debugPrint` and fall through to canned offline text, so the user is told something confident without knowing the request failed. | `lib/features/ai_assistant/services/ai_copilot_service.dart:210-218`, `:283-287` | Major | Prefix or badge offline/fallback answers visibly. |
| 1.7 | **Warning** | Missing empty states on user-data lists — the section header renders and the body is blank. Affects logged meals, clubs, family members (both Family Connect and the Visits tab), glucose/BP history, completed workouts, and cycle logs. | `lib/features/nutrition/screens/nutrition_hydration_screen.dart:174-175`; `lib/features/community/screens/activity_clubs_screen.dart:85`; `lib/features/family/screens/family_connect_screen.dart:87-89`; `lib/features/appointments/screens/appointments_screen.dart:840`; `lib/features/chronic_care/screens/chronic_care_screen.dart:212-249`, `:322-349` | Major | Add designed empty states. |
| 1.8 | **Pass** | Empty states *are* well handled on the primary surfaces: journal (`'No reflections recorded yet'`), appointments (`'No upcoming visits'`), medications, lab reports (`'No reports yet'` + upload CTA), emergency contacts, prenatal scans, clinic search, and a "Build your baseline" placeholder for correlations. | `journal_feeling_screen.dart:691-707`; `appointments_screen.dart:374-400`; `lab_reports_screen.dart:292-311`; `emergency_safety_screen.dart:363-366`; `app_state.dart:795-805` | — | — |
| 1.9 | **Pass** | Loading states are good on the highest-risk flows: auth (`_isLoading` + spinner), lab upload/OCR (staged `LinearProgressIndicator` driven by `labAnalysisStage`/`labAnalysisProgress`), AI chat typing indicator, and PDF export. | `sign_in_screen.dart:26`, `:323-328`; `upload_report_modal.dart:96-99`, `:263-309`; `ai_chat_sheet.dart:406-438`; `data_portability_screen.dart:213-247` | — | — |
| 1.10 | **Warning** | Touch targets below the 44 pt / 48 dp minimum: header avatar (~38 px), several back controls with `size: 18` icons, the chronic-care "Log Value" chip (`vertical: 7`, icon 16), and Home quick-grid icons at `size: 18`. | `lib/core/widgets/glass_app_bar.dart:68-83`; `lib/features/community/screens/community_challenges_screen.dart:36-44`; `lib/features/community/screens/activity_clubs_screen.dart:29-31`; `lib/features/chronic_care/screens/chronic_care_screen.dart:192-204`; `lib/features/home/screens/home_screen.dart:1645-1651` | Minor | Wrap in 48 dp minimum hit areas. |
| 1.11 | **Warning** | Responsive layout is mostly disciplined (`Expanded`/`Flexible` + `maxLines` + ellipsis are used widely), but three overflow bugs were found and fixed *by hand* during this session's prior work (Journal telemetry 16 px, Triage 5 px, Emergency title 33 px), which suggests small-screen layout has never been systematically tested. No tablet layout exists — the app is a stretched phone layout, and iPad allows landscape. | Fixed: `journal_feeling_screen.dart`, `triage_screen.dart`, `emergency_safety_screen.dart`. iPad orientations: `ios/Runner/Info.plist:88-94` | Major | Test at 320 dp width and on iPad; either build a tablet layout or restrict iPad orientations to portrait. Apple reviews iPad screenshots against actual iPad behaviour. |
| 1.12 | **Pass (light-only)** | No dark theme exists — `MaterialApp` sets `theme:` only, with no `darkTheme` or `themeMode`, so the app is light in all cases and cannot break from a theme switch. Note one artifact: `values-night/styles.xml` gives the Android launch window a **black** background, so dark-mode users get a black flash before the light UI paints. | `lib/core/theme/app_theme.dart:7-54`; `lib/main.dart:124`; `android/app/src/main/res/values-night/styles.xml` | Minor | Either ship a dark theme or align the night launch theme to the light background. |
| 1.13 | **Pass** | Keyboard handling is solid: `windowSoftInputMode="adjustResize"`, bottom sheets use `isScrollControlled: true` with `viewInsets.bottom` padding, and auth/onboarding use `SingleChildScrollView`. Keyboard types are correct on email, numeric, and phone fields. | `AndroidManifest.xml:29`; `log_meal_sheet.dart:110-118`; `sign_in_screen.dart:129`, `:235`; `emergency_safety_screen.dart:711` | — | — |
| 1.14 | **Warning** | One keyboard-type gap: the age field in the family-member modal has no `keyboardType`, so it opens a text keyboard for a numeric value. | `lib/features/appointments/widgets/family_member_modal.dart:140-148` | Minor | Add `TextInputType.number`. |
| 1.15 | **Warning** | Animation/perf: the feeling dial previously wrote all user data to `SharedPreferences` and fired a global `notifyListeners()` on every interaction (fixed this session). The same pattern remains structurally risky elsewhere — `AppState` is one ~1740-line `ChangeNotifier` wrapping the whole app, so *any* mutation rebuilds every `ListenableBuilder`, including the root `MaterialApp`. `_persistCurrentUserData()` writes the entire user blob synchronously on most actions. | `lib/core/state/app_state.dart` (`_persistCurrentUserData`); root listener `lib/main.dart:118-120` | Major | Debounce persistence; split the notifier or introduce selector-style rebuilds before adding more screens. |
| 1.16 | **Pass** | No lorem ipsum, and debug affordances are properly gated: demo sign-in is `kDebugMode && ENABLE_DEMO` and `seedDemoEvents` early-returns in release. | `lib/core/env/app_env.dart:27-39`; `lib/features/auth/screens/sign_in_screen.dart:173-201`; `lib/core/state/app_state.dart:1083-1085` | — | — |
| 1.17 | **Warning** | Lint noise: 1 unused-import warning and 21 infos, including two `share_plus` deprecation warnings (`Share.share` → `SharePlus.instance.share()`) that will break on the next major bump. | `lib/features/home/screens/home_screen.dart:19`; `lib/features/community/screens/activity_clubs_screen.dart:151` | Minor | Clear before submission. |

---

## 4. Section 2 — Feature / workflow integrity

### Primary flows traced

| Flow | Entry point | Status |
|---|---|---|
| Cold start → splash → gate | `main.dart:133-162` | **Warning** — see 2.4 |
| Sign up | `sign_up_screen.dart` → `AuthService.register` → `welcome-email` → `signInWithPassword` | **Fail** — see 2.1 |
| Sign in | `sign_in_screen.dart` → remote, with local fallback blocked in release | Pass (raw error text — see 1.5) |
| Onboarding baseline | root `home` when incomplete; "Skip for now" available | Pass |
| Core tabs (Home / Journal / Triage / Appointments / Labs) | `HealthCompanionShell` | Pass |
| Lab upload → OCR → AI interpretation | `upload_report_modal.dart` → `interpret-lab` | Pass (good staged progress) |
| AI chat | `ai_chat_sheet.dart` → `health-ai-chat` | **Warning** — see 2.7, 3.5 |
| Symptom triage | `triage_screen.dart` → `health-ai-chat` (`mode: triage`) | Warning — see 1.1 |
| Appointments / find care | `find_care_screen.dart` (real Google Maps) **and** `doctor_availability_screen.dart` (fake directory) | **Fail** — see 2.2 |
| Emergency SOS + contacts | `emergency_safety_screen.dart` | Pass (persists, dials via `tel:`) |
| Mood / mental-health check | `mood_check_screen.dart` | Pass (disclaimer + crisis lines present) |
| Family sharing | `family_connect_screen.dart` | **Fail** — demo UI in release, see 2.3 |
| Clubs & leaderboard | `activity_clubs_screen.dart` | **Fail** — fake ranks, see 2.2 |
| Data export | `data_portability_screen.dart` | Pass |
| Sign out | `glass_app_bar.dart` profile sheet | Pass |
| Account deletion | profile sheet → `delete-account` | **Fail** — see 2.5 |
| Payments | none | N/A |

### Findings

| # | Status | Issue | Reference | Severity | Suggested fix |
|---|---|---|---|---|---|
| 2.1 | **Fail** | **Signup depends on an edge function that is likely not deployed.** `register` calls `prepareAccount`, which invokes `welcome-email`; any invocation failure returns `null`, and in release that becomes `AuthException('Unable to create account. Please try again.')`. Deployment was blocked by an expired Supabase token in the prior session and no `RESEND_API_KEY` exists, so the greeting the signup screen advertises also cannot send. Separately: in release the local duplicate-email pre-check is skipped (`existing != null && !kReleaseMode`), so duplicate handling relies entirely on the function's 409. | `lib/core/services/auth_service.dart:113-155`; `lib/core/network/supabase_repository.dart:152-186`; `supabase/functions/welcome-email/index.ts:18-73` | **Blocker** | Deploy and smoke-test signup against the hosted project from a release build before submitting. Decide whether the greeting email is required for v1 or should be dropped from the copy. |
| 2.2 | **Fail** | **Fabricated clinicians and users shown as real.** (a) `clinic_directory.dart` is commented "Demo clinic directory" and contains invented doctors and hospitals; it drives `DoctorAvailabilityScreen`, reachable from Quick Actions. (b) `BookAppointmentModal` embeds its own fake doctor list and slots (`'Tomorrow, 09:30 AM'`) and is reachable from Home → Book Specialist. (c) `AppState.countryBoard()` returns nine invented people with point totals, rendered under the heading "Public movement ranks". | `lib/core/data/clinic_directory.dart:5-124` via `lib/core/widgets/quick_action_sheet.dart:208`; `lib/features/appointments/widgets/book_appointment_modal.dart:33-58` via `home_screen.dart:1598`; `lib/core/state/app_state.dart:1708-1727` via `activity_clubs_screen.dart:94` | **Blocker** | Remove all three, or replace with real data. `FindCareScreen` (real Google Maps search) already exists and is the honest replacement for the fake directory. The leaderboard should show only real participants or be cut for v1. |
| 2.3 | **Fail** | **Release UI labelled "Demo".** Family Connect ships buttons reading `Create Local Invite (Demo)`, `Show Demo QR Code`, `Add Local (Demo)`, a `Demo Family Invite QR` dialog, and copy admitting "Real account invites and encrypted sharing are not enabled yet." It is reachable in release from the profile sheet and is not behind `AppEnv.enableDemo`. | `lib/features/family/screens/family_connect_screen.dart:408`, `:424`, `:442-463`, `:501`, `:729-737`; entry at `lib/core/widgets/glass_app_bar.dart:229-235` | **Blocker** | Gate behind `kDebugMode`/`AppEnv.enableDemo`, or finish the feature, or remove the entry point. Reviewers read "Demo" as "incomplete app". |
| 2.4 | **Warning** | **Possible indefinite splash with no network.** The splash gate is `!_splashCompleted \|\| _appState.isHydrating`, and `hydrate()` awaits `pullRemoteEvents` → `fetchHealthEvents`, which has no timeout (the AI, lab, and delete calls all do). A hung socket leaves the user on "Preparing daily telemetry…" indefinitely. There is no `connectivity_plus` and no offline banner anywhere. | `lib/main.dart:137-138`; `lib/core/state/app_state.dart:295-325`; `lib/core/network/supabase_repository.dart:247-255`; splash copy `splash_screen.dart:225-226` | Major | Add a timeout to remote hydration and proceed with local data on expiry. |
| 2.5 | **Fail** | **Account deletion does not do what its dialog promises.** The confirmation says it "will permanently delete your Cura account **and local health data on this device**". `deleteAccount()` calls the edge function, signs out, and calls `_resetInMemoryProfile()` — in-memory only. The `hc_users_v1` record (email, name, blood type, password hash) and the per-user persisted health blob stay in `SharedPreferences`, and `EventStore.clear()` is never called. Also, if `SUPABASE_SERVICE_ROLE_KEY` is unset the function returns **503 "no deletions performed"**, and the user sees only a raw-error SnackBar. | dialog `lib/core/widgets/glass_app_bar.dart:347-371`; `lib/core/state/app_state.dart:395-434`; `_resetInMemoryProfile` at `:596-668`; `supabase/functions/delete-account/index.ts:95-112` | **Blocker** | Clear `hc_users_v1`, the per-user data blob, and `EventStore` on delete; verify the service-role key is set server-side; fail loudly and honestly if the remote delete did not succeed. |
| 2.6 | **Warning** | **Deep-link / init race on cold start.** `initState` fires `hydrate()` and `_initDeepLinks()` without ordering. `Supabase.initialize` runs *inside* `hydrate()`, but `_handleAuthDeepLink` calls `Supabase.instance.client` — so an initial `cura://auth-callback` link can be processed before initialization. The failure is caught and logged, so the likely symptom is a silently unrestored session rather than a crash. The handler also validates only the scheme, not the host. | `lib/main.dart:79-106`; init at `lib/core/network/supabase_repository.dart:121-126` called from `app_state.dart:297` | Major | Await initialization before handling links; validate the host. |
| 2.7 | **Warning** | `setState` after `await` without a `mounted` guard — most notably in AI chat right after the network call resolves (the adjacent line 148 *does* guard, so this is an oversight), plus several spots in the meal-log sheet and onboarding photo picker. Closing the sheet mid-request throws. | `lib/features/ai_assistant/widgets/ai_chat_sheet.dart:150-155`; `lib/features/nutrition/widgets/log_meal_sheet.dart:47-48`, `:66-84`; `lib/features/onboarding/screens/onboarding_baseline_screen.dart:55-57` | Major | Add `if (!mounted) return;` after each await. |
| 2.8 | **Warning** | **CI is red.** `flutter test` reports 51 passing, 1 failing: `submitNewSymptomTriage generates updated assessment` expects `'URGENT'` and gets `'ANALYZING…'`. The test is stale — triage became async and the sync method now only sets a placeholder — but the workflow runs `flutter test` on every push to `main`, so the repo has no green baseline. | `test/app_state_test.dart:75`; `.github/workflows/flutter_ci.yml:20` | Major | Update the test to the async API (`submitNewSymptomTriageAsync`) and get CI green before tagging a release. |
| 2.9 | **Warning** | Two screens containing mock data have **no navigation entry** and are effectively dead code: `InsuranceClaimsScreen` (with `'BlueCross Platinum Health'`, policy `'BCP-992014-88'`, `'$640.00'`) and `CommunityChallengesScreen`. Harmless today; a rejection risk if linked later. | `lib/features/insurance/screens/insurance_claims_screen.dart:147-195`; `lib/features/community/screens/community_challenges_screen.dart` | Minor | Delete or clearly mark as unshipped. |
| 2.10 | **Warning** | Chronic-care doctor-prep copy cites fixed values (`'fasting glucose (102 mg/dL)'`, `'sleep duration (7h 10m)'`) regardless of the user's actual data — a health app telling users invented numbers about themselves. | `lib/features/chronic_care/screens/chronic_care_screen.dart:171-173`, `:281-284` | Major | Derive from real state or remove the numbers. |
| 2.11 | **Pass** | Permission requests are contextual, not at launch: camera/photos on user tap, microphone only when dictation starts, Health Connect behind an explanatory sheet listing exactly what is read. Nothing is requested during onboarding or startup. | `upload_report_modal.dart:40-46`; `journal_entry_sheet.dart:101-127`; `wearable_permissions_sheet.dart:122-154` | — | — |
| 2.12 | **Warning** | One exception to 2.11: Home → Sync Wearable calls `WearableService.requestAuthorization()` directly, bypassing the rationale sheet, so the OS health prompt appears with no preceding explanation. Dictation likewise only explains *after* a failed init ("Allow microphone access…"). | `lib/core/state/app_state.dart:1232` via `home_screen.dart:803`; `journal_entry_sheet.dart:120-121` | Major | Route both through the rationale sheet / pre-prompt. |
| 2.13 | **Pass** | Denied-permission degradation is reasonable: the app keeps working with manual entry when health permissions are refused, and AI features fall back to local heuristics. | `ai_copilot_service.dart:121-122`, `:218`; `report_interpreter_service.dart:159-168` | — | — |
| 2.14 | **Pass** | No payments, subscriptions, paywalls, or purchase SDKs anywhere — nothing to reconcile against Apple 3.1.1 or Play Billing. | `pubspec.yaml`; repo-wide search for `in_app_purchase`, `stripe`, `razorpay`, `billing`, `paywall` | — | — |
| 2.15 | **Warning** | Push notifications: none implemented (no FCM/APNs). The app shows an `unreadNotificationsCount` badge with no notification system behind it, and `ConsentManager` exposes a notifications toggle that grants nothing. | `lib/core/consent/consent_manager.dart:133-171`; `app_state.dart` `unreadNotificationsCount` | Minor | Remove the toggle/badge or implement notifications. Don't declare push in store metadata. |

---

## 5. Section 3 — Apple App Store compliance

| # | Guideline | Status | Issue | Reference | Severity | Suggested fix |
|---|---|---|---|---|---|---|
| 3.1 | 5.1.1 / crash | **Fail** | **Missing `NSSpeechRecognitionUsageDescription`.** Three paths start Apple speech recognition; iOS terminates the process when speech recognition begins without this key. This is a first-session crash for any user who taps the mic. | key absent from `ios/Runner/Info.plist`; callers `journal_entry_sheet.dart:101-127`, `ai_chat_sheet.dart:81-100`, `log_meal_sheet.dart:51-71` | **Blocker** | Add the key with an accurate string. |
| 3.2 | 5.1.1 | **Fail** | **Inaccurate microphone purpose string.** `NSMicrophoneUsageDescription` reads "Microphone access may be used when capturing media with your camera." The actual use is voice dictation of journal entries, symptoms, and meals. Generic or wrong purpose strings are a standard rejection. | `ios/Runner/Info.plist:78-79` | **Blocker** | Rewrite to describe dictation. |
| 3.3 | 2.1 / build | **Fail** | **No iOS build has ever been produced.** No `Podfile` or `Podfile.lock` is committed and `DEVELOPMENT_TEAM` is unset in all three build configurations (`CODE_SIGN_STYLE = Automatic`). Nothing about the iOS target — pod resolution, HealthKit entitlement provisioning, launch behaviour — has been validated. | `ios/` (no Podfile); `ios/Runner.xcodeproj/project.pbxproj` | **Blocker** | Run `flutter build ipa`, fix what surfaces, and test on a device before any other iOS work. |
| 3.4 | 4.8 | **Pass** | Sign in with Apple is **not required**: the only auth is Supabase email + password. Repo-wide search found no Google/Facebook/OAuth login — `signInWithPassword` is the sole method, and `signInAnonymously` appears only as an internal fallback for lab upload, not a user-facing guest login. | `lib/core/network/supabase_repository.dart:189-197`; `lib/core/services/report_interpreter_service.dart:129-131` | — | If social login is ever added, Sign in with Apple becomes mandatory. |
| 3.5 | 1.4.1 | **Warning** | Medical-advice surfaces are mostly disciplined — triage ("Guidance only, not a diagnosis"), lab reports ("Not a diagnosis • Always review with your physician"), mood check ("a wellness screening, not a diagnosis of depression"), diet plan ("not a prescription"). **The AI chat sheet has no persistent disclaimer**; the welcome message carries none, and the guardrail lives only in the edge-function system prompt and in some generated strings. Apple scrutinises health apps that generate advice; a live LLM with no visible standing disclaimer is the weakest link. | disclaimers `triage_screen.dart:268-270`, `lab_reports_screen.dart:446-447`, `mood_check_screen.dart:70-72`, `diet_plan_screen.dart:113-115`; gap `ai_chat_sheet.dart:50-55`; server guardrail `supabase/functions/health-ai-chat/index.ts:20-28` | Major | Add a persistent in-UI disclaimer to AI chat. Be ready to describe the methodology behind triage and lab interpretation in Review Notes. |
| 3.6 | 5.1.1(v) | **Warning** | An in-app deletion path **does exist** (profile sheet → Delete Account → `delete-account`, which removes user rows, storage objects, the profile, and the auth user) — but it is incomplete and mis-described; see 2.5. Also, the privacy policy tells users to find it at "Profile → Delete Account", while the actual control is in a bottom sheet behind the header avatar. | `lib/core/widgets/glass_app_bar.dart:296-371`; `supabase/functions/delete-account/index.ts:117-149`; wording `privacy_policy_screen.dart:62-63` | Major | Fix the local wipe, verify the server key, align the wording. |
| 3.7 | 2.1 (completeness) | **Fail** | Content that reads as "incomplete app": fake clinicians, fake public leaderboard, "Demo"-labelled Family Connect, and copy admitting features "are not enabled yet". Rolled up from 2.2 and 2.3. | see 2.2, 2.3 | **Blocker** | Remove or gate before submission. |
| 3.8 | 4.2 | **Pass** | Not a web wrapper. Fully native Flutter UI with real device integrations (HealthKit, camera, on-device OCR, speech, share sheet, `tel:` dialling). No minimum-functionality concern. | `lib/features/**`; `pubspec.yaml:14-34` | — | — |
| 3.9 | 1.2 (UGC) | **Warning** | There is no human-to-human chat or public profile, and journal data is private — but the clubs screen shows a "Public movement ranks" board of named people with **no report or block mechanism**. A repo-wide search for report/block/moderation UI found none. The fact that the names are fabricated makes this worse, not better. | `activity_clubs_screen.dart:80-94`; `app_state.dart:1708-1727` | Major | Remove the public board for v1 (simplest), or add report/block plus a moderation path. |
| 3.10 | 3.1.1 | **Pass** | No digital purchases and no external payment links — `url_launcher` is used only for maps, `tel:`, and Health Connect/Apple Health deep links. | `find_care_screen.dart:111-112`; `emergency_safety_screen.dart` | — | — |
| 3.11 | 5.1.2 / privacy manifest | **Warning** | `PrivacyInfo.xcprivacy` declares only HealthAndFitness, EmailAddress, Name, and PhotosOrVideos. Not declared but demonstrably collected or transmitted: **crash/performance data** (Sentry, `tracesSampleRate: 0.2`), **other user content** (journal text, symptom queries, triage input, mood-check summaries sent to the LLM), **sensitive health info** (medications, allergies, lab summaries in LLM payloads), and the user-entered **city** sent to Google Maps in a URL. | `ios/Runner/PrivacyInfo.xcprivacy:10-58`; Sentry `lib/main.dart:52-58`; LLM payload `ai_copilot_service.dart:57-111`, `:145-149`; city `find_care_screen.dart:111-112` | Major | Extend the manifest and keep App Privacy answers consistent with it. |
| 3.12 | ATT | **Pass** | `NSPrivacyTracking` is false, no IDFA or tracking SDK, no ad frameworks — no ATT prompt needed. | `ios/Runner/PrivacyInfo.xcprivacy:5-8` | — | — |
| 3.13 | Assets | **Pass** | App icons are branded and technically valid: 1024×1024, PNG colour type 2 (no alpha channel), full icon set present for both platforms. | `ios/.../Icon-App-1024x1024@1x.png` (`sips: hasAlpha: no`); `android/.../mipmap-*/ic_launcher.png` | — | Cosmetic note: corners are pre-rounded on a white field, so Apple's mask will add a visible white ring. Supply a full-bleed square artwork. |
| 3.14 | HealthKit | **Pass** | HealthKit entitlement present, both health usage strings present and specific, and the update string honestly states write access is unused. | `ios/Runner/Runner.entitlements`; `Info.plist:80-83` | — | — |
| 3.15 | Assets | **Warning** | iPad permits all four orientations while the app locks portrait at runtime and has no tablet layout — Apple tests iPad builds and requires iPad screenshots. | `ios/Runner/Info.plist:88-94` vs `lib/main.dart:35-38` | Minor | Restrict iPad orientations or build a real tablet layout. |

---

## 6. Section 4 — Google Play compliance

| # | Status | Issue | Reference | Severity | Suggested fix |
|---|---|---|---|---|---|
| 4.1 | **Pass** | Target API level satisfied: `compileSdk`/`targetSdk` resolve to **36** via the Flutter Gradle plugin, `minSdk 26`. | `android/app/build.gradle.kts:29-33`; Flutter `FlutterExtension.kt:22-34` | — |
| 4.2 | **Fail** | **Data Safety form will mismatch the code.** Health, mental-health, and medical-document data is transmitted to third-party LLM providers (OpenAI preferred, Gemini fallback) via edge functions, and crash data goes to Sentry. Lab report **images** can be sent as `image_base64`, and OCR'd report text is embedded in prompts. Any Data Safety declaration that omits third-party sharing of health data, or omits crash data, is a policy violation and a common enforcement trigger. | `supabase/functions/health-ai-chat/index.ts:110-123`, `:207-283`; `supabase/functions/interpret-lab/index.ts:171-210`, `:497-528`; `report_interpreter_service.dart:201-254`, `:491-517`; Sentry `lib/main.dart:52-58` | **Blocker** | Enumerate every category and destination, declare sharing with third-party AI processors and crash reporting, and make the privacy policy match (see 5.2). |
| 4.3 | **Fail** | **`android:allowBackup` is not set, so it defaults to `true`, and there are no `dataExtractionRules` or `fullBackupContent`.** Every piece of health data in `SharedPreferences` — journal entries, mood-check results, menstrual and pregnancy logs, medications, allergies, emergency contacts, and the local password hash — is auto-backed-up to the user's Google account and restored to new devices. | `android/app/src/main/AndroidManifest.xml:17-20` (no `allowBackup`); persisted keys `lib/core/state/app_state.dart:690-730` | **Blocker** | Set `android:allowBackup="false"` or ship `dataExtractionRules` excluding health data, and declare backup behaviour in Data Safety. |
| 4.4 | **Warning** | `ACTIVITY_RECOGNITION` is declared but never referenced in Dart — steps come through the `health` package / Health Connect. Either the `health` plugin needs it for Android step reads (plausible, unverified from the app manifest alone) or it is an over-broad declaration. | `AndroidManifest.xml:7`; step reads `wearable_service.dart:16-17`, `:142-143` | Major | Confirm against the merged manifest; remove if unneeded. Play flags declared-but-unused permissions. |
| 4.5 | **Warning** | Health Connect integration requires Play's **data-access declaration** and an approved use case, plus a privacy-policy link, and the app must handle permission revocation. The rationale intent filter and `ViewPermissionUsageActivity` alias are correctly in place, which is the part most apps get wrong. | `AndroidManifest.xml:38-60`, `:90-99` | Major | Complete the Health Connect / Health Apps declaration in Play Console before release; this is a manual-review gate. |
| 4.6 | **Pass** | No sensitive high-risk permissions: no background location, SMS, call log, `QUERY_ALL_PACKAGES`, or Accessibility Service. `<queries>` is correctly scoped to speech, `https`, `tel`, and Health Connect. | `AndroidManifest.xml:74-100` | — |
| 4.7 | **Warning** | Account deletion path exists in-app (4.x requires in-app **or** web). There is no web deletion URL, which Play also asks for in the Data Safety form. | see 2.5, 3.6 | Major | Fix the in-app path; publish a web deletion request URL for the Console form. |
| 4.8 | **Pass** | No ads, no ad SDK, no deceptive placements. Content rating should be straightforward apart from the health/medical category. | `pubspec.yaml` | — |
| 4.9 | **Pass** | No dynamic code loading, no remote code execution, no hidden functionality. Network calls go only to Supabase, its edge functions, and `https://www.google.com/maps/search/`. `usesCleartextTraffic="false"` and iOS `NSAllowsArbitraryLoads` false. | `AndroidManifest.xml:20`; `ios/Runner/Info.plist:69-73` | — |
| 4.10 | **Warning** | Release signing depends on an untracked local `android/key.properties`, and `build.gradle.kts` **silently falls back to debug signing** if any property is missing. A debug-signed AAB is rejected at upload, and the fallback makes the failure easy to miss. | `android/app/build.gradle.kts:36-66` | Major | Fail the release build loudly when signing config is incomplete; back up the keystore off-machine. |
| 4.11 | **Warning** | No code shrinking or obfuscation configured (`minifyEnabled`/`shrinkResources` absent; no `--obfuscate --split-debug-info` in any documented build command). Not a policy violation, but it ships larger and leaves Dart symbols readable. | no matches in `android/`; `.github/workflows/flutter_ci.yml` | Minor | Add obfuscation and split debug info to the release command. |

### Security findings surfaced during the audit

| # | Status | Issue | Reference | Severity | Suggested fix |
|---|---|---|---|---|---|
| 4.12 | **Fail** | **`welcome-email` is an unauthenticated account-creation endpoint that accepts a plaintext password.** It performs no JWT or caller check before calling `admin.auth.admin.createUser` with the service-role key, and it takes `password` in the request body. Reachable by anyone holding the anon key — which ships inside the app. It bypasses GoTrue's built-in signup rate limiting, captcha, and abuse protections, and enables email enumeration via the 409 path. | `supabase/functions/welcome-email/index.ts:18-73`; caller `supabase_repository.dart:160-167` | **Blocker** | Prefer GoTrue signup with confirmations disabled, so passwords never transit a custom function. If the function must stay, add rate limiting, captcha, a shared secret, and a non-enumerating error response. |
| 4.13 | **Warning** | Local password hashing is a **single unstretched SHA-256** of `"$id::$password"`. It backs a debug-only offline login path (release throws before reaching it), but the hash is written to `SharedPreferences` on every device and — per 4.3 — is backed up to Google Drive today. | `lib/core/services/auth_service.dart:30-33`, `:157`, `:204`; persisted at `:45` | Major | Stop persisting a password hash at all; rely on the Supabase session. |
| 4.14 | **Pass** | No secrets in tracked files. Config comes from `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `AI_GATEWAY_URL`, `SENTRY_DSN`) with no hardcoded fallbacks; release startup validates them and rejects placeholder URLs. `.gitignore` covers `env/*.json` (keeping `*.example`), `.tmp_deploy_env`, `.tmp_service_role`, and `supabase/.env*`; `git ls-files` confirms only the example is tracked. | `lib/core/env/app_env.dart:6-69`; `lib/main.dart:31-33`; `.gitignore:51-60` | — |
| 4.15 | **Warning** | `health-ai-chat` and `interpret-lab` accept the anon key / anonymous JWT, so unauthenticated callers can burn paid LLM tokens with arbitrary payloads. | `supabase/functions/health-ai-chat/index.ts:78-93`; `supabase/functions/interpret-lab/index.ts:155-176` | Major | Require a real user JWT and add per-user rate limiting. |
| 4.16 | **Warning** | Four repository write methods (`saveJournalEntry`, `recordCheckIn`, `upsertScore`, `recordHabitLog`) are implemented and tested but have **no callers** in `lib/`. If the backing tables exist, Data Safety answers should reflect what actually happens, not what the repository could do. | `lib/core/network/supabase_repository.dart:278-377`; only caller `test/network/supabase_repository_test.dart` | Minor | Wire them up or delete them. |

---

## 7. Section 5 — General policy / content

| # | Status | Issue | Reference | Severity | Suggested fix |
|---|---|---|---|---|---|
| 5.1 | **Warning** | Privacy Policy and Terms of Use are **rendered in-app** as full text (not external links) and are reachable from the profile sheet — genuinely better than most apps. But they are **not linked before account creation**: the sign-up screen has no Terms/Privacy link and no acceptance checkbox. Both stores expect pre-signup availability, and GDPR/DPDP expect it at collection time. | `lib/features/legal/screens/privacy_policy_screen.dart`, `terms_of_use_screen.dart`; entry `glass_app_bar.dart:272-293`; gap `sign_up_screen.dart` | Major | Add links (and ideally an explicit acceptance) to sign-up. |
| 5.2 | **Fail** | **The privacy policy understates actual data flows.** It says AI features "may use a contracted AI provider (e.g. Google Gemini)", but the code prefers **OpenAI** and only falls back to Gemini. It does not mention **Sentry** crash reporting, does not disclose that **lab report images** may be uploaded to an AI vision provider, and does not mention mental-health screening answers. A health app whose policy is narrower than its behaviour is an enforcement risk on both stores independent of review. | `privacy_policy_screen.dart:53-56`, `:45-48`; provider order `health-ai-chat/index.ts:110-123`, `interpret-lab/index.ts:178-210`; images `interpret-lab/index.ts:171-176`; Sentry `lib/main.dart:52-58` | **Blocker** | Rewrite to name every processor and category, including images, mental-health data, and crash telemetry. |
| 5.3 | **Warning** | Both stores require a **publicly hosted** privacy-policy URL for the listing (in-app text is not sufficient), and Health Connect requires it too. No hosted URL is referenced anywhere in the repo; the only contact is `support@cura.health` — a domain whose existence I could not verify. | `lib/core/branding/app_brand.dart:6` | Major | Host the policy at a stable URL and confirm the support mailbox receives mail. |
| 5.4 | **Pass** | Health content is framed as wellness guidance, not diagnosis, and Terms state the app "is not a medical device" and "must not be used for emergency decision-making". The mood check ships crisis resources (112 India, 911/988 US, AASRA, iCall) and escalates on the safety item — the right handling for a depression screener. | `terms_of_use_screen.dart:46-47`; `mood_check_screen.dart:70-112`; `lib/core/mental/mood_check.dart:112-115` | — |
| 5.5 | **Warning** | No age gate or minimum-age statement, despite collecting health, mental-health, and menstrual/pregnancy data. This drives the Play content-rating and "Families" answers and Apple's age rating; menstrual/pregnancy tracking also carries reproductive-health sensitivity in some jurisdictions. | no age-gate found in `lib/features/auth/` or onboarding | Major | Add a minimum-age affirmation and set ratings to 17+/Mature accordingly. |
| 5.6 | **Pass** | No gambling, no adult content, no regulated-substance content. No restricted category beyond health itself. | repo-wide review | — |
| 5.7 | **Warning** | Store metadata must not imply diagnosis. Current in-app language is careful, but `README.md`, `DEEP_TESTING_REPORT.md`, and `PRODUCTION_READINESS_AUDIT.md` in the repo root contain marketing-style claims that should not be copied into listing copy unreviewed. | repo-root markdown files | Minor | Draft listing copy deliberately; avoid "diagnose", "detect", "medical-grade". |

---

## 8. Prioritized punch-list

### Tier 1 — Would cause outright store rejection (fix before any submission)

| # | Item | Reference | Track |
|---|---|---|---|
| 1 | **Deploy and smoke-test `welcome-email`**, or move signup back to GoTrue. Verify from a release build that a brand-new user can register. Signup is currently dead if the function isn't live. | 2.1 | Both |
| 2 | **Add `NSSpeechRecognitionUsageDescription`** to `ios/Runner/Info.plist`. Without it, iOS kills the app the first time anyone taps the mic. | 3.1 | iOS |
| 3 | **Rewrite `NSMicrophoneUsageDescription`** to describe voice dictation rather than camera capture. | 3.2 | iOS |
| 4 | **Remove the fake clinic directory and fake booking doctors.** Route Quick Actions and Home → Book Specialist to the real `FindCareScreen`. | 2.2 | Both |
| 5 | **Remove or replace the hardcoded "India activity board."** Invented people presented as public ranks. | 2.2 | Both |
| 6 | **Gate or finish the "Demo"-labelled Family Connect UI.** Buttons that say "Demo" and copy saying features aren't enabled read as an incomplete app. | 2.3 | Both |
| 7 | **Make account deletion do what the dialog says** — wipe `hc_users_v1`, the per-user data blob, and `EventStore` — and confirm `SUPABASE_SERVICE_ROLE_KEY` is set so the function doesn't 503. | 2.5, 3.6 | Both |
| 8 | **Stop showing raw exception text to users** in delete-account, release sign-in, vitals sync, and lab report bodies. | 1.5 | Both |
| 9 | **Set `android:allowBackup="false"`** (or add `dataExtractionRules`) so health data and the local password hash stop syncing to Google Drive. | 4.3 | Android |
| 10 | **Align the privacy policy with reality** — name OpenAI, disclose lab-image upload to an AI vision provider, disclose Sentry, disclose mental-health data — and fill the Play Data Safety form to match. | 4.2, 5.2 | Both |
| 11 | **Lock down `welcome-email`** so an unauthenticated caller can't create accounts with the service-role key, and stop putting plaintext passwords through a custom function. | 4.12 | Both |
| 12 | **Produce a first iOS build** (`flutter build ipa`) with a `DEVELOPMENT_TEAM` and a committed `Podfile`, and test on a real device. iOS readiness is otherwise unknowable. | 3.3 | iOS |
| 13 | **Complete Play's Health Apps / Health Connect declarations** and host the privacy policy at a public URL. | 4.5, 5.3 | Android |

### Tier 2 — Likely to drive poor reviews or a metadata rejection

| # | Item | Reference |
|---|---|---|
| 14 | Add a persistent disclaimer to the AI chat sheet; every other health surface has one. | 3.5 |
| 15 | Add a timeout to remote hydration so a bad network can't strand users on the splash screen. | 2.4 |
| 16 | Add loading/disabled states to triage submit, vitals sync, and delete-account. | 1.1–1.3 |
| 17 | Fix the stale triage test and get CI green. | 2.8 |
| 18 | Add `if (!mounted) return;` after awaits, starting with the AI chat sheet. | 2.7 |
| 19 | Remove or moderate the public leaderboard (Apple 1.2 needs report + block for public user content). | 3.9 |
| 20 | Link Terms and Privacy from the sign-up screen and add a minimum-age affirmation. | 5.1, 5.5 |
| 21 | Fix the deep-link/initialization race so `cura://auth-callback` reliably restores a session on cold start. | 2.6 |
| 22 | Route Home → Sync Wearable through the rationale sheet instead of prompting cold. | 2.12 |
| 23 | Stop the chronic-care prep card from citing invented glucose and sleep numbers. | 2.10 |
| 24 | Add empty states for meals, clubs, family members, and glucose/BP history. | 1.7 |
| 25 | Surface AI/network failures instead of silently serving canned offline text. | 1.6 |
| 26 | Make release builds fail loudly when signing config is missing, rather than falling back to debug signing. | 4.10 |
| 27 | Require a real user JWT on `health-ai-chat` and `interpret-lab`, and rate-limit them. | 4.15 |
| 28 | Resolve `ACTIVITY_RECOGNITION` — confirm the plugin needs it, or drop it. | 4.4 |

### Tier 3 — Polish

| # | Item | Reference |
|---|---|---|
| 29 | Test at 320 dp width and on iPad; restrict iPad orientations or build a tablet layout. | 1.11, 3.15 |
| 30 | Raise touch targets to 48 dp (avatar, back buttons, chips, quick-grid). | 1.10 |
| 31 | Debounce `_persistCurrentUserData()` and narrow `AppState` rebuild scope. | 1.15 |
| 32 | Supply a full-bleed square iOS icon so Apple's mask doesn't leave a white ring. | 3.13 |
| 33 | Fix the black launch flash in Android dark mode, or ship a real dark theme. | 1.12 |
| 34 | Clear the 22 analyzer issues, including the `share_plus` deprecations. | 1.17 |
| 35 | Add `keyboardType: TextInputType.number` to the family-member age field. | 1.14 |
| 36 | Delete the unreachable insurance and community-challenges screens with their mock data. | 2.9 |
| 37 | Remove the notifications consent toggle and unread badge until push actually exists. | 2.15 |
| 38 | Enable obfuscation and split debug info for release builds. | 4.11 |
| 39 | Wire up or delete the four unused repository write methods. | 4.16 |

---

## 9. Finding counts

| Severity | Count |
|---|---|
| Blocker | 13 |
| Major | 26 |
| Minor | 14 |
| Passing areas confirmed | 18 |

**Nothing in the application code was modified during this audit.** Awaiting explicit instruction before any fixes.
