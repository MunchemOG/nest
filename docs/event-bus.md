# Nest event bus — message contract

The one format every bird speaks. Birds never call each other: a bird publishes an event, and any bird that cares hears it. The Nest app draws its live timeline from the same stream, and Magpie stores every event as history.

## Rules of the bus

1. **Local only.** Events never leave the Mac.
2. **Publish facts, not requests.** "Owl saw Mithun leave", not "Wren, tidy now". Wren decides what leaving means for Wren. The only request-shaped event is `ask`, and only you or the app send it.
3. **Every action carries its own undo.** If an event changed something, its `undo` field holds everything needed to reverse it. No undo, no action.
4. **One sentence a human can read.** `summary` is exactly what the Timeline shows.
5. **Magpie hears everything** and is the only writer to the vault. Other birds read memory by asking Magpie, never by opening files.
6. **Quiet by default.** An event reaches you (Inbox, ping, sound) only if its `attention` says so.

## The envelope

Every event is one JSON object:

```json
{
  "id": "evt_01JCF8Q2X9M4",
  "ts": "2026-11-10T08:14:07-06:00",
  "bird": "wren",
  "kind": "action",
  "topic": "wren.file.moved",
  "summary": "Wren moved swerve-pod-v4.step to Robotics / CAD",
  "data": {"from": "~/Downloads/swerve-pod-v4.step", "to": "~/Mithu/Robotics/CAD/swerve-pod-v4.step", "rule": "ext+project", "confidence": 0.94},
  "undo": {"op": "file.move", "args": {"from": "~/Mithu/Robotics/CAD/swerve-pod-v4.step", "to": "~/Downloads/swerve-pod-v4.step"}},
  "caused_by": "evt_01JCF8PZ7T11",
  "attention": "none"
}
```

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | string | `evt_` + a ULID, so ids sort by time |
| `ts` | string | ISO 8601 with offset |
| `bird` | string | `wren`, `swift`, `crow`, `owl`, `magpie`, `peacock`, `you` or `app` |
| `kind` | string | One of the seven kinds below |
| `topic` | string | `<bird>.<thing>.<what happened>`, past tense |
| `summary` | string | One sentence, starts with the bird's name, past tense, 90 characters at most |
| `data` | object | Details for that topic |
| `undo` | object or null | `{op, args}` that reverses this event; null if nothing changed |
| `caused_by` | string or null | The event that led to this one |
| `attention` | string | `none`, `inbox`, `calm` (show at the next calm moment) or `ping` (interrupt now) |

## Kinds

| Kind | Used for | `undo` |
| --- | --- | --- |
| `signal` | Something a bird noticed: you sat down, a file appeared, tests passed | null |
| `action` | Something a bird changed | required |
| `undo` | An action was reversed (`data.target` is the action's id) | required (this is Redo) |
| `pitch` | Crow proposes a tool | null |
| `report` | Swift reports a run; Peacock announces a post kit | null |
| `note` | Magpie wrote or linked memory | required |
| `ask` | You or the app tell a bird something (`data.to`, `data.text`) | null |

## Flock state

Four values every bird reads before acting. Each changes only through its signal.

| State | Values | Set by | Effect |
| --- | --- | --- | --- |
| `presence` | `here`, `away`, `stranger`, `guest` | `owl.presence.changed` | `away`: Wren may tidy, Swift may run. `stranger`: every bird pauses. `guest`: carry on, no alert. |
| `flow` | `true`, `false` | `owl.flow.changed` | `true`: nothing with `attention` above `none` is shown; it waits. |
| `mode` | a mode name | `wren.mode.changed` | Other birds may adapt (Owl's nudges know you're in "Robotics"). |
| `paused` | list of birds | `app.bird.paused`, `app.bird.resumed` | A paused bird publishes nothing but `signal`s about itself. |

A **calm moment** is: `presence` is `here`, `flow` is false, and no keyboard or pointer input for 20 seconds. Events with `attention: "calm"` wait for one.

## Topics

| Bird | Topic | Kind | Key `data` |
| --- | --- | --- | --- |
| Owl | `owl.presence.changed` | signal | `to`, `was` |
| Owl | `owl.flow.changed` | signal | `to` |
| Owl | `owl.distraction.noticed` | signal | `minutes`, `context`, `due` |
| Owl | `owl.nudge.given` | action | `step` (1–4), `about` |
| Owl | `owl.screen.locked` | action | `reason` (`left`, `stranger`) |
| Owl | `owl.gesture.done` | action | `gesture`, `effect` |
| Wren | `wren.file.moved`, `wren.file.renamed` | action | `from`, `to`, `rule`, `confidence` |
| Wren | `wren.file.skipped` | signal | `path`, `why` |
| Wren | `wren.folder.created` | action | `path`, `project` |
| Wren | `wren.look.changed` | action | `wallpaper`, `appearance`, `accent` |
| Wren | `wren.mode.changed` | action | `to`, `was`, `settings` |
| Wren | `wren.workspace.restored` | action | `project`, `files`, `tabs`, `windows` |
| Swift | `swift.run.started`, `swift.run.finished` | signal | `tasks`, `branch` |
| Swift | `swift.task.merged` | action | `task`, `commit`, `tests_added` |
| Swift | `swift.task.held`, `swift.task.failed` | signal | `task`, `guess`, `confidence` |
| Swift | `swift.merge.rolled_back` | undo | `target`, `why` |
| Swift | `swift.report.ready` | report | `status`, `headline`, `points`, `usage` |
| Crow | `crow.friction.seen` | signal | `pattern`, `count` |
| Crow | `crow.pitch.made` | pitch | `headline`, `evidence`, `minutes_saved`, `scope` (`nest`, `other`) |
| Crow | `crow.pitch.answered` | signal | `pitch`, `answer` (`build`, `later`, `never`) |
| Magpie | `magpie.note.written`, `magpie.note.linked` | note | `note`, `links` |
| Magpie | `magpie.lesson.learned` | note | `bird`, `lesson`, `from` |
| Magpie | `magpie.memory.forgotten` | action | `what`, `derived` (undo is null: forgetting is the one thing that cannot be undone) |
| Peacock | `peacock.win.seen` | signal | `what`, `trigger` |
| Peacock | `peacock.clip.saved` | action | `path`, `seconds` |
| Peacock | `peacock.kit.ready` | report | `platform`, `title`, `path`, `best_time` |
| You | `you.undo.asked` | ask | `target` |
| You | `you.correction.made` | signal | `target`, `what_you_did` |
| App | `app.ask.sent` | ask | `to`, `text` |
| App | `app.bird.paused`, `app.bird.resumed` | signal | `bird` |

A new topic is added here first, then built.

## Undo ops

| `op` | `args` | Reverses |
| --- | --- | --- |
| `file.move` | `from`, `to` | A move or rename |
| `folder.remove_if_empty` | `path` | A created folder |
| `look.set` | `wallpaper`, `appearance`, `accent` | A restyle |
| `mode.set` | `to` | A mode switch |
| `workspace.close` | `opened` | A restored workspace |
| `git.revert` | `commit` | A merge |
| `note.restore` | `note`, `content_before` | A note edit or link |
| `app.unhide` | `bundle_id` | Owl hiding a distracting app |

Undoing publishes an `undo` event whose own `undo` is the original action, which is how Redo works.

## Who listens to what

| Listener | Hears | And then |
| --- | --- | --- |
| Wren | `owl.presence.changed`, `owl.flow.changed`, `peacock.kit.ready`, `you.correction.made` | Tidies when you leave; switches modes; files post kits; learns |
| Swift | `owl.presence.changed`, `crow.pitch.answered` (build + nest) | Stands down when you arrive; queues the pitch for plan mode |
| Crow | every `action`, `undo` and `you.correction.made` | Finds what you keep doing by hand |
| Owl | `wren.mode.changed`, `crow.friction.seen` | Judges distraction by context |
| Peacock | `swift.task.merged`, `swift.report.ready`, `wren.look.changed`, `owl.flow.changed` | Captures wins; stays quiet in flow |
| Magpie | everything | Writes history, lessons and daily notes |
| Nest app | everything | Timeline, flock overview, Inbox |

## Left open

- **Transport.** Anything local with publish and subscribe works. Simplest first version: an append-only JSONL file per day that every bird tails, plus a Darwin notification to wake listeners. Move to XPC or a Unix socket only if that proves slow.
- **Delivery.** At least once; listeners ignore an `id` they have seen.
- **Retention on the bus.** Seven days of raw events; Magpie keeps the history that matters.
