# Cura — Play Console & Health Connect form answers

Use these exact answers in Google Play Console. They match the code as of 28 September 2026.

**Public legal URLs (hosted):**

- Privacy Policy: `https://cura-health-legal.vercel.app/privacy`
- Terms of Use: `https://cura-health-legal.vercel.app/terms`
- Index: `https://cura-health-legal.vercel.app/`

Paste the Privacy Policy URL into:

1. Play Console → App content → Privacy policy
2. Play Console → App content → Data safety → Privacy policy
3. Play Console → App content → Health apps → Privacy policy (if asked)
4. App Store Connect → App Privacy → Privacy Policy URL

Account deletion (Play also asks for a web path): users delete in-app via avatar → Delete Account. Web request: `mailto:support@cura.health` with subject `Delete my Cura account`.

---

## Play Data Safety

**Does your app collect or share any of the required user data types?** Yes

**Is all of the user data collected by your app encrypted in transit?** Yes (HTTPS / TLS to Supabase, Sentry, and AI providers)

**Do you provide a way for users to request that their data is deleted?** Yes  
**Deletion method:** In-app (avatar → Delete Account) and email `support@cura.health`

### Data types

| Type | Collected | Shared | Required / optional | Purpose | Notes |
|---|---|---|---|---|---|
| Personal info → Name | Yes | No | Required | App functionality | Display name on account |
| Personal info → Email | Yes | Yes | Required | App functionality, Account management | Shared with Resend **only if** a greeting email is configured |
| Health & fitness → Health info | Yes | Yes | Optional (user-entered or authorized) | App functionality | Vitals, labs, meds, journal, mood screening, cycle/pregnancy logs, meals |
| Photos and videos | Yes | Yes | Optional | App functionality | Lab / prescription images. Shared with OpenAI or Gemini for the requested interpretation only |
| Other user-generated content | Yes | Yes | Optional | App functionality | Chat messages, symptom text, journal text sent to Health AI |
| Device or other IDs | No | No | — | — | No advertising ID / IDFA |
| App activity → Other actions | No | No | — | — | In-app analytics stay on device |
| App info and performance → Crash logs | Yes | Yes | Optional | Analytics | Sentry. Not linked to the account name |
| App info and performance → Diagnostics | Yes | Yes | Optional | Analytics | Sentry performance traces |
| Location | No precise / no coarse GPS | No | — | — | User-typed city is sent only as a Maps search URL on the device |
| Financial info | No | No | — | — | |
| Messages / SMS | No | No | — | — | |
| Audio | Processed on device | No | Optional | App functionality | Speech-to-text dictation; audio is not uploaded |

**Is this data sold or used for advertising?** No  
**Is this data used for tracking?** No  
**Can users request deletion?** Yes

**Third-party sharing destinations to name if the form asks:**

- Supabase (auth, database, file storage)
- OpenAI (AI chat, triage, lab reading — primary)
- Google Gemini (AI fallback)
- Sentry (crash / performance)
- Resend (welcome greeting email, only when configured)
- Google Maps (user opens a search URL; city string leaves the device)

---

## Play Health apps declaration

**Is this a health app?** Yes — wellness / personal health record organizer. Not a medical device.

**Does the app access Health Connect?** Yes

**Use case:** Fitness and wellness tracking / personal health insights. The user can see recovery trends from data they authorize.

**Data types read from Health Connect:**

- Heart rate
- Resting heart rate
- Heart rate variability
- Steps
- Sleep
- Oxygen saturation
- Blood pressure

**Data types written to Health Connect:** None

**When is access requested?** Contextual — after the user opens the wearable permission sheet or taps Sync Wearable. Not at launch.

**Rationale (paste into the Health Connect declaration):**  
Cura reads heart rate, HRV, steps, sleep, oxygen saturation, and blood pressure from Health Connect only after the user opts in, so they can see recovery and activity trends next to the notes they keep in the app. Cura does not write data back to Health Connect and does not use this data for advertising.

**Privacy policy URL:** `https://cura-health-legal.vercel.app/privacy`

---

## App Store privacy labels (for when an IPA exists)

Collected, linked to the user, not used for tracking:

- Health & Fitness
- Contact Info (email, name)
- Sensitive Info (mental-health screening, cycle/pregnancy, labs)
- User Content (journal, chat, symptoms)
- Photos or Videos (lab images)

Collected, not linked:

- Crash Data
- Performance Data (Sentry)

Tracking: No. ATT not required.

---

## After you log in to Supabase

The stored management token is expired (401). In a terminal:

```bash
supabase login
cd "/Users/prakharjain/Documents/health companion"
supabase functions deploy welcome-email --project-ref fpvcyxjatjajsaziblzg --no-verify-jwt
supabase functions deploy health-ai-chat --project-ref fpvcyxjatjajsaziblzg
supabase functions deploy interpret-lab --project-ref fpvcyxjatjajsaziblzg
supabase functions deploy delete-account --project-ref fpvcyxjatjajsaziblzg
supabase secrets list --project-ref fpvcyxjatjajsaziblzg
```

`--no-verify-jwt` on `welcome-email` is required: signup happens before a user JWT exists. The function still checks the project anon key and rate-limits.

Then, only if you have the keys:

```bash
supabase secrets set RESEND_API_KEY=re_... --project-ref fpvcyxjatjajsaziblzg
# Optional sender override:
# supabase secrets set CURA_FROM_EMAIL="Cura <hello@yourdomain.com>" --project-ref fpvcyxjatjajsaziblzg
```

`SUPABASE_SERVICE_ROLE_KEY` is injected automatically on hosted Edge Functions. After login, `supabase secrets list` should show it (or it is available as a platform secret even if not listed). A real Delete Account tap that returns 503 means it is missing.

There is no Resend key in this repo or in `env/production.json`. The greeting email cannot send until you create a Resend key and set it as above.
