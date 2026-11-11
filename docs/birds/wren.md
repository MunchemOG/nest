# Wren — keeper of space

Master-plan phases: 3 (core, Jan–Mar 2027) and 8 (style + modes, Aug–Sep 2027). Its mind (prompt, voice, examples): `docs/minds/wren.md`.

Wren organizes your files, styles your Mac, and reshapes your workspace for whatever you're doing, while the other birds handle memory, focus, building, and showing off.

## Who it is
A tidy, gentle homemaker, named after the small bird that builds neat nests out of scraps.
- **Personality:** warm, light, a little playful. Its menu bar bird hops when it tidies and settles when everything is in place.
- **Judgment:** decides where each file belongs, and when a mess should be left alone because it's an active project you're in the middle of.
- **Initiative:** tidies while you're away (Owl tells it), restyles your Mac as your day changes, builds folders for projects before you ask.
- **Boundaries:** never deletes, every action can be undone, folders you mark off-limits are never touched.

## Core principles
1. **Local and free.** Every model runs on your laptop. No cloud, no API bills, files never leave your Mac.
2. **Fast and premium.** Simple rules (file type, source, name patterns) handle most files instantly; the model only steps in for hard ones, in the background. Results cached, target under one second per decision, smooth 120 fps animations.
3. **Autonomous, but undoable.** Only moves, renames, restyles. Never deletes. Every action lands in an undo history reversible with one click.
4. **Beautiful first.** Calm, minimal, animated with purpose, native to macOS.
5. **Learns from you.** Every correction (moving a file back, rejecting a wallpaper) is stored in Magpie as a lesson and becomes training data.
6. **Ship early, stack features.**

## What it does
| Capability | Detail |
|---|---|
| Organize | Starts with Downloads, then your Mithu folder (minus off-limits list); reads inside files (PDFs, images, screenshots, code); renames and groups; builds project folders as they form |
| File search | Natural-language search: "the PDF my professor sent about enzymes" |
| Cleanup | Finds duplicates and huge forgotten files; groups open browser tabs by topic and saves sessions |
| Style | Curated wallpapers (free photo sites, or Claude Design / Canva exports) by time of day, season or mode; themes the whole Mac to match: light/dark, nearest accent colour, menu bar bird follow the wallpaper palette |
| Modes | Reshapes the workspace (wallpaper, theme, window layout, apps, Do Not Disturb, volume, brightness, Night Shift, Low Power Mode, Bluetooth) for study, coding, robotics or night, plus new modes Wren invents when it spots a recurring way you work |
| Resume | "Back to AP Physics" reopens the exact files, tabs and windows from last time |

Talking to Wren: in the Nest app, or via its menu bar bird or a global shortcut, though Wren never needs you to.

## Works with the flock
| Bird | Gives Wren | Gets from Wren |
|---|---|---|
| Owl | You sat down, walked away, or entered flow, so Wren can tidy while you're gone and switch modes | Nothing; Owl only watches |
| Magpie | Your projects, schedule, and past lessons | A log of every action and undo, stored as lessons |
| Swift | New Wren features, built and tested overnight | Bug reports from Wren's own error log |
| Crow | Ideas for new Wren features | Patterns in what you undo or redo by hand |
| Peacock | Post kits for its Ready to Post folder | Before/after shots of big cleanups and new looks |

## How it's built
Native Swift app with a two-speed brain: instant rules for most decisions, a local model for hard cases in the background. Every undo becomes a Magpie lesson that retrains Wren's model.

| Layer | Tool | Why |
|---|---|---|
| App and interface | Swift, SwiftUI, MenuBarExtra | Native look, full macOS access |
| File watching | FSEvents | Instant notice of new/changed files |
| Reading files | PDFKit, Vision (OCR) | Text from PDFs, images, screenshots, on-device |
| Fast path | Hand-written rules | Most decisions in milliseconds |
| AI model | Small open model via MLX, fine-tuned on Kaggle free GPUs | Hard cases, free and private |
| File search | SQLite + local embeddings | Natural-language search |
| Wallpaper, theme, modes | NSWorkspace, AppleScript, accessibility APIs | Set desktop, switch appearance, arrange windows |
| Flock link | Nest event bus + Magpie | Hears Owl's signals; logs actions and lessons |

## Build plan
1. **Organizer core:** menu bar app, Downloads watcher, text extraction, rules + local model, move/rename with undo log. *Done means: a messy Downloads folder cleans itself, and every move can be undone.*
2. **Understand and search:** content-aware grouping, project detection, duplicates and big-file cleanup, tab grouping, NL file search. *Done means: any file found from one plain-English query.*
3. **Style:** wallpaper library and picker, palette-matched light/dark and accent switching, animated menu bar bird. *Done means: your Mac's look changes through the day without you touching anything.*
4. **Modes and resume:** mode engine and saved workspaces, triggered by you first, then by Owl and Magpie. *Done means: "back to AP Physics" restores everything exactly.*
5. **Learning:** every undo logged as a lesson; monthly fine-tunes on Kaggle. *Done means: the fine-tuned model beats the base model on 100 of your past corrections.*
6. **Flock connections:** Owl triggers tidying and modes; Magpie supplies projects and schedule; Peacock captures before/after shots.

## Risks and guardrails
| Risk | Guardrail |
|---|---|
| AI misfiles something important | Never delete; every action in undo log; test on a copy of your folders first |
| Local model too slow or drains battery | Smallest model that works; batch work while charging; cache per file |
| Fine-tuning feels out of reach | Prompting carries early phases; fine-tune once there are hundreds of logged corrections |
| macOS permissions block features | Ship outside the App Store; request each folder/capability once, with a clear reason |
| Scope explodes | Each phase has one "done means" test; nothing new starts until it passes |
| Motivation drops | A demo clip at the end of every phase; use the app daily |

## Decisions
- **Folders:** Downloads first, then your Mithu folder. Organizes everything by default, skipping only what could break or leak. *Break code:* never rearranges files inside a code project (can move the whole project). *Break functionality:* never touches system and Library folders, apps, app data and settings, packages like the Photos library, the Nest's code, or Magpie's vault. *Leak data:* never moves files into shared, synced or public folders, never uploads or sends anything, leaves sensitive-looking files (passwords, keys, IDs, tax forms) in place, only tagging them. When unsure, leaves the file and notes why. Output files from Crow, Swift and Peacock (reports, screenshots, mockups, clips) are tidied too; the Nest's code never is.
- **Wallpapers:** curated, not generated: high-quality images from free photo sites (following attribution rules) or your own Claude Design and Canva exports, whole Mac themed to match.
- **Modes:** Wren creates, names and retires modes on its own from recurring patterns.
- **Settings:** yes to everyday settings per mode (volume, brightness, Night Shift, notifications, Low Power Mode, Bluetooth); never security or privacy settings.
- **Talking to it:** Nest app for the whole flock, plus quick chat from its menu bar bird or a global shortcut.
