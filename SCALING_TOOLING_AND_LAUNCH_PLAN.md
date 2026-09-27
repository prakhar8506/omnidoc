# Cura — Tooling, Caching, and Launch Sequencing Plan

> **Purpose:** Turn the current state described in `GLOBAL_PRODUCTION_PROCESS.md` into an ordered, actionable plan — diagnose the broken prescription/lab scan, decide on media/CDN tooling, define a caching strategy, and sequence remaining work for a global Play Store + App Store launch.
> **Audience:** Engineering, product, launch/ops.
> **Date:** 2026-09-19

Related docs (do not duplicate; link instead):

| Document | Role |
|----------|------|
| `GLOBAL_PRODUCTION_PROCESS.md` | Current stack, process, and feature-honesty inventory |
| `PRODUCTION_READINESS_AUDIT.md` | Historical honesty audit (2026-09-16) |
| `ANTIGRAVITY_PRODUCTION_LAUNCH_PROMPT.md` | Phased implementation program (0–7) |
| `LAUNCH_SETUP.md` | Live cloud checklist |

---

## 1. WHERE THINGS STAND

Most of what was open in the September 16 audit is closed in source: fail-fast env validation, LLM keys server-side only in Edge Functions, Health Connect/HealthKit as the sole wearable path (no fake "any smartwatch via Bluetooth" claim), and the honesty rule ("hide or label 'later version'; never snackbar-fake success") written directly into process, not left to memory.

What's left is almost entirely **process and tooling**, not fake features: no CI, no hosted Privacy/Terms URL, no product analytics, one confirmed broken feature (prescription/lab scan), and a handful of "not in the toolchain yet" items already self-identified in `GLOBAL_PRODUCTION_PROCESS.md` §4.5. This document turns that list into an order of operations.

---

## 2. PRESCRIPTION / LAB SCAN — DIAGNOSE BEFORE FIXING

Do not guess at a fix. The failure could be at any of four layers, and each has a completely different remedy.

### 2.1 Diagnostic table

| Failure point | How to confirm | Likely cause |
|---|---|---|
| Upload never lands in Storage | Check `lab-uploads/{user_id}/…` in Supabase Storage right after a failed scan | Client navigates away before upload confirms; no retry/upload-complete check |
| `interpret-lab` throws before returning | `supabase functions logs interpret-lab` | Function timeout on a large image; vision JSON schema rejecting a response that doesn't match exactly |
| Function succeeds, output is wrong | Compare raw model output (log it if not already) against what's shown in-app | **Handwriting.** Vision LLMs handle printed lab reports well and handwritten prescriptions poorly — this may not be a bug at all |
| Result is correct, UI mis-renders it | Log the raw response and diff against the rendered screen | Client-side parsing/mapping bug between the structured JSON and the widget tree |

### 2.2 Diagnostic procedure (in order)

1. [ ] Pull `interpret-lab` function logs for the last 10 real failed attempts. Note whether the function even ran, and if it ran, whether it threw or returned successfully.
2. [ ] Re-test with a **known-clean printed lab report image** (not a prescription) to isolate whether the pipeline itself works at all.
3. [ ] Separately re-test with an actual **handwritten prescription photo**. If the printed-report test passes and the handwritten test fails, this is very likely an accuracy limitation, not a defect.
4. [ ] Check Storage directly to confirm the file upload step completes before the function is invoked (rule out a race condition).
5. [ ] If the function returns a response, log the raw structured JSON and compare it to what the UI actually displays, to rule out a client-side rendering bug.

### 2.3 Decision point

- If the root cause is upload timing, function timeout, or a client rendering bug → fix directly; these are ordinary engineering bugs.
- If the root cause is genuinely handwriting-recognition accuracy → **rescope the v1 claim** rather than ship a feature that silently fails. Per the existing honesty rule in `GLOBAL_PRODUCTION_PROCESS.md`: "if a feature cannot be real for v1, hide or label 'later version' — do not snackbar-fake success." Concretely:
  - [ ] Update in-app copy and store listing language from "scan your prescription" to "scan printed lab reports and pharmacy labels" (or similar accurate scope) if handwriting isn't reliably solvable before launch.
  - [ ] Add an honest low-confidence path: when OCR confidence is low, show the raw image and let the user manually confirm/correct extracted values instead of guessing silently.

---

## 3. MEDIA & STORAGE TOOLING DECISION

Split by data sensitivity — do not apply the same tool to lab/prescription images and to avatars.

### 3.1 Decision matrix

| Asset type | Where it should live | Add Cloudinary / CDN? | Why |
|---|---|---|---|
| Lab reports / prescriptions | Supabase Storage, private bucket, scoped to `auth.uid()` (already correct) | **No** | These are sensitive medical documents viewed once or twice by their owner. A third-party CDN/transform vendor adds a new subprocessor to disclose in the Privacy Policy and a new place PHI-adjacent images live, for a benefit (fast repeated delivery) that doesn't apply here |
| Avatars | Supabase Storage private bucket (current) | **Maybe — check Supabase's own image-transformation feature on paid plans first** | Public-ish, viewed repeatedly, genuinely benefits from resize/format conversion + edge caching. If Supabase's built-in transforms cover this, skip adding a vendor entirely |
| Marketing / store screenshots, branding assets | Public asset host (Cloudinary is a reasonable fit here) | **Yes, if useful** | Not sensitive; benefits fully apply, no privacy-policy implications |

### 3.2 Action items

- [ ] Check current Supabase plan/feature set for built-in Storage image transformations (resize-on-the-fly via URL params) before evaluating Cloudinary at all.
- [ ] If Supabase transforms don't cover the avatar case and avatar traffic/volume justifies it, add Cloudinary scoped **only** to avatars and marketing assets — never lab/prescription buckets.
- [ ] Do not treat this as a launch blocker either way — it's a "once you have usage data" item (see Section 5).

---

## 4. CACHING STRATEGY

| Cache type | What it covers | Approach / tool | Priority |
|---|---|---|---|
| Client image cache | Avatars, lab thumbnails | `cached_network_image` package | Before real users rely on it |
| AI/OCR result cache | `interpret-lab` output | Already persisted to `biomarker_results` — **confirm** client reads from this table first and only calls the Edge Function for genuinely new uploads | Verify now (cheap, high-value check) |
| Local structured cache | Per-user profile JSON, event queries currently in `SharedPreferences` | Migrate to Drift or Isar — also sets up the offline outbox queue already flagged as a gap | Before real users rely on it |
| LLM cost cache | Repeated/FAQ-style wellness chat prompts | Short-TTL cache keyed on a normalized prompt | Once you have usage data justifying the spend |
| Never cache | Any user-specific health data at a CDN/edge layer | N/A — caching here would actively work against the privacy posture | N/A — explicit exclusion |

---

## 5. LAUNCH SEQUENCING

### 5.1 Tier 1 — Blocks submission (do first)

- [ ] Diagnose and fix (or honestly rescope) the prescription/lab scan (Section 2)
- [ ] Host Privacy Policy + Terms at a **public URL** — stores require a URL, not in-app copy
- [ ] Google Play Console app created; Data Safety form completed; Health Connect permissions declared
- [ ] Apple Developer Program account; App Store Connect record created; HealthKit review notes prepared
- [ ] Minimal CI: PR-gated `flutter analyze` + `flutter test` (no more laptop-only releases)
- [ ] Run the existing QA matrix (`GLOBAL_PRODUCTION_PROCESS.md` §8) against an actual **release** AAB/IPA, not a debug build
- [ ] Internal/closed testing tracks live on both stores (Play Internal → Closed; TestFlight) before any public release

### 5.2 Tier 2 — Should exist before real users rely on it

- [ ] Migrate remaining sensitive local storage from `SharedPreferences` to `flutter_secure_storage`; confirm no leftover SHA-256 password store ships in release
- [ ] Sentry fully wired in production, with alerting; spend alerts/caps active on Gemini/OpenAI keys
- [ ] Consented product analytics added (PostHog / Amplitude) — this also gives real usage data on where the scan feature fails, rather than guessing
- [ ] Fastlane (or Play Publisher / Codemagic) for repeatable signed builds and uploads
- [ ] Client image caching (`cached_network_image`) live for avatars/thumbnails
- [ ] Local cache layer migrated to Drift/Isar (Section 4)

### 5.3 Tier 3 — Do once you have real usage data

- [ ] Avatar CDN/transform decision executed (Section 3)
- [ ] Background sync (`workmanager` / iOS background fetch) within OS limits
- [ ] ARB-based i18n pipeline for locales beyond `en`/`hi`
- [ ] Status/uptime page for Edge Functions (AI + OCR outages are user-visible)
- [ ] LLM cost caching for repeated chat prompts, if spend data justifies it

---

## 6. RECOMMENDED PACKAGE/TOOL ADDITIONS

| Tool | Purpose | Tier |
|---|---|---|
| `cached_network_image` | Client-side image caching | Tier 2 |
| `flutter_secure_storage` | Secure local storage for auth/session data | Tier 2 |
| Drift or Isar | Structured local cache, replacing ad hoc `SharedPreferences` use | Tier 2 |
| `workmanager` (Android) / background fetch (iOS) | Background sync within OS limits | Tier 3 |
| Sentry (already integrated) | Crash reporting — confirm fully wired + alerting | Tier 2 |
| PostHog or Amplitude | Consented product analytics | Tier 2 |
| Fastlane | iOS certs/metadata/TestFlight upload automation | Tier 1–2 |
| GitHub Actions or Codemagic | CI: analyze/test on PR, build AAB/IPA on tag | Tier 1 |
| Cloudinary (scoped) | Avatar/marketing asset transforms + CDN, only if Supabase transforms don't cover it | Tier 3 |

---

## 7. OPEN DECISIONS REQUIRING PRODUCT/LEGAL INPUT

1. If the prescription scan turns out to be a handwriting-accuracy limitation: rescope the claim now, or invest further in a dedicated handwriting-OCR approach before launch?
2. Confirm current Supabase plan tier and whether Storage image transformations are available before deciding on Cloudinary.
3. Confirm analytics vendor choice (PostHog vs Amplitude) against data-residency/privacy-policy requirements already noted for EU/UK listings.
4. Confirm budget/threshold for LLM spend caps before enabling broader chat usage in production.

---

## 8. HOW TO USE THIS FILE

- **Before starting any Tier 1 item:** confirm it isn't already done in source — this plan reflects the state described in `GLOBAL_PRODUCTION_PROCESS.md` as of 2026-09-19.
- **When the prescription scan is fixed or rescoped:** update `GLOBAL_PRODUCTION_PROCESS.md` §6 (Feature inventory vs production honesty) and the store listing copy together, in the same change.
- **Tier boundaries are sequencing, not permission to skip:** a Tier 3 item becoming urgent (e.g., avatar traffic spiking) should be pulled forward rather than rigidly deferred.
