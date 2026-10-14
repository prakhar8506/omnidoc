# Play Console draft answers

These are drafts from the code. They are not a submitted form. Verify every policy page in the current Play Console before you paste them.

## App access

Reviewers need a real account. Do not ship the demo button. Source evidence that demo is debug-only: `lib/core/env/app_env.dart` lines 46–47. Put the reviewer email and password only in the Play “app access” notes, not in git.

## Ads

No ads. `pubspec.yaml` has no ad SDK. Declare “no ads”.

## Target audience

18 and over. The sign-up checkbox starts unchecked (`sign_up_screen.dart` line 32). Sign-in with Google does not show that checkbox (`sign_in_screen.dart` lines 173–178). Do not declare the app child-directed. Fix the sign-in gap before you answer the form.

## Content rating

Draft for the IARC questions, still to be confirmed in the questionnaire:

- No violence, no sexual content, no gambling, no user-generated public feed that was verified as moderated.
- Health and medical information: yes, wellness information, not a diagnosis. Mood check asks about low mood and self-harm and shows helplines (`mood_check_screen.dart` line 127).
- Shares user health information with a cloud service when email/Supabase sign-in is used, and with an AI provider when the user asks for chat or a lab explanation (`privacy.html` lines 38–40).
- No ads.

## Data safety

Use `data-inventory.csv`. Short version:

- Data is collected. Health data, photos, and messages are optional features. An account email is required for email sign-in.
- Data is not sold and not used for ads (`privacy.html` line 34).
- Data can be sent to Supabase, OpenAI, Gemini, Sentry (if a DSN is compiled in), Google Sign-In, and Razorpay.
- Users can delete from the profile sheet. Cloud deletion is implemented for a Supabase auth user only.
- Encrypted in transit: HTTPS. Encrypted at rest by the app: no for the phone copy.

## Health apps declaration

Features from the code: journaling, meals and water, medications, cycle and pregnancy logs, glucose and blood pressure logs, wearable trends, lab upload and plain-language explanation, AI chat, family invite, PDF export.

Health Connect reads declared in the manifest: heart rate, resting heart rate, heart rate variability, steps, sleep, oxygen saturation, blood pressure.

The app is not described in the privacy page as a medical device (`privacy.html` line 18). Regulatory status is not decided in this audit.

The declaration must match the manifest. Reconcile the extra types in `wearable_service.dart` lines 84–93 before you submit.

## Permissions declarations

See `permissions-justification.md`. Camera, microphone, and photos need a reason the user sees in the app. Health Connect needs the privacy-policy intent, which is declared.

## AI-generated content

The app generates chat replies and lab explanations with OpenAI, and Gemini as a fallback (`health-ai-chat/index.ts` lines 101–102, `privacy.html` lines 38–41). Output is described as informational and not a diagnosis. There is no in-app control to report a harmful answer yet. Say that in the disclosure only after that control exists, or describe the gap honestly.

## News, government, financial

News: no. Government: no. Financial: the app sells a subscription through Razorpay (`razorpay_flutter` in `pubspec.yaml`). Answer the financial declaration to match that payment, not as a bank or lender. Confirm the exact question text in Play Console.
