# Crow — the inventor

Master-plan phase 5 (Apr 26 – May 30, 2027). Its mind: `docs/minds/crow.md`.

Crow studies how you work, turns recurring friction into proposals for new tools, and hands the ones you approve to Swift to build.

## Who it is
Curious and a little opinionated: an inventor that only pitches ideas it can back with evidence from your own habits.
- **Personality:** sharp, playful, confident but never pushy. Shows its reasoning ("here's what I saw") instead of asserting.
- **Judgment:** ranks ideas by time or annoyance saved; drops ideas that only look clever.
- **Initiative:** pitches one idea at a time, at a calm moment (never mid-focus).
- **Learning:** remembers which pitches you accept or reject, so its taste converges on yours.

## What it does
| Capability | Detail |
|---|---|
| Friction log | Notices repeated actions, the same search twice, bouncing between two apps, copy-paste loops, long pauses after an error |
| Pattern finding | Groups those moments into recurring needs, e.g. "you rename screenshots by hand several times a week" |
| Pitch cards | A designed card per idea: problem, evidence, proposed tool, estimated time saved, quick mockup |
| Prototypes | An approved Nest pitch becomes a task in Swift's queue, with its own "done means" test |
| Nest backlog | Ranked list of every idea for expanding the Nest |
| Taste learning | Tracks accepts and rejects to pitch better over time |

## How it's built
Crow watches both what you do and what's on your screen, all processed on your Mac.
- **Sensing:** macOS events for app switches, window focus, file actions, clipboard use, search queries inside the Nest, plus regular screen snapshots read on-device with ScreenCaptureKit and Vision OCR
- **Privacy line:** snapshots are read, then deleted, keeping only short notes in Magpie; password fields, private browser windows and excluded apps are skipped; no raw keystroke logging; nothing leaves your Mac
- **Pattern engine:** a local model groups events into recurring needs continuously in the background
- **Pitch cards:** SwiftUI cards in the Nest, styled from the design system
- **Handoff:** approved Nest pitches go straight into Swift's queue

## Decisions
- **How often it pitches:** whenever Crow judges it's needed: a strong idea and a calm moment, never mid-focus.
- **Scope of ideas:** always beyond the Nest too. Nest ideas go to Swift; ideas for school, robotics or anything else come to you as pitches, since Swift only touches the Nest.
- **Sensing:** screen content and everything else it needs, processed only on your Mac. Watches all the time.
- **Pitch card:** understood in 5 seconds: one-line headline naming the problem, an evidence strip (small chart of frequency plus a screenshot), a live mockup, a time-saved badge, three buttons (Build it, Not now, Never), styled with Wren's current theme, smooth motion.
