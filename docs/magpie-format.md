# Magpie's memory — note format and vault layout

How the Nest's shared memory is written down. Plain Markdown that opens as an Obsidian vault, one format for every note, so any bird (and you) can read it forever. A contract to code against.

## The vault

```
Nest Vault/
  Days/            2026-11-10.md            one per day, auto-written, editable
  Projects/        Swerve pod.md            one per project
  Ideas/           Screenshot naming.md     one per idea, including Crow's pitches
  People/          Coach R.md               one per person who matters to a project
  You/             Goals.md, Schedule.md, To-dos.md, Voice.md
  Birds/
    Wren/          Lessons.md, Modes.md
    Swift/         Reports/2026-11-10.md, Usage.md
    Crow/          Pitches/…, Taste.md
    Owl/           Focus patterns.md
    Magpie/        Decisions.md
    Peacock/       Wins/…, Devlogs/…
  Archive/         anything moved out to keep search fast; still searchable
```

Outside the vault, never synced into it: `index.sqlite` (keyword and embedding index, rebuildable from the notes) and `events/` (the bus's raw seven-day log).

## Every note

```markdown
---
id: n_01JCF8R1ZK
type: project
title: Swerve pod
created: 2026-03-14
updated: 2026-11-10
by: magpie
tags: [robotics, ftc]
links: ["[[Gear ratios]]", "[[Servo question]]"]
sources: [evt_01JCF8Q2X9M4]
you_edited: false
---

# Swerve pod

One paragraph: what this is and where it stands.

## Decisions
- 2026-03-14 Chose a 96mm wheel. [[Gear ratios]]

## Open
- Does the steering servo have enough torque on carpet?

## Log
- 2026-11-10 Wren filed swerve-pod-v4.step under Robotics / CAD.
```

| Field | Meaning |
| --- | --- |
| `id` | `n_` + a ULID; never changes, even if the title does |
| `type` | `day`, `project`, `idea`, `person`, `goal`, `lesson`, `pitch`, `report`, `win`, `devlog`, `decision` |
| `by` | The bird that first wrote it, or `you` |
| `links` | Wiki links to other notes; Magpie also keeps the reverse links in the index |
| `sources` | The event ids this note was built from. This is what makes "forget" complete. |
| `you_edited` | Turns true the moment you change the note by hand |

## Rules

1. **Your edits always win.** Once `you_edited` is true, Magpie never rewrites your words. It may only append under `## Log` and add links, and it treats what you changed as a lesson.
2. **One gatekeeper.** Other birds never write files. They publish events; Magpie decides which note each belongs in.
3. **Append, don't rewrite.** Facts are added as dated lines. The opening paragraph is the only part Magpie rewrites, and only while `you_edited` is false.
4. **Link by meaning, show the reason.** When Magpie links two notes it adds one line saying why: "Both are about the pod's gear ratio."
5. **Short notes.** A note over about 400 lines is split by Magpie into linked parts.

## What is never stored

Passwords, keys and tokens; card, account and ID numbers; anything from a private browser window; raw screenshots and video (only short notes about them); the contents of files Wren tagged as sensitive. If one of these shows up in an event, Magpie stores "something sensitive, skipped" and nothing else.

## Daily note

```markdown
---
id: n_01JCF9…
type: day
title: 2026-11-10
by: magpie
---
# Tuesday 10 November

**In one line:** Robotics until 18:00, physics set finished, Swift merged 9 tasks.

## You
- 16:40 Resumed AP Physics (2h 10m, one nudge).

## The flock
- Wren: 41 moves, 2 undone. [[Lessons]]
- Swift: Green. 9 of 11 merged. [[2026-11-10 report]]
- Crow: pitched [[Screenshot naming]]. You said Build it.

## Tomorrow
- Physics problem set 8 due 16:00.
```

Written at the end of the day from that day's events; yours to edit.

## Lessons: how the birds learn

Every correction (you undo something, move a file back, reject a wallpaper, answer a pitch) becomes one entry in that bird's `Lessons.md` and one line in a training file.

```markdown
- 2026-11-10 **Screenshots of field diagrams are robotics, not school.**
  Wren put `auto-path-blue-left.png` in School / Physics. You moved it to Robotics / Autonomous.
  ^lesson-01JCFA
```

Training line, one JSON object per line in `training/<bird>.jsonl` (outside the vault):

```json
{"id": "lesson-01JCFA", "bird": "wren", "ts": "2026-11-10T08:20:00-06:00", "context": {"name": "Screenshot 2026-11-10 at 08.14.png", "ocr": "blue alliance · start left · path", "open_project": "Robotics"}, "bird_did": {"op": "file.move", "to": "School/Physics"}, "you_did": {"op": "file.move", "to": "Robotics/Autonomous"}, "lesson": "Screenshots of field diagrams are robotics, not school."}
```

A fine-tune is worth running once a bird has a few hundred of these. The test for a new model: it must beat the old model on 100 held-back corrections.

## Asking Magpie

Birds and the app ask through the bus (`ask` to `magpie`) and get back notes, never file paths:

```json
{"answer": "You decided Swift keeps no fixed reserve; it learns your usage and holds back what you usually need.", "notes": ["n_01JB…"], "confidence": 0.9}
```

If Magpie is not sure, it says so and returns the closest notes instead of guessing.

## Forgetting

"Forget X" removes: the notes about X, every line in other notes whose `sources` came from X, the lessons and training lines built from it, and its index entries. Magpie then publishes `magpie.memory.forgotten` with a count and no content. This is the one action in the Nest with no undo, so Magpie shows what will go and asks once.

## Archiving

Only when it keeps search fast or the vault easier to use: a project untouched for six months moves to `Archive/` whole. Archived notes keep their ids and links, stay searchable, and move back the first time they are linked again.
