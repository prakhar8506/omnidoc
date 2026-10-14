# Permissions justification

Source: `android/app/src/main/AndroidManifest.xml` lines 2–15. Merged-manifest output of a release build was not generated in this audit, so a plugin can still add permissions at merge time.

| Permission | Why the app has it | Where the user is told | Status |
|---|---|---|---|
| `INTERNET` | Supabase, AI functions, fonts, Sentry, Razorpay | Not a dangerous permission | Keep |
| `CAMERA` | Lab, meal, and journal photos via `ImagePicker` | No separate prominent disclosure screen was found before the system prompt | Keep only with a pre-prompt |
| `RECORD_AUDIO` | `speech_to_text` is a dependency | Disclosure screen not found | Confirm a feature uses the mic; otherwise remove |
| `READ_MEDIA_IMAGES` | Declared beside the photo picker | Play restricts broad photo access. Uploads already call `ImagePicker` and `FilePicker` | Remove after a picker test on API 26 and API 36. Verify the page titled about photos and video permissions on developer.android.com |
| `READ_EXTERNAL_STORAGE` maxSdk 32 | Legacy gallery read | Same as photos | Prefer the system picker |
| `ACTIVITY_RECOGNITION` | Comment on line 7: step counts for the health plugin | Health permission flow | Keep if steps are shown |
| `health.READ_HEART_RATE` | Wearable heart rate | Health Connect rationale activity, lines 42–44 and 60–68 | Keep |
| `health.READ_RESTING_HEART_RATE` | Resting heart rate | Same | Keep |
| `health.READ_HEART_RATE_VARIABILITY` | HRV | Same | Keep |
| `health.READ_STEPS` | Steps | Same | Keep |
| `health.READ_SLEEP` | Sleep | Same | Keep |
| `health.READ_OXYGEN_SATURATION` | Blood oxygen | Same | Keep |
| `health.READ_BLOOD_PRESSURE` | Blood pressure | Same | Keep |
| `CALL_PHONE` | Not declared. The manifest queries `DIAL` (lines 95–98) | n/a | Absent, which matches “open the dialer” |
| Location | Not declared | n/a | Absent. Doctor search is a typed city (`privacy.html` line 30) |
| Exact alarms | Not declared | n/a | Absent. Verify the current Play exact-alarm policy only if you add reminders that need it |
| Notifications | Not declared in the app manifest | n/a | If a plugin adds `POST_NOTIFICATIONS`, justify it at the moment of use |

`android.hardware.camera` is `required="false"` (line 16), so a phone without a camera can still install.
