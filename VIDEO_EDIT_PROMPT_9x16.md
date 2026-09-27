# 9:16 Edit Prompt — Same Style as the Zypit / Luay Serfraz Reference

**Role:** Senior finishing editor + motion designer (feature / TV-commercial).  
**Job:** Take my **raw vertical talking-head** and finish it in the **exact editing language** of the reference ad — not a 16:9 copy, not a new style. Same caption system, same graphics grammar, same cuts, same grade, same mix. Then upgrade picture and sound so it feels like a **TV commercial** shot for Reels / TikTok / Shorts.

**“Exact replica” means the craft, not the frame.** Same behind-the-subject type, split sandwich captions, red boards, 3D mosaics, collage slam, B&W clock, stats pill, DM cluster, dimmed logo stinger. Rebuild every device for **9:16**. Swap talent, handle, product names, and VO to my shoot. Do not invent a different template.

---

## 1. Deliverable

- **Aspect:** **9:16 vertical**. Master **1080×1920** (or 4K 2160×3840, then downscale). 30 fps, progressive, Rec.709.
- **Duration:** Cut to the voice. Reference is ~45s; my cut should be the same density — no padding, no dead air.
- **Codec:** H.264 High or H.265, 4:2:0, high bitrate. Stereo AAC 48 kHz, 320 kbps.
- **Loudness:** **−14 LUFS** integrated, true peak **−1.0 dBTP**, LRA ~6–8 LU.
- **Safe areas (Reels/TikTok):** Keep face + all type inside the **center 70%**. Nothing critical in the top ~180 px (status / username) or bottom ~280 px (caption, CTA, home bar). Captions live at **chest / mid-torso**, never in the bottom UI zone.

---

## 2. Picture — TV-ad finish, same room language

Grade the raw take; do not flatten it into a bright vlog.

- Warm indoor tungsten. Skin = healthy gold, not baked orange.
- Hero garment / brand color slightly lifted so it reads as a product color.
- Practical lamps stay warm. Screens stay cooler (cyan / magenta). Contrast them against skin.
- Shadows slightly crushed with a hint of teal in dark furniture. Not digital black.
- Soft highlight roll-off. Gentle bloom on practicals. Subtle vignette (8–12%).
- Fine grain. Keep slight wide-angle distortion if the lens has it.
- **Framing (9:16):** Mid-shot, headroom tight but not cropped, eyes ~28–34% from top, torso and hands in frame. Subject **optically centered**. Camera slightly low.

**Quality upgrade vs phone original**
- Stabilize micro-jitter; keep organic life. No robotic lock-off.
- Face sharpen moderate. Skin smooth **very light**. Keep pores, fabric, hair.
- Denoise shadows without plastic smear. Light dehaze.
- Output should feel like a national TV spot shot in a real office.

---

## 3. Audio — booth-clean, VO-driven

Original language of the reference: dry voice, almost no music, graphic whooshes only.

- High-pass ~80 Hz.
- **De-reverb / echo removal** until the voice sits dry and close (treated-booth intimacy, still human).
- De-ess 5–8 kHz. Kill plosives, clicks.
- Cut boxiness ~300–400 Hz. Presence +2 to +4 dB at 3–5 kHz.
- Compress 3:1–4:1, 2–4 dB GR. Limiter −1 dBTP. Repair clipped peaks first.
- Voice mono-center. No fake stereo chorus.
- **SFX:** short whoosh (100–180 ms) on mosaic in, number pops, collage slam, stats bounce, DM in, red-card cuts, logo slam. Optional sub-hit under big numbers and “Step 1/2/3”.
- **No music bed under VO.** If anything, a barely-there rumble under B-roll, ducked 20 dB under speech.
- Mute after last word except a tiny logo whoosh.
- Captions **always** sync to spoken words. Never early. Out by ~2–4 frames after the next phrase starts.

---

## 4. Typography system (do not change this personality)

**Font:** SF Pro Display / Inter / Neue Haas Grotesk Display (or closest).

| Role | Weight | Color / opacity |
|---|---|---|
| Keywords, numbers | ExtraBold / Black, tracking −1 to −2% | `#FFFFFF` 100% |
| Connectors (*the, of, to, is, and, with, just, your*) | Regular / Medium | White **70–85%** |
| Red cards | ExtraBold | White (lighter red on staggered “Step” reveal) |
| White graphic boards | ExtraBold / Regular | Black or brand red |

- **No stroke. No heavy drop shadow.** Max 2–4% black at 8 px blur, only if type dies on a wall.
- **9:16 sizes (1080-wide):** connectors ~42–56 px; keywords ~56–72 px; hero words (“easiest” class) ~120–160 px; giant numbers (“1500+”, “60,000”) ~140–180 px.
- **In:** 4–8 frame fade + scale 96% → 100% with tiny overshoot. **Out:** 4–6 frame fade as the next chunk takes the slot.
- Keywords heavier (more opaque, slightly larger). Connectors quieter. If connectors are as bold as keywords, it is wrong.

---

## 5. Behind-the-object captions (signature look)

Captions live on a **Z-plane behind the speaker**. Head, hair, shoulders, clothes, and hands **occlude the type**. Body always wins. Eyes and mouth never covered. If a giant word sits on the head, **the face punches through the letters**.

**Build:** per-frame person matte (ML segmentation / Roto Brush). Fine hair, glasses, lav, watch, fingers. Composite type **under** the foreground plate.

### 9:16 placement grammar (adapt the landscape sandwich)

The reference splits phrases **left and right of the torso** at chest height. Keep that grammar; tighten it for vertical.

- **Default = split sandwich** at **chest / upper-torso** (~48–56% from top — the optical middle, above Reels UI).
  - **Left phrase:** right-aligned in the left third, tucked beside the body, over negative space (desk, wall, monitors).
  - **Right phrase:** left-aligned in the right third, same **baseline** as the left. Do not stagger vertically.
  - Speaker is the **gutter**. Type never crowds the face.
- **Single phrase:** left slot, same height (e.g. “And here’s”, “But the”).
- **Giant numbers / isolated verbs:** right slot, oversized (“1500+”, “pay”).
- Optical alignment, not math. Nudge into the empty room, not onto cheeks.
- Stack a second line **only** if a phrase cannot fit beside the body. Never drop type into the bottom 280 px.

**If any caption sits on top of the face instead of behind it, the edit is wrong.**

---

## 6. Watermark choreography

Handle lockup: Instagram glyph stacked above `@HANDLE` (SF Pro Medium, slightly open tracking, all caps).

- **Default:** top-right, **below** Reels status bar (~140–180 px from top). White glyph + white handle.
- **If the right slot is occupied by captions:** jump the lockup to **lower-left**, still **above** the bottom UI (~320 px from bottom). Never cover a keyword.
- **White graphic boards:** lower-left at 35–45% opacity.
- **Red cards:** Step 1 → lower-left. Step 3 + comment CTA → upper-right (still below status bar).
- Glyph: **white** on talking-head and red. **Instagram gradient** (magenta → orange) on the 3D mosaic and during the end-logo cycle.

---

## 7. Motion-graphics set pieces (rebuild in 9:16)

Hard cuts into graphics unless noted. Whoosh on hits.

### A. Opening hero type
Quiet beat of face, no type. Then:
- Small connector above/left of the hero word.
- **Hero word ExtraBlack**, almost full width, sitting **behind the head** (face cuts through).
- Small connector below/right of the word.
- Pop in 6–8 frames after first speech. Hold, then hand off to the split-caption system.

### B. 3D post mosaic (~2s beat)
Hard cut to **true black**. 12–20 square tiles tumble in 3D (Z-rotation, motion blur, near tiles soft/large, far tiles receding). Centered sentence: Regular connectors + **ExtraBold keywords**. Gradient IG glyph top-right. Subtle camera drift. Hard cut back to VO.

*9:16:* tiles arranged in a taller column; keep the sentence in the optical center, not the bottom.

### C. Solid red title cards
Full-bleed brand red matching the hero garment (~`#E31C23`, slightly orange-red — not cherry, not maroon). Hard cut. No zoom, no dissolve.

1. **Step 1.** “Step” can fade in lighter red, then the number snaps white.
2. **Step 2.** Same.
3. **Step 3.** Centered, white.
4. **Comment CTA** — two-line lockup, slightly above center: small Regular “Comment” over a much larger **italic** quoted product name with curly quotes.

Hold each ~0.6–1.2s. Cut back to VO.

*9:16:* type centered, large, generous side margins. Do not sit the lockup in the bottom UI.

### D. Creator collage slam
Full **white**. Dozens of 9:16 creator stills/loops, scattered, slightly rotated, slow parallax (3–8 px/s). Centered giant red type, two lines (number ExtraBlack, noun ExtraBlack). Last letters of the noun **smear right** with horizontal motion blur. Scale 108% → 100% + hit SFX.

*9:16:* collage fills the tall frame; type stays in the middle third so tiles read above and below.

### E. B&W clock B-roll
ECU analog clock, black and white, high contrast, shallow DOF, slight Dutch. Hands may be slightly sped. Split captions over the clock (no person, so type sits on the image, not behind a body): left Regular connector | right ExtraBold time phrase. Watermark lower-left. Hard cut in/out.

*9:16:* crop the clock vertically (face of the clock large, rim and hands filling height). Captions still at mid-frame.

### F. Stats pill
Full white. Centered rounded speech-bubble / tooltip, hot pink (`#E11D48`–`#F43F5E`), notch at the bottom. White icons + stats inside (comments / likes / follows). Scale 0 → 110% → 100% bounce. Under the bubble, small brand-red word that completes as the VO hits (“blew” → “blew up”). Faded watermark lower-left. **12–16 frame dissolve** into talking-head (washed, leftover ghost word allowed).

### G. DM / iMessage cluster
Full white. Stack of **dark-mode** rounded bubbles (`#2C2C2E`), white text, circular avatars. Copy = many variants of the same inbound message. Cluster **yaw-rotated ~15–25°**, messy deck, foreground sharp, rear bubbles softer/clipped. Slow drift. Black caption underneath, two beats, keyword slightly bolder. Faded watermark lower-left. Hard cut to red comment card.

*9:16:* stack the cluster taller than wide; caption sits under it in the middle third, still above bottom UI.

### H. End card
Talking-head **dims to 25–35%** (room stays visible — not a fade to black). Last split captions remain as **ghost grey**, still behind the body. **Giant Instagram logo** on the face (~22–28% of frame width). Color cycle: white outline → Instagram gradient → white, ~0.4–0.6s per state, smooth interpolate. Handle ExtraBold white, centered under the logo. Hold ~1s. No fade out.

---

## 8. Timeline grammar (map to my VO)

Slip ±3–5 frames to the take. Structure is the product; words are mine.

| Beat | Picture | Type / graphic |
|---|---|---|
| 0.0 | Talking-head | No captions. Watermark top-right. |
| Hook | Talking-head | Hero word **behind head**, then split sandwich for the rest of the hook. |
| Proof insert | 3D mosaic, ~2s | Centered ExtraBold keywords. |
| Promise | Talking-head | Chunked left slots, then giant number on the **right**. Watermark jumps lower-left when the right slot is live. |
| Step 1 | Red card → VO | Split sandwich for the benefit line. |
| Step 2 | Red card → “from a pool of” → collage slam | Giant red count over drifting tiles. |
| Targeting | Talking-head | Split: keywords left / connectors right. |
| Step 3 | Red card → VO | Isolate the money verb (**pay**) huge on the right. |
| Time | B&W clock | Split: connector \| ExtraBold duration. |
| Social proof | Stats pill → dissolve to face → DM cluster | Bounce pill, then stacked dark bubbles. |
| CTA | Red comment card → talking-head | Split sandwich CTA. |
| Sting | Dim + logo cycle | Ghost last line + handle. |

**Spoken spine (replace names/numbers with mine, keep this cadence):**  
Hook → “flood the algorithm with brand content” → exact strategy + **big signup number** in **N days** → Step 1 craft a **benefits** message → Step 2 pick from a **huge creator pool** the **right persona** → Step 3 brief them, they post, **you only pay for the views they got** → within **24 hours** it **blew up** + inbound DMs → if you want this done for your launch, **comment the product name** and we’ll do it.

---

## 9. Transitions

- Talking-head to talking-head: invisible. One take if possible. Jump-cut only on gesture.
- Talking-head → graphic: **hard cut** (exception: stats pill → face = dissolve).
- Red cards: **hard cut** in and out.
- End: **brightness dip**, not fade to black.
- Never freeze a mid-gesture into a card.

---

## 10. 9:16 vs the landscape reference — what must change

| Keep identical | Rebuild for vertical |
|---|---|
| Behind-subject type | Tighter left/right gutters beside the torso |
| Quiet connectors, screaming keywords | Type sizes scaled to 1080×1920 |
| Watermark collision logic | Offset for Reels top/bottom UI |
| Red boards, mosaic, collage, clock, pill, DMs, logo sting | Composed in a tall column; type stays in the **middle third** |
| Dry VO, whooshes only | Same mix, cleaner (de-reverb, −14 LUFS) |
| Warm tungsten grade | Same, then TV-ad polish |

Do **not** put captions at the bottom like standard auto-captions. Do **not** use a 16:9 letterbox. Do **not** cover the face. Do **not** add a music bed that fights the VO. Do **not** use generic YouTube red — match the sweater / brand red.

---

## 11. Done looks like this

A 9:16 commercial a stranger would swear was cut by the same editor as the reference: same caption personality, same occlusion, same watermark dance, same red boards, same 3D clutter, same smeared collage type, same B&W clock, same pink stats bubble, same stacked DMs, same dimmed logo stinger — on **my** talent, **my** product, **my** vertical footage — with booth-clean voice and a TV-ad grade.

Build the style as an exact replica. Finish picture and sound like a national TV ad. Export 1080×1920, 30 fps, −14 LUFS.
