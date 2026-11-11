# The Nest — Master Plan

The Nest is a flock of six AI birds that run your Mac on their own, each a separate mind with one job, sharing one memory and one design. Built over the next year. Bird specs live in `docs/birds/`, the app spec in `docs/nest-app.md`.

## The flock at a glance

| Bird | Role | Key powers |
|---|---|---|
| Wren | Keeper of space | Organizes files, curated wallpapers and Mac-wide theme, self-invented modes that set layout, apps and settings, resume any project |
| Swift | Builder | Drives Claude Code to build and test the Nest's code overnight, auto-merges on green tests, forecasts your usage around robotics |
| Crow | Inventor | Watches how you work (actions and screen), pitches tools on beautiful cards; Nest ideas go to Swift, others to you |
| Owl | Eyes | Webcam presence, greeting, instant lock, intruder alert, context-aware distraction nudges, flow mode, gestures |
| Magpie | Second brain | Shared memory as linked Markdown notes; goals, schedule, to-dos, every bird's actions; answers anything |
| Peacock | Showcase | Clips wins as you work, gets them edited to your theme, drafts devlogs in your voice, hands post kits to Wren |
| Nest app | Window into the flock | A full app to monitor and chat with every bird; each bird can also be reached directly from the background |

## How it fits together

Magpie is the hub: every bird writes what it does and reads what it needs, so the birds never call each other directly. Through Magpie, Owl tells Wren you've left so it can tidy, Crow's Nest ideas reach Swift's queue, and Peacock's post kits land in Wren's Ready to Post folder.

## Shared foundations

**Principles**
1. **Autonomous.** The birds act on their own; you only step in if you want to.
2. **Fast and premium.** Instant rules first, models only for hard cases, nothing ever buffers in front of you.
3. **Undoable.** Every action can be reversed in one tap; nothing is deleted.
4. **Beautiful.** Everything follows one design system and Wren's current theme.
5. **Learns from you.** Every correction becomes a lesson in Magpie and, over time, training data.
6. **Never breaks, never leaks.** No bird rearranges code projects or app data, changes security settings, or sends your data anywhere you didn't choose.

**Brains**

| Brain | Used by | Why |
|---|---|---|
| Small open models on your Mac (MLX) | Wren, Crow, Owl, Magpie, Peacock | Free, private, fast enough for judgment calls |
| Claude Code on your Pro plan | Swift, with plan mode for Crow's rough ideas | Strong enough to actually build and test code |
| Kaggle's free weekly GPUs | Monthly fine-tunes | Train local models on your own corrections |
| AI video editors (Claude, Higgsfield, or similar) | Peacock | Polished reels; only clips you'd post leave your Mac |

**Talking to the birds**
- The **Nest app**: a full app to watch the whole flock and chat with any bird
- **Directly**: click a bird's menu bar icon for a quick chat, or press a global shortcut from anywhere
- **Later**: a private portal so your iPad's browser can reach every bird

## How it should look

One design system drives every surface, from the Nest app to Swift's reports, and Wren's current theme tints all of it. The visual direction is still being decided; see `docs/design-status.md`.

**The design system**
1. **Tokens:** colours, fonts, spacing, corners, effects (glass, blur, glows, shadows), and motion (durations, easing, springs)
2. **Components:** cards, panels, buttons, chat bubbles, status pills, built only from tokens
3. **Rules:** why things look the way they do, with do/don't examples, so Swift and the AI editors can create new pieces that complement the style instead of cloning it

**Surfaces**

| Surface | Look and feel |
|---|---|
| Nest app | Overview of the whole flock, a chat per bird, live activity timeline |
| Menu bar birds | One small animated bird per bird; Wren's hops when it tidies, Owl's settles when you arrive |
| Owl's greeting | A soft spoken line plus a glow sweeping the screen's edge |
| Swift's reports | Mission-control style: green/amber/red status, headline, up to three points, details folded |
| Crow's pitch cards | Headline, evidence strip, live mockup, time-saved badge, Build it / Not now / Never |
| Magpie's view | Search, timeline, and a map of linked ideas inside the Nest app |
| Wallpapers and theme | Curated high-quality images or your own Claude Design and Canva exports; accent, light/dark, and bird colours follow the wallpaper |
| Peacock's reels | Edited to the design system, shaped per platform |

## Build order

| # | Phase | Start | End |
|---|---|---|---|
| 1 | Design system + Nest app shell | 2026-11-16 | 2026-12-06 |
| 2 | Swift core | 2026-12-07 | 2027-01-17 |
| 3 | Wren core | 2027-01-18 | 2027-03-14 |
| 4 | Magpie | 2027-03-15 | 2027-04-25 |
| 5 | Crow | 2027-04-26 | 2027-05-30 |
| 6 | Owl | 2027-05-31 | 2027-07-11 |
| 7 | Peacock | 2027-07-12 | 2027-08-15 |
| 8 | Wren style + modes | 2027-08-16 | 2027-09-26 |
| 9 | Flock wiring + polish | 2027-09-27 | 2027-10-31 |

**Why this order**
1. **Design system and Nest app shell first:** every later surface uses them, so nothing has to be restyled.
2. **Swift early:** once it works, it builds and tests parts of every other bird overnight.
3. **Wren core:** the original project, and useful every day right away.
4. **Magpie before the watchers:** Crow, Owl, and Peacock all read from and write to it.
5. **Crow before Owl and Peacock:** both use Crow's view of your screen.
6. **Wren's style and modes late:** they need Owl's and Magpie's signals to switch at the right moments.
7. **Finish with wiring and polish:** connect every bird and record the year-end demo.

The dates are a guide: robotics season and school will shift them, and Swift should shorten the later phases.

## Decisions so far

| Bird | Decided |
|---|---|
| Wren | Starts with Downloads, then your Mithu folder; organizes everything except what could break code, break your Mac, or leak data; curated wallpapers that theme the whole Mac; invents its own modes, which also set volume, brightness, Night Shift, notifications, Low Power Mode, and Bluetooth (never security settings) |
| Swift | Touches only the Nest's code; plan mode first for Crow's ideas; auto-merges on green tests with automatic rollback; forecasts your usage and works in the gaps, protecting robotics time; reports wait until you sit down; pings only when critical; mission-control voice |
| Crow | Pitches whenever it judges it's needed, at calm moments; watches all the time, including screen content, on-device, with no keystroke logging; ideates beyond the Nest |
| Owl | Camera on only while you're at the laptop or it wakes, off once the screen locks; context-based distraction (no app lists); four-step nudge ladder; spoken and animated greeting; lock, pause the flock, and alert you when a stranger sits down, with a guest mode |
| Magpie | Remembers anything useful except passwords, keys, account and ID numbers, and private browsing; its own view in the Nest app plus Obsidian; your edits always win; archives only when it helps |
| Peacock | Records whenever your work is clip-worthy; AI editing to your theme; devlogs in your voice; never posts itself, handing post kits to Wren's Ready to Post folder; reaches out at calm moments |

## Later and resolved

**Later**
- iPad portal for every bird, over Tailscale
- New birds as Crow finds needs for them

**Resolved**
- Swift's usage reserve: no fixed size. Swift learns how much you use Claude across your days (chats and Claude Code share the same limits) and keeps enough in reserve for what you usually need at each time of day and week.
- Wren also tidies output files from Crow, Swift and Peacock (reports, screenshots, mockups, clips); the Nest's code itself stays off-limits.
