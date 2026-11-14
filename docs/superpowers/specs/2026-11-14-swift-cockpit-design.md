# Swift's cockpit: projects, limits, models and memory

Approved in chat on 2026-11-14. Mithun picked the "Cockpit" layout and asked for it to look even better, then said to build it without stopping.

## Why

Swift's close-up was a read-only list. You couldn't set a limit, pick a project, choose a model, or tell Swift what to do in plain words. Every session started cold and re-read the repository. This spec makes Swift something you steer.

## What Mithun asked for

1. You set your own usage limits.
2. Swift works on several projects, each picked with a folder picker.
3. You tell Swift what to do in plain words.
4. Each project has its own memory. It is written by the most capable model in full depth, with nothing lost, and parts that stop being true are deleted. Its job is to save tokens, never to cost accuracy.
5. Subagents per project or task when you choose; otherwise everything stays in one session.
6. Model and effort switch easily.

## Decisions

| Question | Answer |
| --- | --- |
| Rules for projects other than the Nest | Set per project: test command (optional), auto-merge on/off, strict Nest checks on/off. The Nest keeps today's strict rules. |
| When memory is updated | After every task: the session updates the sections its change touched and deletes anything that no longer holds. A full rebuild runs when you ask, or by itself once more than half the sections are stale. |
| Where memory lives | Inside each repository, in `.nest/memory/`, committed on the task's branch so it merges or rolls back together with the code. |
| Where model, effort and subagents are set | A default per project, which any task can override from its row or from chat. Memory builds have their own setting (Opus at max effort by default; any model can be picked). |
| Limits | Two caps you set: how much of the week Swift may use, and how full the five-hour window may get. Each project can also have a share of Swift's weekly cap. The learned forecast can only make Swift more careful, never looser. A live preview shows about how many tasks the cap allows. |
| Layout | Cockpit. Swift's tile sits in the middle of the studio. The left panel is for talking and the queue; the right column holds the instruments (limits, how Swift runs, memory). |

This reverses one earlier decision. "Swift touches only the Nest's code" becomes "Swift touches only the projects you assign it, each in its own folder, by that project's rules." The decision is updated in `docs/birds/swift.md` and `docs/master-plan.md`.

## Parts

All logic lives in NestKit and is tested there. The app only draws it and saves it.

### Run settings (`Settings/RunSettings`)
- `ClaudeModel`: `haiku`, `sonnet`, `opus`, `fable`. Each is a Claude Code `--model` alias.
- `Effort`: `low`, `medium`, `high`, `xhigh`, `max`, the same as `--effort`.
- `RunSettings(model, effort, subagents)`. Its `arguments` are `--model <m> --effort <e>`, plus `--disallowed-tools Agent` when subagents are off. Its prompt line tells the session whether it may split work across subagents.
- A queued task can carry an override, stored in the queue as `model/effort/agents|solo` (for example `opus/max/solo`).
- Sessions are started as `session + arguments + [prompt]`. The app's session command passes `"$@"` to `claude`, so the extra arguments reach it.

### Limits (`Budget`)
- `SwiftLimits(weeklyCap, fiveHourCap)`, both from 0 to 1.
- `BudgetRules` gains `weeklyCap`. A task may start only if `weekly + nextTask` is no more than the lower of `weeklyCap` and `1 - reserve`, where the reserve comes from the forecast or the fixed fallback. Whichever is stricter wins.
- A project's share: the share times `weeklyCap` is the most of the week that project's tasks may use. The usage log records which project each session belonged to.
- `Budget.tasksLeft(cap:)` is the room under a cap divided by the average task cost. It drives the live preview.

### Projects (`Projects/`)
- `SwiftProject`: `id`, `name`, `folder`, `tests` (a command, or none), `autoMerge`, `strictChecks`, `defaults: RunSettings`, `memory: RunSettings`, `share` (or none).
- `SwiftSettings`: limits plus projects. It is saved as JSON in Swift's support folder by `SwiftSettingsStore`. The first time it is read, it holds the Nest with today's rules.
- Each project has its own queue file. The Nest keeps `queue.sqlite`; other projects use `projects/<id>/queue.sqlite`.
- The shift visits every project in turn, each in its own folder, under one budget. Auto-merge happens only when the project has it on and has a test command. Otherwise a done task stays on its branch for you.
- A project with no `CLAUDE.md` gets Swift's general house rules: its own branch, small commits, the summary block.
- The Nest-only checks (no hard-coded design values, and so on) run only when `strictChecks` is on.

### Memory (`Memory/`)
- Layout: `.nest/memory/README.md` is the index (model, date, and the commit it was verified at). Each section is a `.nest/memory/<name>.md` file whose front matter lists `covers:` (the paths it describes) and `verified:` (a commit).
- Build: the request queues a task `M-<n>`, "Build the project's memory brief", carrying the project's memory run settings. It then goes through the normal pipeline: branch, checks, merge.
- Every task's prompt includes the whole brief. The session is told to treat the brief as a map: trust the code wherever they disagree. After its change it updates the sections it made untrue, deletes lines and sections that no longer hold, and sets `verified:` to its own commit.
- Stale: a section is stale when any path it covers changed after its `verified` commit. Swift reads this from git. Once more than half the sections are stale, the next rebuild is queued by itself.

### Plain-language chat
- "Add a task: … Done means: …" still queues directly.
- Anything else goes to a plan pass for the chosen project, using the project's default model. The tasks that come back are queued in order.
- Words in a message set an override for the tasks it creates: "on opus", "max effort", "with agents", "solo".
- "Do Y-03 on opus max" changes one queued task's override.

### Cockpit (app)
- Left panel, `SwiftTalkPanel`: project pills with `+` (folder picker), the folder and rules line, the chat, and the queue. Each queue row has a menu showing its model, effort and subagents setting.
- Centre: the studio flies to Swift's tile, with Swift's name and what it is doing beneath it.
- Right column, replacing focus and needs-you while Swift's close-up is open:
  - `SwiftLimitsPanel`: a ring gauge for the week with a marker at your cap, two sliders, the live "about N tasks left" line, the five-hour bar, and each project's share.
  - `SwiftRunPanel`: model and effort as segmented pills, the subagents switch, the test command, the auto-merge switch, and memory status with a Rebuild button.
- Every value comes from the tokens. Motion is honoured: with reduced motion the gauge moves without animation, and colour changes still show.

## Testing

Each part above has a "done means" in `docs/queue.md` (S2-18 to S2-23). It is tested in NestKit with temp repositories and stand-in sessions, as the runner tests already are. The app's models are tested in NestAppTests.
