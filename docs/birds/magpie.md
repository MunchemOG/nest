# Magpie — the second brain

Master-plan phase 4 (Mar 15 – Apr 25, 2027). Its mind: `docs/minds/magpie.md`. Note format and vault layout: `docs/magpie-format.md`.

Magpie collects what you do, what you want, what you plan, and what every other bird does, and keeps it all as one linked, searchable memory on your Mac.

## Who it is
A patient collector with an eye for connections.
- **Personality:** curious, organized, quietly delighted when two ideas months apart connect.
- **Judgment:** decides what's worth keeping and what's noise.
- **Initiative:** surfaces forgotten connections ("this links to what you saved in March") when useful.
- **Boundaries:** everything stays on your Mac; anything you ask it to forget is gone, along with what it learned from it.

## What it does
| Capability | Detail |
|---|---|
| Shared memory | Every bird reads and writes here: Wren's file moves, Owl's focus patterns, Crow's pitches, Swift's reports, Peacock's wins |
| Your life | Goals, to-dos, schedule, projects, ideas, from what you tell it and what the birds observe |
| Linked notes | One note per project, idea, person and day, automatically linked |
| Daily notes | A short auto-written journal of the day, editable |
| Ask anything | "What did I decide about Swift's budget?" answers with links to the notes behind it |
| Connections | Surfaces related notes you'd forgotten, when relevant |
| Forget | Delete anything on command, plus everything derived from it |

## How it's built
Plain Markdown files are the source of truth, with a fast index on top, so memory is readable forever and never locked in.
- **Storage:** folder of linked Markdown notes; opens directly as an Obsidian vault
- **Index:** SQLite plus local embeddings for instant keyword and meaning search, rebuildable from the notes
- **One gatekeeper:** other birds write only through Magpie, so every note follows one format
- **Calendar and to-dos:** reads Apple Calendar and Reminders through EventKit
- **Speed:** searches answer from the index instantly; the local model is used only for summaries and connections
- **Safety:** FileVault on disk, optional Time Machine backups, no cloud

## Decisions
- **What it remembers:** anything useful by default. Never stores passwords, keys, card/account numbers or ID numbers; ignores private browser windows; drops anything you tell it to forget.
- **Viewer:** both: a view inside the Nest app (search, timeline, map of linked ideas) plus Obsidian for heavy editing.
- **Hand editing:** yes. Your edits always win over Magpie's, and it learns from what you change.
- **iPad access:** yes, later, for every bird: a private web version of the Nest app served from your Mac over Tailscale.
- **Archiving:** only when it keeps search fast or memory easier to use. Archived notes are never deleted, stay searchable, come back when relevant.
