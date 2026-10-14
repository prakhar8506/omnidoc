# Cura release audit

Date: 14 October 2026. Branch: `release-audit`. This is an evidence review, not a legal opinion and not a Play Console submission.

## Summary

| ID | Area | Item | Status | Evidence | Fix / owner |
|---|---|---|---|---|---|
| R1 | Recon | Versions and architecture | PASS | Flutter 3.44.6, Dart 3.12.2. `compileSdk`/`targetSdk` 36 and NDK `28.2.13676358` in Flutter `FlutterExtension.kt` lines 23–42. App id `com.healthcompanion.health_companion`, `minSdk` 26, version `1.0.0+1` in `android/app/build.gradle.kts` 17–31 and `pubspec.yaml` 3. | — |
| A1 | Play | Target API 36 | PASS | `android/app/build.gradle.kts` line 29 uses `flutter.targetSdkVersion`. Flutter tools set that to 36. Verify the number on developer.android.com page “Target API level requirements”. | Founder verifies the page |
| A2 | Play | Edge-to-edge and predictive back on Android 16 | NEEDS-HUMAN | Not run. No Android 16 emulator session in this audit. | QA on an API 36 emulator |
| A3 | Play | 16 KB native alignment | FAIL | Check not run. On-disk bundle `build/app/outputs/bundle/release/app-release.aab` is dated 18 Sep 2026 and is not this branch. | Rebuild AAB, then run the ELF alignment check |
| A4 | Play | App bundle, Play App Signing, version, keystore out of git | NEEDS-HUMAN | `version: 1.0.0+1` in `pubspec.yaml` line 3. `scripts/build_play_release.sh` lines 13–21 builds an AAB with obfuscation and refuses a missing `android/key.properties`. `git check-ignore` shows `android/key.properties` and `env/production.json` ignored. `git log --all -- env/production.json android/key.properties` returned no commits. Play App Signing enrollment and offline keystore copies were not inspected. | Founder confirms Play App Signing and two offline keystore copies |
| A5 | Play | Final applicationId | NEEDS-HUMAN | Id is `com.healthcompanion.health_companion` in `android/app/build.gradle.kts` lines 17 and 27, namespace matches, Kotlin package not separately renamed in this pass. It is permanent after the first upload. | Lawyer / founder decide before first upload |
| A6 | Play | Health apps declaration | NEEDS-HUMAN | Manifest health permissions are lines 9–15 of `AndroidManifest.xml`. Code also reads glucose, ECG, temperature, respiratory rate, workouts, and atrial fibrillation burden in `wearable_service.dart` lines 84–93 and 384–412. Those types are not in the manifest or in `legal-site/privacy.html` line 28. | Founder completes Play Console > Policy > App content and aligns code, manifest, and policy |
| A7 | Play | Health Connect rationale activity | PASS | `AndroidManifest.xml` lines 42–44 and 60–68 declare `ACTION_SHOW_PERMISSIONS_RATIONALE` and `ViewPermissionUsageActivity` with `START_VIEW_PERMISSION_USAGE`. | — |
| A8 | Play | Health Connect limited-use wording | FAIL | `legal-site/privacy.html` lines 28 and 34 say wearable data is not sold and not used for ads. The phrase “limited use” is not in that file (`rg` for “limited use” and “Health Connect” on the legal site). | Founder / lawyer add the current Health Connect wording, then verify the Play Console flow |
| A9 | Play | Data safety form | NEEDS-HUMAN | Draft rows are in `data-inventory.csv`. The form itself was not submitted. | Founder copies the CSV into Play Console and checks it |
| A10 | Play | Privacy policy URL and inventory match | FAIL | Public URL constant `lib/core/branding/app_brand.dart` lines 7–8: `https://cura-health-legal.vercel.app/privacy`. Mismatches listed under Privacy below. Last updated line is 28 September 2026 (`privacy.html` line 14). | Founder updates the page before listing |
| A11 | Play | Account deletion in app and on the web | FAIL | In-app delete exists in the profile sheet. Web text is an email instruction in `legal-site/contact.html` line 22, not a deletion form. `delete-account/index.ts` lines 82–86 require a Supabase `getUser()` JWT. Google sign-in does not create that user (`auth_service.dart` lines 274–275). A live test account was not deleted in this audit. | Founder: web deletion URL, and make delete cover the Google/local account |
| A12 | Play | Demo sign-in absent from release | NEEDS-HUMAN | Source gate: `app_env.dart` lines 46–47 (`kDebugMode && ENABLE_DEMO`) and `sign_in_screen.dart` lines 200–230. `signInDemoAccount` throws unless that flag is on (`app_state.dart` lines 447–450). A current release APK was not scanned for the string. | Founder builds release and searches the binary; put real reviewer credentials in Play notes |
| A13 | Play | 18+, no ads, IARC | NEEDS-HUMAN | No ad SDK in `pubspec.yaml` dependencies (lines 9–37). Age copy exists. IARC answers were not submitted. | Founder completes the questionnaire in Play Console |
| A14 | Play | 12 testers / 14 days | NEEDS-HUMAN | Not observable in the repo. Calendar draft is `release-plan.md`. Verify the current rule in Play Console. | Founder |
| A15 | Play | Sensitive permission disclosures | FAIL | Camera, microphone, and photos are declared (`AndroidManifest.xml` lines 3–6). A per-permission prominent disclosure screen was not found for each of them. Health Connect has a rationale intent. | Founder adds pre-prompts or confirms existing sheets cover each permission |
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
| F1 | Privacy | Inventory vs policy vs consent | FAIL | Policy says records sync to a private cloud account (`privacy.html` line 34 and 48). Google sign-in is on-device only (`auth_service.dart` lines 274–275). Policy wearable list omits types the code still queries. | Founder aligns policy and product |
| F2 | Privacy | Age gate cannot be bypassed | FAIL | Sign-up Google button checks the 18+ box (`sign_up_screen.dart` lines 132–137). Sign-in Google button does not (`sign_in_screen.dart` lines 173–178; no `_termsAccepted`). Checkbox on sign-up starts false (line 32). | Founder decides the sign-in gate |
| F3 | Privacy | DPDP notice, grievance, retention, transfers | NEEDS-HUMAN | Policy has 18+, deletion, Sentry, and names OpenAI and Gemini (`privacy.html` lines 38–40). No grievance officer. No retention period in days. Commencement of the rules was not determined. | Lawyer |
| F4 | Privacy | Health data in logs | NEEDS-HUMAN | `debugPrint` calls log errors and, in `supabase_repository.dart` line 352, `fetchHealthEvents error: $e`. Whether `$e` contains row data was not proven. Sentry is initialised in `main.dart` line 57. `beforeSend` scrubbing was not found in that call. | Engineer scrubs breadcrumbs before launch |
| F5 | Privacy | Local health store | FAIL | Profile JSON is `SharedPreferences` (`user_data_service.dart` lines 11–26). No `flutter_secure_storage` or SQLCipher (`rg` over `lib` and `android` found no matches). | Founder decision in `decisions-for-founder.md` |
| G1 | AI | Provider terms and no-training | NEEDS-HUMAN | Policy states providers are not permitted to train on the data (`privacy.html` line 40). The contracts were not in the repo. | Founder attaches the DPA |
| G2 | AI | Report incorrect AI output | FAIL | No in-app flag/report control was found for chat or lab drafts. | Founder adds a report action and an “AI draft” label |
| G3 | AI | Lab path belongs to caller | PASS | `interpret-lab/index.ts` lines 166–167 reject a `storage_path` that does not start with `${user.id}/`. | — |
| G4 | AI | Prompt injection, rate limit, size cap | FAIL | Chat forwards `body.context` as JSON (`health-ai-chat/index.ts` lines 94–99). No per-user rate limit in that file. CORS is `*` (lines 14–17). | Engineer, listed as a decision if it changes behaviour |
| H1 | Manifest | Unused permissions | FAIL | `READ_MEDIA_IMAGES` and `READ_EXTERNAL_STORAGE` are declared (`AndroidManifest.xml` lines 5–6) while uploads use `ImagePicker` and `FilePicker` (`upload_report_modal.dart` lines 38 and 85). `CALL_PHONE`, location, and exact-alarm permissions are absent (`rg` found no matches). | Founder approves removing broad photo permission after a picker test |
| H2 | Manifest | Backup | FAIL | `allowBackup="true"` (`AndroidManifest.xml` line 21). Extraction rules exclude root, file, database, and external, and do not exclude `sharedpref` (`data_extraction_rules.xml` lines 7–18). This matches the current privacy sentence (`privacy.html` line 48) and conflicts with a “exclude all app data” rule. | Founder decision; do not flip without rewriting the privacy page |
| H3 | Manifest | Cleartext and user CAs | PASS | `usesCleartextTraffic="false"` and `networkSecurityConfig` (`AndroidManifest.xml` lines 22–23). Config file trusts `system` certificates only. Debug manifest still sets cleartext. Commit `8429071`. | — |
| H4 | Manifest | Exported components | PASS | Exported: launcher `MainActivity` and the Health Connect alias which requires `START_VIEW_PERMISSION_USAGE`. FileProvider `exported="false"` (lines 73–76). | — |
| H5 | Manifest | Deep links | NEEDS-HUMAN | `cura://auth-callback`, `cura://auth`, `cura://family-invite` (`AndroidManifest.xml` lines 46–58). No `autoVerify` https App Link. Parameter checks were not fully traced. | Engineer |
| I1 | Client | Secrets in git | NEEDS-HUMAN | `gitleaks` and `trufflehog` are not installed. Tracked example file `env/production.json.example` has placeholders only. Ignored files were not printed. | Run a secret scanner on full history and rotate anything it finds |
| I2 | Client | Session storage | FAIL | Session id key `hc_session_user_id` in SharedPreferences (`auth_service.dart` lines 20 and 269–270). Password hash is also stored for local accounts (lines 182 and 264–265). | Founder decision |
| I3 | Client | Screenshot block | NEEDS-HUMAN | No `FLAG_SECURE` in the repo. | Founder |
| I4 | Client | Release obfuscation script | PASS | `scripts/build_play_release.sh` lines 18–21. This audit did not produce a new AAB. | Rebuild before upload |
| J1 | Backend | RLS in migrations | PASS | Enabled with `auth.uid()` policies in `20260916000001_row_level_security.sql` and `20260918000000_production_domain_tables.sql`. | Confirm the hosted project has these migrations applied |
| J2 | Backend | Two-user test | FAIL | Not executed. | Engineer with two accounts |
| J3 | Backend | Private buckets | PASS | `lab-uploads`, `avatars`, `exports` inserted with `public` false (`20260918000001_storage_buckets.sql` lines 2–7). Policies key off `auth.uid()`. | Hosted project must match |
| J4 | Backend | `family_links` / `device_trials` | PASS | RLS enabled and no client policies (`20261013010000_family_links.sql` lines 36–37, `20261013000000_device_trials.sql` line 7), so the Data API should deny authenticated reads. Service role bypasses that. Not tested live. | Confirm live |
| J5 | Backend | `delete-account` JWT | PASS | Function calls `getUser()` and returns 401 without a user (`delete-account/index.ts` lines 82–88). It does not accept a user id from the body for the delete target. | — |
| J6 | Backend | `delete-account` when service role is missing | FAIL | Lines 95–112 return HTTP 503 and include `user_id` in the JSON, and perform no delete. | Engineer: do not echo the id; fail closed |
| J7 | Backend | Function JWT deploy flags and rate limits | NEEDS-HUMAN | `supabase/config.toml` has no `[functions.*] verify_jwt` entries. Live flags were not queried. | Confirm in the Supabase dashboard |
| J8 | Backend | Separate prod and dev projects | NEEDS-HUMAN | Local `project_id = "health_companion"` (`config.toml` line 5). The release build reads `env/production.json`, which is gitignored. | Founder |
| K1 | Release | Current AAB on a device | NEEDS-HUMAN | Not installed from this branch. | `scripts/build_play_release.sh` then Play pre-launch report |
| L1 | Listing | Store text and screenshots | NEEDS-HUMAN | Listing text is not in the repo. | Founder, no diagnosis claims |
| M1 | QA | Device matrix | FAIL | Not run in this audit. | QA |

## Launch blockers

These are FAIL items in A, F, H, I, and J:

- 16 KB alignment not checked on a current bundle (A3).
- Health data types in code do not match the privacy list (A6, F1).
- Health Connect “limited use” text missing (A8).
- Privacy policy does not match local Google sign-in (F1).
- Account deletion does not cover a Google/local account, and was not proven against a test user (A11).
- Sign-in with Google skips the 18+ checkbox (F2).
- Health data and session id sit in SharedPreferences (F5, I2).
- `READ_MEDIA_IMAGES` is still declared (H1).
- Backup includes shared preferences (H2), which is intentional today and still a Play/privacy review item.
- No in-app way to report a bad AI answer (G2, related).
- `delete-account` can return the user id and skip deletion when the service role secret is absent (J6).
- Two-user RLS test not done (J2).
- Device QA matrix not run (M1).

## Fixed on this branch

| Commit | Change |
|---|---|
| `8429071` | Release network security config trusts system CAs only and is referenced from the manifest. |
| `386e9ca` | Profile sheet opens Flutter’s open-source licences page. `NOTICES.md` and `assets/ICON_SOURCES.md` added. |

## Needs a person

Trademark clearance, patent freedom-to-operate, CDSCO/FDA/MDR, DPDP commencement and grievance officer, PHQ licence, clinician review of health text, Play Console forms, Play App Signing, keystore backups, secret-history scan, hosted Supabase JWT flags, Android 16 emulator, 16 KB check, and the 12-tester clock.

## Architecture (one page)

Cura is a Flutter app. The phone keeps the health profile in SharedPreferences (`hc_user_data_*`, session id `hc_session_user_id`). Email/password can talk to Supabase Auth. Google sign-in stores a local account and does not create a Supabase auth user. Wearable reads go through the `health` plugin and Health Connect. Lab images can be uploaded to the private `lab-uploads` bucket and interpreted by the `interpret-lab` function, which calls OpenAI or Gemini. Chat uses `health-ai-chat`. Crash traces can go to Sentry when a DSN is compiled in. Razorpay checkout uses `razorpay-order` and `razorpay-verify`. Family links are written only by the `family-circle` function with the service role. Legal pages are the static site `cura-health-legal.vercel.app`.

## Go / no-go

**No-go for Play production** on what was verified here. Target SDK in source is 36, demo UI is gated in source, RLS migrations exist, storage buckets are defined as private, cleartext is off, and the keystore file is gitignored. The blockers above are still open.

Not verified, and not cleared: trademark, patents, “legally compliant”, clinician review, live Play Console, live Supabase project settings, a fresh release AAB, and the device matrix.
