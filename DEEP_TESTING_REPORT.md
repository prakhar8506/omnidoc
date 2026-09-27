# Cura — Deep Testing Report

> **Date:** 2026-09-19  
> **Surfaces tested:** Flutter web (`web-server` @ `127.0.0.1:8090`) with production Supabase + `ENABLE_DEMO=true`; Android emulator AVD `HealthCompanion_API34` (unstable ADB — install/screenshot incomplete); `flutter test` (20/20 selected suites passed).  
> **Method:** Live UI walkthrough with screenshots under `qa_screenshots/`, plus full `lib/` evidence pass for dummy / snackbar / fabricated clinical claims.

---

## Verdict

The app is **past pure prototype** on auth, Supabase init, lab upload picker, and onboarding entry — but it is **not store-honest yet**. Multiple screens still show **false clinical confidence**, **layout overflows on phone width**, and **UI that claims success without doing the work**.

| Area | Grade | One-line |
|------|-------|----------|
| Auth / demo gate | B | Demo works in debug; release gate exists |
| Onboarding | C | Reachable; overflow + false “Uploaded” badge |
| Consent center | D | Fabricated sync times; toggle/state bugs; overflow |
| Home recovery honesty | D | Fabricated sleep/load/stress fallbacks; “Zero Conflicts” |
| Wearables | C+ | Real Health package; false success SnackBar on quick sync |
| Labs / AI | B- | Edge Functions wired; hardcoded 70% confidence; fake mic |
| Family / booking | D | Demo invites; fake “encrypted” / confirmed booking |
| Community / insurance | F (hidden) | Dead “Coming later” tiles; orphaned fake BlueCross UI |
| Emulator stability | F (infra) | AVD boots then ADB goes offline repeatedly |

---

## What we actually ran

1. **Web app** — `flutter run -d web-server --web-port=8090 --dart-define-from-file=env/production.json --dart-define=ENABLE_DEMO=true`  
   - Log: `Supabase init completed` / repository initialized against hosted project.  
2. **Interactive walkthrough** — splash → Welcome / Sign In → **Try demo mode** → **Clinical baseline** onboarding → Upload sheet → Consent & Permission Center.  
3. **Unit/widget tests** — 20 passed (`phase0`, `app_state`, `ai_copilot`, `widget_test`).  
4. **Android emulator** — AVD launched multiple times; `adb` repeatedly lost the device (`offline` / `not found`) before APK install completed. Treat Android **UI** findings as deferred; **code paths** for Android Health Connect are still reviewed below.

Screenshots: `qa_screenshots/web_*.png` (sign-in, onboarding overflow, upload modal, consent overflows).

---

## A. UI flaws (observed live)

### P0 / blocking visual bugs

| Issue | Evidence | Cause |
|-------|----------|--------|
| **Onboarding lab card: RIGHT OVERFLOWED BY 2.5 PIXELS** | `web_08`–`web_11` | `Row` with title `"Recent Lab or Bloodwork"` + optional `"Uploaded"` chip without `Flexible`/`Expanded` on the title (`onboarding_baseline_screen.dart` ~150–179) |
| **Consent Data Quality card: RIGHT OVERFLOWED BY 21–62 PIXELS** | `web_16`, `web_tab_*`, `web_22`–`web_26` | Hero `Row` puts title column + large `%` side-by-side without flex (`permission_center_screen.dart` ~90–129+) |
| **False “Uploaded” badge** | Onboarding card showed green **Uploaded** after only opening the upload sheet | `setState(() => _labUploaded = true)` runs on **button press**, not after successful upload (`onboarding_baseline_screen.dart` ~188–191) |

### P1 UX / layout

| Issue | Notes |
|-------|--------|
| Demo CTA dominates Sign In | “Try demo mode” is visually primary; fine for debug, dangerous if ever left in a store build |
| Privacy footer contrast | Light grey on gradient — weak WCAG |
| Consent status text truncated | “Sufficient Confi…” cut off beside overflow |
| Phone-width fragility | Both overflows appear at **390×844** — Play/App Store phone screenshots will show yellow/black stripes in **debug**; release hides stripes but **clips content** |

### Working UI (confirmed)

- Splash → Sign In branding (**Cura**), tagline, email/password fields, Sign In / Create Account.  
- Upload modal: Take Photo / Gallery / Browse Files.  
- **Browse Files** opens a real browser file chooser (Playwright intercepted it).  
- Consent toggles change coverage % (75% ↔ 88% observed when steps toggled).

---

## B. Tech flaws

| Issue | Severity | Detail |
|-------|----------|--------|
| Fabricated consent `lastSynced` | P1 | Defaults subtract 12m / 4h / 15m etc. with **no real sync** (`consent_manager.dart` ~75–126) |
| Consent toggle vs warning mismatch | P1 | Runtime: Steps toggle **ON** while banner still **“Manually disabled…”**. Root cause: `PermissionItem.copyWith` uses `dataGapWarning ?? this.dataGapWarning`, so passing `null` on re-enable **keeps** the old warning (`consent_manager.dart` ~33–45, 167–175) |
| Quick-action vitals sync false success | P1 | SnackBar “Vitals synchronized with Apple Health…” without awaiting result (`quick_action_sheet.dart`) |
| Lab confidence hardcoded **70%** | P0 | Not model confidence (`report_interpreter_service.dart`) |
| Recovery tri-stat invents data | P0 | If results null → sleep **7.2h**, consistency **88%**, strain **6.2**, recovery **74**, fake z-scores (`home_screen.dart` ~547–565; `app_state` sleep consistency) |
| Analytics is `debugPrint` only | P2 | No production sink |
| Emulator / ADB flaky on this machine | Ops | Blocks reliable Android UI automation; prefer physical device or CI emulator with software GPU |
| Flutter web a11y | P2 | Semantics off until placeholder clicked; hard for automation |
| Dual auth in debug | P2 | Local SharedPreferences fallback still possible outside release |

**Real tech (working):**

- `supabase_flutter` init against production URL.  
- Edge Function clients for AI chat + lab interpret + delete-account.  
- `health` package WearableService (no invented vitals when empty).  
- Release `AppEnv.validateRequired()`.  
- Demo gated: `kDebugMode && ENABLE_DEMO`.

---

## C. Workflow flaws

```text
Cold start → Splash → Sign In
              ├─ Demo (debug) ──► empty-ish user → Onboarding baseline (forced)
              │                      ├─ Open upload → modal (OK)
              │                      │    └─ set _labUploaded=true immediately (BUG)
              │                      └─ Save baseline → shell
              └─ Email sign-in ──► Supabase (release required)
```

| Flow | Status | Flaw |
|------|--------|------|
| Demo → onboarding | Works | Good empty-ish path |
| Lab upload open | Works | Marks Uploaded too early |
| File browse | Works | Native chooser opens |
| Consent center | Partial | Fake sync times; overflow; toggle/warning desync |
| Book appointment | Local only | SnackBar “confirmed” with hardcoded doctors; slot ignored |
| Join Video | Dead without URL | Dialog only |
| Family invite / QR | Demo-labeled | Still claims “encrypted” in appointments modal |
| Challenges / Insurance home tiles | Blocked | “Coming in a later version” — screens orphaned |
| Journal / AI voice | Fake STT | Canned text / canned ALT query |
| SOS | Partial | Real `tel:` after manual number — not auto-dial contacts |
| Wearable Connect | Partial | Auth success ≠ samples synced |

---

## D. Still dummy / deceptive functions

### Still fake or misleading (fix before store)

| Feature | UI claim | Reality | Sev |
|---------|----------|---------|-----|
| Medication **Zero Conflicts** | Verified badge | Never computed | P0 |
| Home Sleep/Load/Stress when empty | Real scores | Invented fallbacks | P0 |
| Sleep consistency **88%** | Model input | Constant | P0 |
| Lab **Confidence 70%** | Model OCR confidence | Hardcoded | P0 |
| Emergency Medical ID DOB / Organ Donor | User facts | Hardcoded strings | P0 |
| Fall “HARD IMPACT DETECTED” dialog | Sensor event | Practice path only | P0 |
| Symptom triage “clinical assessment” | Protocol engine | Keyword templates | P0 |
| Journal voice transcription | Listening / clinical reflection | Animation + canned prose | P0 |
| Nutrition sodium “moderate” | Recorded intake | Hardcoded meal labels | P0 |
| Prenatal “Verified imaging” | Clinician verified | User upload only | P0 |
| Movement “Clinically Safe” + kcal | Clinical / measured | Marketing + hardcoded kcal | P0 |
| Book visit “Appointment confirmed” | Clinic booking | Local list + fake slots | P0 |
| Family “Send Encrypted Invite” | Encryption / delivery | Local append | P0 |
| Stress sparkline | Autonomic stress | Hardcoded bar heights | P2 |

### Partially real (needs honesty polish)

| Feature | What’s real | What’s still weak |
|---------|-------------|-------------------|
| AI chat | Edge Function when online | Keyword fallback; mic injects canned ALT question |
| Lab OCR | Storage + `interpret-lab` | Offline placeholders; confidence lie |
| Wearables | HealthKit / Health Connect reads | Quick sync SnackBar lies; Connect ≠ sync |
| Maps directions | `url_launcher` search | String clinic name only |
| Clipboard doctor Qs | Real clipboard | — |
| Account delete | Edge Function | — |
| PDF export | Local PDF | FHIR UI wiring incomplete historically |

### Intentionally deferred (honest)

- Home Challenges / Insurance → “Coming in a later version”.  
- Weather pill → “Weather unavailable”.  
- Family Connect screen copy admits local demo.

---

## E. Emulator notes

- AVD `HealthCompanion_API34` (API 34, arm64) **boots** (~40–70s) then often **drops from `adb devices`** (`offline` / gone).  
- Install of `app-release.apk` hung or failed after disconnect.  
- Recommendation: physical Pixel / Galaxy for Health Connect QA; or emulator with `-gpu swiftshader_indirect` + keep a long-lived `adb` session; avoid killing qemu mid-test.

Web + unit tests were used to complete deep functional coverage where the emulator failed.

---

## F. Priority fix list (ordered)

1. **Stop inventing clinical numbers** — remove tri-stat fallbacks, fixed 88% consistency, 70% lab confidence, Zero Conflicts, hardcoded Medical ID.  
2. **Fix overflows** — onboarding lab title row; consent quality `%` row (`Expanded` / wrap).  
3. **Fix `_labUploaded = true` on modal open** — set only after successful upload.  
4. **Consent honesty** — `lastSynced: null` until real sync; clear `dataGapWarning` when re-enabled.  
5. **Await wearable sync** before success SnackBar.  
6. **Relabel booking / family** — “personal reminder” / “local demo”, remove encrypted claims.  
7. **Hide or implement** voice STT, Join Video without URL, Challenges/Insurance entry points.  
8. **Stabilize Android CI path** for emulator or device farm.

---

## G. Pass / fail checklist (this session)

| Check | Result |
|-------|--------|
| App boots with production Supabase | Pass (web) |
| Demo sign-in (debug) | Pass |
| Onboarding reachable | Pass |
| Layout clean at 390px | **Fixed** (onboarding + consent overflows) |
| Lab upload UI opens | Pass |
| File picker | Pass |
| No false Uploaded badge | **Fixed** |
| Consent sync times truthful | **Fixed** (`lastSynced` null until real sync) |
| Consent toggle consistent | **Fixed** (`copyWith` / rebuild clears warning) |
| No fabricated recovery scores | **Fixed** (empty states; no 7.2h/88%/Zero Conflicts) |
| No Zero Conflicts claim | **Fixed** |
| Unit tests smoke | Pass (46) |
| Emulator install + UI tour | **Fail** (ADB) |

---

## H. Production implementation pass (2026-09-19)

Implemented from priority list F:

1. Honesty: empty recovery/tri-stat when no data; sleep consistency 0; OCR confidence from Edge Function only; Medical ID “Not set”; practice fall dialog; triage/nutrition/pregnancy/fitness labels.
2. Overflows: onboarding lab row + consent quality row use `Expanded`.
3. Uploaded badge only after documents increase.
4. Consent: null defaults; toggle rebuilds item so warning clears; sync records real timestamps after wearable sync.
5. Quick-action + wearable connect await `syncVitals()` and show real message.
6. Booking = personal reminder; family = local contact; Join Video only with https URL; Challenges/Insurance tiles removed; voice/mic honest “not available”.
7. Added `.github/workflows/flutter_ci.yml` (analyze + test on PR/push).

Still deferred (ops / Tier 1–2 from scaling plan): hosted Privacy URL, store accounts, Drift/secure storage, Sentry spend alerts, physical-device Health Connect QA.

---

*Related: `PRODUCTION_READINESS_AUDIT.md` (historical), `GLOBAL_PRODUCTION_PROCESS.md` (ops), `LAUNCH_SETUP.md` (cloud status).*
