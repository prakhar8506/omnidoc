# Security findings

14 October 2026. No secrets are printed here. `gitleaks` and `trufflehog` were not installed, so history was not fully scanned. `git log --all` for `env/production.json` and `android/key.properties` returned no commits. `git check-ignore` shows both paths ignored.

| ID | Severity | Finding | Evidence |
|---|---|---|---|
| S1 | High | Health profile and session id are in SharedPreferences, not Keystore-backed storage. | `lib/core/services/user_data_service.dart` lines 11–26. `lib/core/services/auth_service.dart` lines 20, 182, 264–270. |
| S2 | High | Google sign-in never creates a Supabase user, so RLS and `delete-account` do not cover that account. Phone delete still has to be checked on a device. | `auth_service.dart` lines 274–275. `delete-account/index.ts` lines 82–88. |
| S3 | Medium | `delete-account` returns `user_id` and performs no delete when the service-role secret is missing. | `delete-account/index.ts` lines 95–112. |
| S4 | Medium | Edge functions set `Access-Control-Allow-Origin: *`. | `health-ai-chat/index.ts` lines 14–17. Same pattern in `delete-account/index.ts` lines 29–32. |
| S5 | Medium | Chat accepts a client-supplied `context` object and stringifies it into the model prompt. No rate limit or size cap is in the function. | `health-ai-chat/index.ts` lines 87–99. |
| S6 | Medium | `READ_MEDIA_IMAGES` is declared. | `AndroidManifest.xml` line 5. |
| S7 | Medium | Backup allows shared preferences, which hold the health profile. | `AndroidManifest.xml` line 21. `data_extraction_rules.xml` lines 7–18 do not exclude `sharedpref`. |
| S8 | Low | `debugPrint` of repository errors may include server messages. | `lib/core/network/supabase_repository.dart` line 352. |
| S9 | Info | Release config trusts system CAs only. | `network_security_config.xml`, commit `8429071`. |
| S10 | Info | Lab storage path must start with the caller’s user id. | `interpret-lab/index.ts` lines 166–167. |
| S11 | Info | RLS policies for app tables use `auth.uid()`. | `supabase/migrations/20260916000001_row_level_security.sql` and `20260918000000_production_domain_tables.sql`. |
| S12 | Info | Two-user isolation was not tested against the hosted project. | Not run. |
| S13 | Info | `flutter analyze`, OSV-Scanner, and MobSF were not run in this pass. | Not run. |
| S14 | Info | Sentry initialises when configured. A `beforeSend` scrubber was not found at `main.dart` line 57. | `lib/main.dart` line 57. |

Static analysis and a MobSF scan of a fresh release APK are still required before upload.
