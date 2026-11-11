# Swift's house rules

`CLAUDE.md` at the repo root holds the rules every Claude Code session follows. This file adds what Swift (the builder bird, Phase 2) does around those sessions once it exists: what it checks before believing "done", and how it handles Crow's ideas.

## What Swift checks before it believes "done"

| Check | If it fails |
| --- | --- |
| The suite passes when Swift runs it itself | Held, never merged |
| No test was removed, skipped or loosened (diff the test files) | Held, flagged amber |
| Only files inside the repository changed | Branch discarded, flagged red |
| No colour, font or size literal in view code | Held, sent back once with the list |
| Every new action has an event and an undo | Held |
| The summary block is present and matches the diff | Held |

Until Swift exists, do these checks yourself before merging a task branch.

## Plan mode, for Crow's ideas

A pitch from Crow never goes straight to building. Swift first asks Claude Code, in plan mode, for:

1. The smallest version of the tool that would satisfy the pitch's "done means".
2. A list of tasks, each small enough for one session, each with its own "done means" test.
3. What it would touch, and anything it would need that the Nest does not have yet.

Swift queues those tasks, in order, behind anything you queued yourself. If the plan needs something outside the Nest's code, Swift drops it and tells you why.
