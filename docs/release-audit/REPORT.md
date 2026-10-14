# Cura release audit

Date: 14 October 2026. Branch: `release-audit`. This is an evidence review, not a legal opinion and not a Play Console submission.

## Summary

| ID | Area | Item | Status | Evidence | Fix / owner |
|---|---|---|---|---|---|
| R1 | Recon | Versions and architecture | PASS | Flutter 3.44.6, Dart 3.12.2. `compileSdk`/`targetSdk` 36 and NDK `28.2.13676358` in Flutter `FlutterExtension.kt` lines 23–42. App id `com.healthcompanion.health_companion`, `minSdk` 26, version `1.0.0+1` in `android/app/build.gradle.kts` 17–31 and `pubspec.yaml` 3. | — |
| A1 | Play | Target API 36 | PASS | `android/app/build.gradle.kts` line 29 uses `flutter.targetSdkVersion`. Flutter tools set that to 36. Verify the number on developer.android.com page “Target API level requirements”. | Founder verifies the page |
| A2 | Play | Edge-to-edge and predictive back on Android 16 | NEEDS-HUMAN | Not run. No Android 16 emulator session in this audit. | QA on an API 36 emulator |
| A3 | Play | 16 KB native alignment | PASS | `scripts/build_play_release.sh` built `app-release.aab` (80.2 MB) on 14 October 2026. Every ELF64 `PT_LOAD` `p_align` in arm64-v8a and x86_64 was 16384 or 65536. The seven armeabi-v7a libraries are 32-bit and were not part of that 64-bit check. | — |
| A4 | Play | App bundle, Play App Signing, version, keystore out of git | NEEDS-HUMAN | `version: 1.0.0+1` in `pubspec.yaml` line 3. `scripts/build_play_release.sh` lines 13–21 builds an AAB with obfuscation and refuses a missing `android/key.properties`. `git check-ignore` shows `android/key.properties` and `env/production.json` ignored. `git log --all -- env/production.json android/key.properties` returned no commits. Play App Signing enrollment and offline keystore copies were not inspected. | Founder confirms Play App Signing and two offline keystore copies |
| A5 | Play | Final applicationId | NEEDS-HUMAN | Id is `com.healthcompanion.health_companion` in `android/app/build.gradle.kts` lines 17 and 27, namespace matches, Kotlin package not separately renamed in this pass. It is permanent after the first upload. | Lawyer / founder decide before first upload |
| A6 | Play | Health apps declaration | NEEDS-HUMAN | Manifest health permissions are lines 12–18 of `AndroidManifest.xml`. `WearableService.extraTypes` now only requests sleep-awake, RMSSD, and walking heart rate, which sit under the declared sleep and heart-rate permissions. Glucose, ECG, temperature, respiratory rate, workouts, and atrial fibrillation burden are no longer read. The Play Console form was not submitted. | Founder completes Play Console > Policy > App content |
| A7 | Play | Health Connect rationale activity | PASS | `AndroidManifest.xml` lines 42–44 and 60–68 declare `ACTION_SHOW_PERMISSIONS_RATIONALE` and `ViewPermissionUsageActivity` with `START_VIEW_PERMISSION_USAGE`. | — |
| A8 | Play | Health Connect limited-use wording | NEEDS-HUMAN | `legal-site/privacy.html` and the in-app privacy screen now say Health Connect data is used only for features the user opens, “including the Health Connect Limited Use requirements,” and is not sold or used for ads. The live page was deployed on 14 October 2026. The exact sentence still needs a check against the current Health Connect policy page and the Play Console flow. | Founder verifies the current policy page |
| A9 | Play | Data safety form | NEEDS-HUMAN | Draft rows are in `data-inventory.csv`. The form itself was not submitted. | Founder copies the CSV into Play Console and checks it |
| A10 | Play | Privacy policy URL and inventory match | PASS | Public URL `https://cura-health-legal.vercel.app/privacy` returned HTTP 200 on 14 October 2026. The page date is 14 October 2026. Google sign-in is described as on-phone only. Wearable types match the manifest. Encrypted local storage is described as excluded from backup. | Founder still checks the Play Console URL field |
| A11 | Play | Account deletion in app and on the web | NEEDS-HUMAN | In-app delete erases the phone copy for Google and local accounts without a Supabase token (`app_state.dart` `deleteAccount`). Email accounts still call `delete-account` and keep the phone copy if that call fails. Public page `https://cura-health-legal.vercel.app/delete` returned HTTP 200. `delete-account` was deployed to project `fpvcyxjatjajsaziblzg` on 14 October 2026. A live test account was not deleted. | Founder deletes a test account |
| A12 | Play | Demo sign-in absent from release | NEEDS-HUMAN | Source gate: `app_env.dart` lines 46–47 (`kDebugMode && ENABLE_DEMO`) and `sign_in_screen.dart` lines 200–230. `signInDemoAccount` throws unless that flag is on (`app_state.dart` lines 447–450). A current release APK was not scanned for the string. | Founder builds release and searches the binary; put real reviewer credentials in Play notes |
| A13 | Play | 18+, no ads, IARC | NEEDS-HUMAN | No ad SDK in `pubspec.yaml` dependencies (lines 9–37). Age copy exists. IARC answers were not submitted. | Founder completes the questionnaire in Play Console |
| A14 | Play | 12 testers / 14 days | NEEDS-HUMAN | Not observable in the repo. Calendar draft is `release-plan.md`. Verify the current rule in Play Console. | Founder |
| A15 | Play | Sensitive permission disclosures | NEEDS-HUMAN | Broad photo permissions are removed with `tools:node="remove"` (`AndroidManifest.xml` lines 7–9). Camera and microphone remain. A per-permission prominent disclosure screen was not found for those two. Health Connect has a rationale intent. | Founder adds pre-prompts or confirms existing sheets cover camera and microphone |
| B1 | Brand | Name “Cura” | NEEDS-HUMAN | App label `AndroidManifest.xml` line 18. No trademark search was run. Checklist is in `risk-register.md`. | Trademark attorney before branding spend |
| B2 | Brand | Third-party marks | NEEDS-HUMAN | Privacy text names Apple Health and Health Connect (`privacy.html` line 28). No logo files of those brands were found under `assets/`. | Lawyer reviews listing copy |
| B3 | Brand | Domain and support email | NEEDS-HUMAN | Contact string `support@cura.health` in `privacy.html` line 61. Domain registration and inbox ownership were not checked. | Founder |
| B4 | Brand | Original icon and screenshots | NEEDS-HUMAN | `assets/ICON_SOURCES.md`. Store screenshots are not in the repo. | Founder confirms authorship and uses sample data |
| C1 | Copyright | Dependency licences | PASS | Direct and transitive `LICENSE` files in the pub cache were scanned. No GPL/AGPL/LGPL/SSPL hit in the first 1500 characters. Table in `third-party-licenses.md`. In-app screen added in `386e9ca`. | Keep `showLicensePage` |
| C2 | Copyright | Plus Jakarta Sans OFL | NEEDS-HUMAN | Font is loaded via `google_fonts` (`pubspec.yaml` line 16). `NOTICES.md` names SIL OFL 1.1. The font’s `OFL.txt` is not in the repo or in the `google_fonts` 6.3.3 package. | Vendor `OFL.txt` before the store build |
| C3 | Copyright | Icons | NEEDS-HUMAN | Two PNGs have no author or licence file. See `assets/ICON_SOURCES.md`. | Founder records the source |
| C4 | Copyright | Mood instrument | NEEDS-HUMAN | `lib/core/mental/mood_check.dart` lines 47–65 uses the PHQ-style scale “Not at all / A few days / More than half the days / Nearly every day” and eight paraphrased items including self-harm. No licence or attribution in the file. | Clinician and IP counsel confirm whether this is PHQ-9 and what use is allowed |
| C5 | Copyright | Health content origin | NEEDS-HUMAN | No content-bank register with sources was in the repo. | Clinician review; see decisions |
| D1 | Patents | Similarity register | NEEDS-HUMAN | `risk-register.md`. This audit does not clear patents. | Patent attorney |
| E1 | Medical | Diagnostic claim grep | NEEDS-HUMAN | User-facing lines found include mood check “cannot diagnose depression” (`mood_check_screen.dart` line 127) and nutrition “does not diagnose” (`nutrition_hydration_screen.dart` line 369). System prompts still discuss medicines (`health-ai-chat/index.ts` lines 20–26, `interpret-lab/index.ts` lines 70–80). Copy was not rewritten. | Lawyer and clinician |
| E2 | Medical | Regulated-feature list | NEEDS-HUMAN | Triage urgency bands, AI lab interpretation, cycle/pregnancy logs, glucose/BP display. No CDSCO/FDA determination was made. | Regulatory counsel |
| E3 | Medical | Emergency copy | PASS | Mood screen names 112, 911/988, AASRA, and iCall (`mood_check_screen.dart` line 127). | Keep visible |
| F1 | Privacy | Inventory vs policy vs consent | PASS | Hosted and in-app privacy text dated 14 October 2026. Google sign-in stays on the phone. Cloud sync is described only for an email/Supabase session. Wearable list matches the declared Health Connect types. | — |
| F2 | Privacy | Age gate cannot be bypassed | PASS | Sign-in starts `_termsAccepted` false and blocks email, Google, and the debug demo button until the 18+ checkbox is on (`sign_in_screen.dart`). Sign-up already gated Google. | — |
| F3 | Privacy | DPDP notice, grievance, retention, transfers | NEEDS-HUMAN | Policy has 18+, deletion, Sentry, and names OpenAI and Gemini (`privacy.html` lines 38–40). No grievance officer. No retention period in days. Commencement of the rules was not determined. | Lawyer |
| F4 | Privacy | Health data in logs | NEEDS-HUMAN | Sentry `beforeSend` in `main.dart` clears user, request, extra, and breadcrumbs, and `sendDefaultPii` is false. `deleteAccount` no longer prints the response body. Other `debugPrint` calls remain, including `supabase_repository.dart` `fetchHealthEvents error: $e`. Whether `$e` contains row data was not proven. | Founder reviews remaining debug prints |
| F5 | Privacy | Local health store | PASS | Profile, account list, session id, event log, and consent go through `SecureStore` (`flutter_secure_storage` 11.2.0, Android keystore AES-GCM). A legacy SharedPreferences value is copied once and then deleted. Dark mode and a pending family code remain in SharedPreferences and are not health records. | — |
| G1 | AI | Provider terms and no-training | NEEDS-HUMAN | Policy states providers are not permitted to train on the data (`privacy.html` line 40). The contracts were not in the repo. | Founder attaches the DPA |
| G2 | AI | Report incorrect AI output | PASS | Chat replies and lab explanations show “AI draft” and a Report button that opens a mail to support@cura.health (`ai_draft_notice.dart`, `ai_chat_sheet.dart`, `lab_reports_screen.dart`). | — |
| G3 | AI | Lab path belongs to caller | PASS | `interpret-lab/index.ts` lines 166–167 reject a `storage_path` that does not start with `${user.id}/`. | — |
| G4 | AI | Prompt injection, rate limit, size cap | NEEDS-HUMAN | Deployed `health-ai-chat` rejects messages over 4000 characters, keeps context to 8000 characters, and tells the model that CONTEXT is untrusted. Deployed `interpret-lab` rejects `image_base64` over 8,000,000 characters. No per-user rate limit. CORS remains `*`. | Founder adds a rate limit if the current Play or provider terms require one |
| H1 | Manifest | Unused permissions | NEEDS-HUMAN | `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, and `READ_EXTERNAL_STORAGE` are `tools:node="remove"` so a plugin cannot merge them back. Uploads still use `ImagePicker` and `FilePicker`. A picker test on a device was not run in this pass. `CALL_PHONE`, location, and exact-alarm permissions are absent. | Founder tests photo and file pick on a phone |
| H2 | Manifest | Backup | PASS | `data_extraction_rules.xml` excludes `sharedpref` from cloud backup and device transfer. Privacy text no longer says a reinstall restores logs. `allowBackup` stays true so the rules file is applied. Keystore keys are not relied on to survive uninstall. | — |
| H3 | Manifest | Cleartext and user CAs | PASS | `usesCleartextTraffic="false"` and `networkSecurityConfig` (`AndroidManifest.xml` lines 22–23). Config file trusts `system` certificates only. Debug manifest still sets cleartext. Commit `8429071`. | — |
| H4 | Manifest | Exported components | PASS | Exported: launcher `MainActivity` and the Health Connect alias which requires `START_VIEW_PERMISSION_USAGE`. FileProvider `exported="false"` (lines 73–76). | — |
| H5 | Manifest | Deep links | NEEDS-HUMAN | `cura://auth-callback`, `cura://auth`, `cura://family-invite` (`AndroidManifest.xml` lines 46–58). No `autoVerify` https App Link. Parameter checks were not fully traced. | Engineer |
| I1 | Client | Secrets in git | NEEDS-HUMAN | `gitleaks` and `trufflehog` are not installed. Tracked example file `env/production.json.example` has placeholders only. Ignored files were not printed. | Run a secret scanner on full history and rotate anything it finds |
| I2 | Client | Session storage | PASS | Session id and the local account list, including the password hash, are written with `SecureStore` (`auth_service.dart`). | — |
| I3 | Client | Screenshot block | NEEDS-HUMAN | No `FLAG_SECURE` in the repo. | Founder |
| I4 | Client | Release obfuscation script | PASS | `scripts/build_play_release.sh` lines 18–21. This audit did not produce a new AAB. | Rebuild before upload |
| J1 | Backend | RLS in migrations | PASS | Enabled with `auth.uid()` policies in `20260916000001_row_level_security.sql` and `20260918000000_production_domain_tables.sql`. | Confirm the hosted project has these migrations applied |
| J2 | Backend | Two-user test | FAIL | Not executed. | Engineer with two accounts |
| J3 | Backend | Private buckets | PASS | `lab-uploads`, `avatars`, `exports` inserted with `public` false (`20260918000001_storage_buckets.sql` lines 2–7). Policies key off `auth.uid()`. | Hosted project must match |
| J4 | Backend | `family_links` / `device_trials` | PASS | RLS enabled and no client policies (`20261013010000_family_links.sql` lines 36–37, `20261013000000_device_trials.sql` line 7), so the Data API should deny authenticated reads. Service role bypasses that. Not tested live. | Confirm live |
| J5 | Backend | `delete-account` JWT | PASS | Function calls `getUser()` and returns 401 without a user (`delete-account/index.ts` lines 82–88). It does not accept a user id from the body for the delete target. | — |
| J6 | Backend | `delete-account` when service role is missing | PASS | Deployed function returns HTTP 503 `{ ok: false, error }` and does not include `user_id`. A missing-secret response was not provoked on the live project. | — |
| J7 | Backend | Function JWT deploy flags and rate limits | NEEDS-HUMAN | `supabase/config.toml` has no `[functions.*] verify_jwt` entries. Live flags were not queried. | Confirm in the Supabase dashboard |
| J8 | Backend | Separate prod and dev projects | NEEDS-HUMAN | Local `project_id = "health_companion"` (`config.toml` line 5). The release build reads `env/production.json`, which is gitignored. | Founder |
| K1 | Release | Current AAB on a device | NEEDS-HUMAN | Not installed from this branch. | `scripts/build_play_release.sh` then Play pre-launch report |
| L1 | Listing | Store text and screenshots | NEEDS-HUMAN | Listing text is not in the repo. | Founder, no diagnosis claims |
| M1 | QA | Device matrix | FAIL | Not run in this audit. | QA |

## Launch blockers

Still open after the 14 October 2026 fixes:

- Play Console forms, including the health-apps declaration, were not submitted (A6, A9).
- Health Connect limited-use sentence is in the policy. The current Health Connect policy page was not opened (A8).
- A live test account was not deleted (A11).
- Camera and microphone still have no separate prominent disclosure. Photo permissions are stripped in the release manifest (A15, H1). A picker test on a phone was not run.
- No per-user AI rate limit. CORS on the functions is still `*` (G4).
- Two-user RLS test not done (J2).
- Device QA matrix not run: Android 10–12, 14, 16 emulator, tablet, Hindi, large text, dark and light, offline, and fresh install (M1).

## Fixed on this branch

| Commit | Change |
|---|---|
| `8429071` | Release network security config trusts system CAs only and is referenced from the manifest. |
| `386e9ca` | Profile sheet opens Flutter’s open-source licences page. `NOTICES.md` and `assets/ICON_SOURCES.md` added. |
| this pass | Encrypted local health store, backup excludes shared preferences, photo permissions removed, sign-in 18+ gate, wearable reads limited to declared types, privacy and `/delete` published, AI draft report and size caps, Sentry scrub, release AAB 16 KB check passed for ELF64. |

## Needs a person

Trademark clearance, patent freedom-to-operate, CDSCO/FDA/MDR, DPDP commencement, PHQ licence, clinician review of health text, Play Console forms, Play App Signing, keystore backups, secret-history scan, hosted Supabase JWT flags, Android 16 emulator, the device matrix, and the 12-tester clock. Grievance contact in the policy is support@cura.health. No person’s name was added.

## Architecture (one page)

Cura is a Flutter app. The phone keeps the health profile, session id, event log, and consent in keystore-backed storage. Those values are excluded from Android cloud backup and device transfer. Email/password can talk to Supabase Auth. Google sign-in stores a local account and does not create a Supabase auth user. Wearable reads go through the `health` plugin and only the Health Connect types declared in the manifest. Lab images can be uploaded to the private `lab-uploads` bucket and interpreted by the `interpret-lab` function, which calls OpenAI or Gemini. Chat uses `health-ai-chat`. Crash traces can go to Sentry when a DSN is compiled in, with user, request, extra, and breadcrumbs stripped. Razorpay checkout uses `razorpay-order` and `razorpay-verify`. Family links are written only by the `family-circle` function with the service role. Legal pages, including `/delete`, are the static site `cura-health-legal.vercel.app`.

## Go / no-go

**No-go for Play production.** The 14 October 2026 app bundle exists, its 64-bit libraries meet 16 KB `PT_LOAD` alignment, and the code and privacy mismatches listed above were fixed. Store release still needs the Play Console forms, a live account-deletion test, the device matrix, and the legal reviews below.

Not verified, and not cleared: trademark, patents, “legally compliant”, clinician review, live Play Console, live Supabase JWT flags, a two-user RLS test, and the device matrix.
