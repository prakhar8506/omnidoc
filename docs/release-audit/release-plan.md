# Release plan

Verify the current closed-testing rule in Play Console before relying on this calendar. An organisation account may not have the same 14-day requirement. This draft assumes a personal developer account that must keep at least 12 testers opted in for 14 continuous days.

Pick a start date. The dates below use a placeholder start of the day you opt the testers in.

| Day | Action |
|---|---|
| 0 | Upload an internal or closed-testing AAB built by `scripts/build_play_release.sh`. Complete Data safety, health declaration, content rating, and the privacy URL first. |
| 0 | Opt in at least 12 testers. They must stay opted in. |
| 1–13 | Fix only crashes from the pre-launch report. Do not reset the track in a way that drops testers. |
| 14 | Confirm the console shows the production-access requirement met. Then apply for production. |
| After access | Production rollout at a small percentage. Watch crashes. No health data should appear in Sentry. |

Not scheduled here, because they are outside the repo: trademark opinion, clinician read of the health text, and keystore copies in two offline places.
