# Decisions for the founder

These change the product, the wording, or the architecture. They were not coded in this branch.

| Decision | Recommendation | Trade-off |
|---|---|---|
| Keep the application id `com.healthcompanion.health_companion` | Change it before the first Play upload if you want a brand-specific id. After upload it cannot change. | A new id means new Firebase/Supabase redirect entries and a new listing. |
| `allowBackup="true"` with shared preferences included | Leave it only if you still want logs to survive reinstall, and keep the privacy page saying that. The audit checklist asked for backups off. | On: reinstall can restore health logs, and a cloud backup may hold them. Off: uninstall wipes the phone copy. |
| Encrypt the on-phone profile | Move health JSON and the session id out of plain SharedPreferences before launch. | More engineering, and a migration for people who already have data on the phone. |
| Sign-in with Google and the 18+ box | Require the same unchecked 18+ and Terms box on the sign-in screen before Google continues. | Returning adults tap once more. Without it, a new Google user never sees the box. |
| Account deletion for Google/local users | Deletion today calls a Supabase function that needs a Supabase user. Google sign-in never creates one, so cloud delete does not run. Decide a path that still erases the phone copy and any server rows keyed by the Google id. | Support email alone will not satisfy a reviewer who creates a Google account and then deletes it. |
| Broad photo permission | Remove `READ_MEDIA_IMAGES` after confirming the system picker still opens on Android 8 through 16. | If a device has no photo picker, gallery upload breaks until you add a narrow fallback. |
| Health types the code reads but the policy does not list | Either declare and disclose glucose, ECG, temperature, respiratory rate, and workouts, or stop requesting them. | Declaring more types increases the Health Connect and Data safety review. |
| Activity rings and recovery/strain names | Ask a lawyer before launch. A safer graphic and original names reduce argument; they do not remove patent risk. | A visual change late in the design. |
| Mood questions | Do not ship the current eight items until someone confirms the instrument licence. | Replacing them changes the journal. |
| AI “report this answer” | Add a control and the words “AI draft” on chat and lab results. | Small UI, required for a generative feature review. |
| Screenshot blocking | Optional. Medical ID may need to stay visible for an emergency. | `FLAG_SECURE` hides recents thumbnails and blocks screenshots on the screens you choose. |
| CORS `*` on edge functions | Restrict origins if a website calls the functions. The Android app does not need `*`. | A wrong allow-list breaks a future web client. |
| Grievance officer and retention periods | Put a named contact and a retention period on the privacy page. This audit did not invent that legal text. | The page is what reviewers and the DPDP notice will be compared against. |
| Demo reviewer login | Keep demo code out of release. Create a real test account and put it only in the Play review notes. | You must maintain that account. |
