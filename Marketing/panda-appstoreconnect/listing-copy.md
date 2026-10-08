# Panda Panda — App Store Connect Submission Package

Pulled from your Claude Design file (turn 5, "App Store submission") — this is the
copy your designer already drafted, ready to paste into Connect. Character counts
are checked against Apple's current limits.

---

## 1. Screenshots

Location: `screenshots/` — five PNGs, 422×514px (Apple Watch Ultra 2/3 size),
no alpha channel, in pitch order (what it is → what you do → why you come back →
what you're chasing → where it lives).

**Important:** App Store Connect only requires screenshots at ONE watch size —
the Ultra size. Connect automatically displays that same set for Series 11 (416×496),
Series 9 (396×484), Series 6 (368×448) and Series 3/SE (312×390); you do not need to
generate five separate resolutions. If you'd rather upload distinct assets per size
anyway, say so and I'll re-render the set at any of the other dimensions.

| File | Headline | Subline |
|---|---|---|
| `01_the-run.png` | One tap. One year. | SEASONS TURN AS YOU RUN |
| `02_worlds.png` | Five worlds that play differently. | NOT FIVE PAINT JOBS |
| `03_the-ritual.png` | A quest a day. | SIXTY SECONDS, THEN BACK TO WORK |
| `04_unlocks.png` | Earn every world. | NO ADS · NO PURCHASES |
| `05_complications.png` | Your streak, on your face. | THREE COMPLICATIONS |

## 2. App icon

`app-icon-1024.png` — 1024×1024, no transparency, no rounded corners (Apple masks
it for you). Same mark used on the watch face and home screen icon.

## 3. App Name
*(30 char max — 18/30 used)*
```
Panda Panda Runner
```
Never put "Apple Watch" in the name — rejected under Guideline 5.2.5.

## 4. Subtitle
*(30 char max — 20/30 used)*
```
A run for your wrist
```

## 5. Promotional Text
*(170 char max — 116/170 used — this is the one field you can edit without a new build)*
```
Five worlds, four seasons each, and a streak that lives on your watch face. One tap to start, sixty seconds to play.
```

## 6. Description
*(4,000 char max — 1,371/4,000 used)*
```
A panda runs. You tap to jump. That's the whole first second of Panda Panda — and then the season turns.

Every run is one year. Spring gives you soft ground and easy gaps. By summer the world is fast and crowded. Autumn takes away what you can see. Winter changes how far a jump carries, so the timing you learned at the start is wrong by the end. One run, four different games.

FIVE WORLDS, FIVE WAYS TO PLAY
Bamboo Grove is rhythm — clusters of stalks, tall-short-tall. Mist Terraces takes the ground away — you jump slab to slab across a gorge with nothing to dodge. Snow Pass drops icicles from the ridge, the one world where you duck instead of leap. Lantern Row swings on a fixed beat, a night market you play like a metronome. Ash Hollow gives way a moment after you land, so you can never stand still.

SIXTY SECONDS A DAY
A new quest every morning, a streak that multiplies what you earn, and a weekly board with the handful of people you actually know. Miss a day and you start again — that's the point.

BUILT FOR THE WATCH, NOT PORTED TO IT
One-tap start from the watch face. Turn the Digital Crown to browse. Haptics on every landing. Three complications so your streak is on your wrist without opening anything.

EARN EVERYTHING
Coins come from running. Worlds and pandas unlock by playing. No ads, no purchases, no timers, no account. Works with no signal — on a plane, on the subway, anywhere.
```

## 7. Keywords
*(100 char max, comma-separated, no spaces — 94/100 used)*
```
endless,runner,jump,arcade,panda,watch,offline,streak,daily,pixel,retro,platformer,tap,minimal
```

## 8. What's New — Version 1.0
```
First release. Five worlds, twenty seasonal variations, daily quests, weekly boards, and three complications.
```

## 9. Support URL
```
https://pandapanda.a6ents.com/
```

## 10. Marketing URL
```
https://pandapanda.a6ents.com/
```

## 11. Category & Rating
- **Primary:** Games → Arcade
- **Secondary:** Games → Casual
- **Age rating:** 4+ (no objectionable content)
- **Price:** Free, no in-app purchases

## 12. Privacy — "Nutrition Label" answers
- **Data collected:** None
- **Tracking:** No
- **Scores & coins:** Stored on-device only
- **Account:** Not required

## 13. App Review notes
*(Paste into the "Notes" field for the reviewer)*
```
watchOS-only app; no companion iPhone app to test. No login, no server, no network calls — everything is stored locally in UserDefaults. To reach the marketplace and locked worlds quickly, tap Market on the home screen; coins are pre-seeded in the review build so all five worlds can be inspected without grinding. The Digital Crown scrolls the home stack and the market grid.
```

## 14. Routing App Coverage File — not applicable
A Routing App Coverage File is a KML document required only for apps in the
**Navigation** category that provide turn-by-turn directions (the file tells
Apple which geographic regions your routing data covers). Panda Panda is filed
under Games → Arcade, not Navigation, so this field does not appear for your
app in Connect and nothing needs to be produced or uploaded. Flagging this now
because generating one anyway would be pure fabrication with no purpose.

---

## Decisions that need you, not a designer (flagged in the source design file)

1. **Support URL / Privacy Policy URL are both required fields**, even though
   the app collects zero data — a single static page can satisfy both. You've
   pointed both fields at `https://pandapanda.a6ents.com/`; confirm that page
   (or a `/privacy` route on it) actually exists and states "no data collected"
   before submitting, or Review will bounce it.
2. **The weekly leaderboard** (shown in one of the "worlds" mockups) implies
   either Game Center (GameKit) or shared friend data. If it ships in this
   1.0 build, the privacy label above is wrong (it currently claims "no data
   collected") and Game Center needs to be enabled in your capabilities. The
   design file's own recommendation is to cut the leaderboard to a 1.1 update
   and keep 1.0's privacy label clean — your call.
3. **Confirm "Panda Panda Runner" is actually available** as an app name —
   App Store Connect rejects the save on the App Information page if it's taken.
