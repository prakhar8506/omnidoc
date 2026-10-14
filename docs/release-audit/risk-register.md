# Risk register

14 October 2026. This does not clear patents, trademarks, or regulatory status. Each row is a question for a qualified person.

## Trademark search the founder must run

Do this before spending on the name, icon, or domain. Search the word Cura and the logo, owner “the Cura health app”, in:

- Indian Trade Marks Registry public search, classes 9 (software), 42 (SaaS), and 44 (medical/health services). Page title to open: the IP India public search.
- WIPO Global Brand Database.
- USPTO trademark search.
- EUIPO eSearch plus.
- Google Play and Apple App Store name search for “Cura” in health.

“Cura” is a common word in health. Expect existing filings. A lawyer should say whether a distinctive name or a distinctive logo is required before launch.

## Feature overlap

| # | Feature | Where | Why it may overlap | Reduce overlap (needs founder approval) | Question for counsel |
|---|---|---|---|---|---|
| 1 | Three concentric rings for recovery, sleep, and strain | `lib/core/charts/activity_rings.dart` | The layout resembles Apple Activity rings. Colors in code are pink, mint, and amber, not the Move/Exercise/Stand triplet, but the nested-ring graphic is still recognisable. | Different geometry, a gap, or a single gauge. Do not use Move, Exercise, or Stand. | Is the graphic a trade-dress or design-patent issue in India and the other launch countries? |
| 2 | “Recovery”, “strain”, and “Primed for Movement” | `lib/core/domains/recovery_model.dart` lines 288–295. Strain comment in `wearable_service.dart` lines 434–437 says Cura does not convert steps into a 0–21 score. | Recovery/strain vocabulary is widely associated with WHOOP. A 0–21 scale is mentioned in the wearable empty state. | Rename scores, document an independent formula in `docs/score-methodology.md`, and remove 0–21 if it is not the product’s own scale. | Does counsel want a freedom-to-operate search on readiness and strain scoring before launch? |
| 3 | Readiness, sleep score, HRV use | `recovery_model.dart` | HRV-based readiness products are crowded. | Keep the formula written down and original. | Same search, using the actual formula text. |
| 4 | Triage urgency bands | `health-ai-chat/index.ts` lines 31–42 (`LOW\|MODERATE\|URGENT\|EMERGENCY`) | Urgency classification can be treated as a medical device if it tells the user what care to seek. | Educational wording only, which is a product change. | CDSCO medical-device software, and FDA/MDR if those countries are in scope. |
| 5 | AI lab interpretation and “medicines clinicians often discuss” | `interpret-lab/index.ts` lines 70–80 | Output can look like a diagnosis or a prescription. | Keep the draft label and the “not a prescription” line. Counsel decides if the feature stays. | Same regulatory question. |
| 6 | Cycle, pregnancy, kick counting, glucose and BP trends | Feature screens under `lib/features/womens_health` and `lib/features/chronic_care` | Fertility prediction and clinical alerts are higher risk than a log book. | Do not add prediction or “your reading is dangerous” alerts without a regulatory opinion. | Which of these functions, if any, is a medical device in India? |
| 7 | Mood check | `lib/core/mental/mood_check.dart` | Wording and the 0–3 two-week scale track PHQ-9 closely, with one item removed and “Several days” changed to “A few days”. PHQ-9 is not assumed to be free for a commercial app. | Replace with an original wellness check, or obtain the instrument licence and print the required credit. | What licence applies, and is attribution enough? |
| 8 | Family invites and clubs | `family-circle` function, activity clubs screen | Social fitness mechanics exist in many patents. Risk is lower than the scoring items. | Keep join codes unguessable. | Does counsel want these in the search at all? |
| 9 | Health Connect, ML Kit, speech recognition | `health` 13.3.2, `google_mlkit_text_recognition` 0.17.1, `speech_to_text` 7.5.0 | Vendor terms can restrict health use, training, and attribution. | Stay inside each vendor’s health and data terms. | Are the current Google ML Kit and Health Connect terms compatible with this product? |

## Reduce-risk list for the founder to approve

None of these were changed in this branch, because they change the product.

1. Rename recovery/strain or document an independent formula.
2. Change the three-ring graphic.
3. Replace or license the mood questions.
4. Add “AI draft” and a report-this-answer control.
5. Decide whether glucose, ECG, and temperature reads stay. If they stay, add the Health Connect permissions and the privacy sentences. If they go, delete the reads.
