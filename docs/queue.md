# Task queue — Phases 1 and 2

One task is one Claude Code session. Start each on its own branch (`task/<id>`). A task is done only when its "done means" test passes along with the whole suite.

**Done:** N1-01, N1-02, N1-04, N1-05, N1-13 to N1-16, and PB-01 to PB-06. **Building now:** N1-03, N1-06 to N1-12 and N1-17 onward; the look is final (`docs/design-status.md`).

## Phase 1 — App shell

**Phase done means: the app shows each bird's status, even before the birds exist.**

### Foundations

| id | goal | done_means | needs |
| --- | --- | --- | --- |
| N1-01 | An Xcode project with a `NestApp` target and a `NestKit` Swift package for shared code | The app builds, opens one empty window, and one placeholder test passes | |
| N1-02 | Every token from `design/tokens.json` available in Swift (`NestColor`, `NestSpace`, `NestRadius`, `NestShadow`, `NestMotion`) | A test loads `tokens.json` and checks each token has a Swift value equal to it | N1-01 |
| N1-03 | The fonts named in `tokens.json` bundled, with each text style as `NestFont` | A test finds every family registered; a preview shows every style | N1-01 |
| N1-04 | The six bird glyphs and the mark from `design/glyphs/` as assets, in tile and menu bar (template) forms | A test loads all 14 images by name | N1-01 |
| N1-05 | A `Bird` type: name, role, colour, glyph | A test checks all six birds resolve every property | N1-02, N1-04 |

### Events (the brain of the app; independent of the look)

| id | goal | done_means | needs |
| --- | --- | --- | --- |
| N1-13 | `NestEvent` and its decoder, following `docs/event-bus.md` | Every example and every topic in the contract decodes; an unknown topic is kept, not a crash | N1-01 |
| N1-14 | `demo-day.jsonl`: one invented day of about 60 events from all six birds | A test decodes the whole file in time order with no errors | N1-13 |
| N1-15 | A `FlockSource` that the app reads events from, with a fake that replays `demo-day.jsonl` | A test replays the day and receives the events in order | N1-14 |
| N1-16 | `FlockState`: each bird's status, latest action and "doing" line, built from events | After replaying the demo day, a test finds the expected status for all six birds | N1-15 |

### Pet brain (no UI; buildable now; spec `docs/superpowers/specs/2026-11-11-pet-mode-design.md`)

| id | goal | done_means | needs |
| --- | --- | --- | --- |
| PB-01 | Pet settings, world snapshot, perches, seeded random and the work-streak tracker | A test sees a 50-minute streak survive a 4-minute pause and reset after a 5-minute one | N1-16 |
| PB-02 | Each bird's quirks and the pet activities | A test pins every bird's personality numbers and favourite apps | PB-01 |
| PB-03 | `PetScheduler`: modes, precedence, who is out | Tests for lively at 3 min, break buddy at 50 min with its 20-min cool-down, visitor timing, hidden causes, and favoured visitor | PB-02 |
| PB-04 | `PetBrain` movement: out, perch, habits, home | A bird turning active heads home on the next tick; hidden sends all home in 420 ms; no shared perches | PB-03 |
| PB-05 | `PetBrain` pointer reactions | A fast pointer makes Swift flee and leaves Owl; each bird's hover reaction matches the spec | PB-04 |
| PB-06 | `PetDirector`: one tick from world to intents | A simulated two-hour session replays identically per seed and keeps every rule | PB-05 |

### Components

| id | goal | done_means | needs |
| --- | --- | --- | --- |
| N1-06 | Button style: variants, sizes, all states | Snapshot tests for each variant and state | N1-02, N1-03 |
| N1-07 | Tag and status pill | Snapshots for every kind and state; motion stops under reduced motion | N1-05 |
| N1-08 | Bird avatar: sizes; resting, active, paused | Snapshots per bird and state | N1-05 |
| N1-09 | Card | Snapshots; only one card in a list can be selected | N1-08 |
| N1-10 | Panel, solid and floating | Snapshots; floating closes on Escape and outside click | N1-02 |
| N1-11 | Chat bubble, typing dots and composer | Snapshots for bird, you, typing | N1-08 |
| N1-12 | A component gallery from a debug menu | A UI test finds each component by its accessibility id | N1-06 – N1-11 |

### Screens

| id | goal | done_means | needs |
| --- | --- | --- | --- |
| N1-17 | The app frame and navigation | A UI test reaches every screen | N1-10, N1-08 |
| N1-18 | Activity row with one-tap Undo and Redo | Tapping Undo publishes `you.undo.asked` with the right target | N1-13, N1-08 |
| N1-19 | The flock overview (every bird and what it's doing) | A new action event makes that bird react once | N1-16 |
| N1-20 | Home | With the demo day replaying, a new event appears live | N1-18, N1-19, N1-09 |
| N1-21 | Timeline: day groups, bird filters, search | Filtering to one bird shows only its rows; search finds a file name | N1-18 |
| N1-22 | "Asleep until Phase N" states for birds not built yet | With an empty source, all six birds show asleep and nothing crashes | N1-20 |
| N1-23 | Reduced motion and run-time accent change | Changing the accent recolours every primary control; with reduced motion nothing moves | N1-20 |
| N1-24 | A 30-second demo recording of the shell replaying the demo day | The clip exists; you would post it | N1-22 |

## Phase 2 — Swift core

**Phase done means: a full week of overnight runs, every merge green, nothing rolled back by hand, your reserve untouched.**

| id | goal | done_means | needs |
| --- | --- | --- | --- |
| S2-01 | Manual runner: one task becomes a tested branch while you watch | One real task ends on its own branch with passing tests and the summary block | Phase 1 |
| S2-02 | The queue in SQLite: goal, done_means, priority, needs, source, state | A test adds, orders, claims and finishes tasks; `needs` is respected | S2-01 |
| S2-03 | The runner passes `CLAUDE.md` plus the task, non-interactively, and reads back the summary block | Five tasks run back to back, each on a fresh branch, all rules followed | S2-02 |
| S2-04 | Checks before believing "done": suite passes, no test weakened, only repo files changed, no hard-coded design values, every action has an undo | A branch that weakens a test, and one with a colour literal, are both held | S2-03 |
| S2-05 | Plan-mode pass for rough tasks | A vague idea comes back as three or more small tasks with tests, queued in order | S2-03 |
| S2-06 | Auto-merge on green with a restore point before every merge | A green task merges with no help; one tap returns to the restore point | S2-04 |
| S2-07 | Automatic rollback when a later run breaks | A deliberately broken task is caught and rolled back with no help | S2-06 |
| S2-08 | Usage log: cost of each task and of your own chats, against the five-hour and weekly limits | After a night's run, the log's total matches what Claude reports to within a few percent | S2-03 |
| S2-09 | Budget rules: robotics hours blocked, a fixed reserve, stop when a task would cross it | With the reserve set high on purpose, Swift pauses instead of running | S2-08 |
| S2-10 | Stand down when you arrive; until Owl exists, a menu bar "I'm here" switch publishes `owl.presence.changed` | Flipping the switch mid-run makes Swift finish its step and stop | S2-03 |
| S2-11 | `swift.report.ready` built from a run | A fixture run of 11 tasks yields the expected status, headline and three points | S2-07, S2-08 |
| S2-12 | Swift's reports shown in the app | Details open in place | S2-11 |
| S2-13 | Swift's page: chat, tonight's queue, usage, boundaries | You can add a task by chat and see it in the queue | S2-12 |
| S2-14 | Critical-only pings | A simulated red sends one notification; a simulated amber sends none | S2-11 |
| S2-15 | Learned forecast replaces the fixed reserve | Over a week of logged days, the forecast leaves at least what you actually used on every day | S2-09 |
| S2-16 | Swift runs itself from the app: once you're away it brings in `docs/queue.md`, builds what's ready, merges green work and reports, with no one at the Mac | With you away and the budget open, a fixture night builds a ready task, merges it and publishes `swift.report.ready`; with you here it starts nothing | S2-14, S2-15 |
| S2-18 | Run settings: model, effort and subagents passed to Claude Code; a project default and a per-task override kept in the queue (spec `docs/superpowers/specs/2026-11-14-swift-cockpit-design.md`) | A task queued as Opus · max · solo starts its session with `--model opus --effort max --disallowed-tools Agent`; a task with no override uses the default | S2-16 |
| S2-19 | Your limits: a weekly cap and a five-hour cap you set, a share per project, the forecast only tightening, and a tasks-left preview | With a 40% cap Swift pauses before crossing it; a forecast stricter than the cap wins, a looser one doesn't; a project over its share pauses while another runs | S2-18 |
| S2-20 | Projects: Swift's settings file with your projects (folder, tests, auto-merge, strict checks, defaults, share); the shift builds each project's queue in its own folder | A fixture night builds a task in two repos; the one with tests merges, the one without stays on its branch | S2-19 |
| S2-21 | Project memory in `.nest/memory/`: built by a deep session, carried in every task's prompt, updated after each task, stale sections found from git | Each prompt carries the brief; changing a covered file marks its section stale; past half stale, a rebuild is queued | S2-20 |
| S2-22 | Tell Swift in plain words: chat goes through a plan pass for the chosen project, and words like "on opus, max, with agents" set the override | A plain request with a stand-in plan pass queues its tasks with the override; "do Y-03 on opus" changes one task | S2-21 |
| S2-23 | Swift's cockpit: talk and queue on the left, Swift in the middle, limits, run settings and memory on the right; folder picker for projects | Moving the cap changes the tasks-left line and is saved; picking a folder adds a project; switching model saves the default | S2-22 |
| S2-24 | Claude Code from Swift: drive the real `claude` over stream-json (start, send, stream, permission answers, interrupt, model, mode, resume) and fold its events into a transcript (spec `docs/superpowers/specs/2026-11-14-swift-claude-code-design.md`) | A stand-in `claude` streams a reply, asks permission for a Write and gets Allow, then is interrupted; the transcript shows the text, the tool card, the answered permission and the stop | S2-23 |
| S2-25 | Drop Swift's own memory brief; archive custom subagents | No prompt carries `.nest/memory`, no night queues a memory build, and the spec lists subagents under Later | S2-24 |
| S2-26 | Project library: tiles, branch and changed files, past sessions and a 14-day activity strip from Claude Code's history | From a fixture history folder, a project lists its sessions newest first with titles, and its strip counts your messages per day | S2-25 |
| S2-27 | Swift's close-up becomes Claude Code: session on the left with tool and permission cards, composer with model, effort, Ultracode and mode, the project launcher | Sending from the model reaches the stand-in `claude` with the chosen model and effort and Ultracode adds the keyword; Allow on a card answers the request | S2-26 |
| S2-28 | The small Swift: a floating window with the same live session, opened from the menu bar | The menu item opens the window and both views share one session | S2-27 |
| S2-29 | Scheduled work in the hours you don't work: jobs, your learned week, worktree runs inside your limits, the schedule sheet and Swift's week | With you away in a learned gap and budget open, a due job runs in a worktree on `swift/<job>` and the main checkout is untouched; with you here or in your hours it waits | S2-28 |
| S2-30 | Swift learns your week from all your work (the Mac's active minutes plus your Claude Code messages, recent weeks counting most) and decides by itself when you're away; the autobuild and scheduled jobs follow it, and "Hold Swift" in the menu bar pauses it | Idle 15 minutes in a learned gap makes Swift away and starts nothing in your hours until an hour idle; touching the Mac brings it back; a week of activity three weeks ago counts less than last week | S2-29 |
| S2-31 | Claude's own numbers in Swift: your session, week and per-model limits with their reset times, plan and account, context left, cost and lines changed, read from Claude Code (`get_usage`, `get_context_usage`, `initialize`, `rate_limit_event`) on start, after each turn and every five minutes; the limits panel uses the latest reading | A stand-in `claude` reports 2% of the session resetting at 8:39pm, 90% of the week and 42% of Fable's week, Pro, and 2% of the context; Swift shows each with its reset and the ring reads 90% with no usage log | S2-30 |
| S2-37 | Sessions like Claude Code: each session is its own Claude Code in its own project, shown as tabs; several run at once and keep going when you switch away; choosing a project opens a fresh session there at once; ⌘N starts a new one, Esc stops Claude, `/clear` starts fresh, and a past session opens in its own tab | Two sessions in two projects each reach the stand-in in their own folder and keep their own transcripts; switching project shows an empty session at once; closing a tab ends only its Claude Code | S2-31 |
| S2-32 | Claude's questions and plans: a question card with its options (one or several, or your own words) that answers as Claude Code expects, and a plan card with Approve and Keep planning | The stand-in asks "Red or blue?"; picking Blue sends the answer back and the card shows it; Approve on a plan allows it, Keep planning denies it with your note | S2-31 |
| S2-33 | What Claude is doing: thinking, the to-do list as a live checklist, subagents' work under their card, compaction and retries in the transcript | From a stand-in stream, thinking shows folded, a to-do update ticks items, a subagent's tool sits under its Task card, and a compaction and a retry each show a line | S2-32 |
| S2-34 | Attachments: paste or drop images to send with your message; drop files or type `@` to mention a project file | A pasted image reaches the stand-in as an image block with your text; typing `@Pa` suggests `Package.swift` and picking it puts `@Package.swift` in the message | S2-33 |
| S2-35 | Every model your account has, with only the effort levels each supports, and fast mode when Claude Code offers it | From the stand-in's model list the picker shows its names, a model without `max` hides it, and fast mode shows only when the session says it is available | S2-34 |
| S2-36 | Claude Code's setup in Swift: skills, plugins, agents, MCP servers with status, output style and effective settings; turn an MCP server on or off, reconnect, reload plugins, pick the output style, each as an undoable event; permission rules shown, never changed | Turning a server off sends `mcp_toggle` and publishes an event whose undo turns it back on; the setup sheet lists the stand-in's skills and servers | S2-35 |
| S2-17 | A week of real overnight runs | The phase's done-means line | all |
