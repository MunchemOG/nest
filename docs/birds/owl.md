# Owl — the eyes

Master-plan phase 6 (May 31 – Jul 11, 2027). Its mind: `docs/minds/owl.md`.

Through your webcam, Owl knows when you're there, whether you're focused, and lets you control your Mac with your hands.

## Who it is
Quiet and protective: sees everything but speaks rarely, so when it does, you listen.
- **Personality:** calm, warm when greeting you, firm when guarding your laptop. Never nags or lectures.
- **Judgment:** decides when to step in. A two-second glance at your phone is fine; 15 minutes of scrolling during a study block is not.
- **Initiative:** steps in before you drift, based on learned patterns, and tells the other birds to stay silent while you're in flow.
- **Boundaries:** sees, never records. Video never leaves your Mac and is never saved.

## What it does
| Capability | Detail |
|---|---|
| Presence | Notices you sit down, wakes the Mac, greets you |
| Guard | Locks the screen the moment you walk away; recognizes you vs. someone else and flags anyone else at your laptop with an alert |
| Focus | Spots distraction (looking away, phone in hand, scrolling feeds), predicts drift from past patterns, nudges you back gently; judges by context not app lists, so purposeful use is fine and even useful work counts as drift when something more urgent is due |
| Flow | Detects deep focus and silences notifications and other birds until you surface |
| Context | Freezes what you were doing when you leave, shows a "you were here" card when you return |
| Gestures | Swipe in the air to switch desktops, pinch to grab a window, palm up to pause music |

## How it's built
Everything runs on-device with Apple's own vision tools.
- **Vision:** Apple Vision framework for face detection, gaze direction, hand pose
- **Recognizing you:** on-device face profile of you only, stored locally
- **Battery:** low-frame-rate idle mode, speeding up only when something changes
- **Control:** macOS accessibility APIs to lock the screen, move windows, switch desktops
- **Memory:** stores events ("distracted at 3:40 for 12 min"), never video
- **Known catch:** the Mac's green camera light stays on whenever Owl is watching, so Owl turns the camera off once the screen locks and back on when the Mac wakes

## Decisions
- **When it watches:** only while you're at the laptop or when it wakes, staying inconspicuous (no windows or sounds apart from the greeting, low frame rate, camera off once screen locks). The green light can't be hidden.
- **What counts as distraction:** no app lists; judged by context. Instagram/YouTube for something useful is fine, aimless scrolling isn't, and even real work (robotics in Android Studio, chatting with Claude) counts as drift when homework is due sooner. Combines webcam, on-screen content (via Crow), and deadlines (via Magpie).
- **Nudges:** four-step ladder: faint glow at the screen's edge → menu bar owl turns to look at you → soft spoken line naming what's due → hides the distracting app (never closing it or losing anything) and brings your task forward. Learns which step works; never lectures.
- **Greeting:** spoken and animated: a short soft line plus a glow sweeping the screen's edge as the owl settles into the menu bar, styled to Wren's theme. The one moment Owl shows itself.
- **Someone else sits down:** locks instantly, pauses every bird, sends an alert to your phone with the time. A guest mode ("they're with me") prevents false alarms.
