# Swift — the builder

Master-plan phase 2 (Dec 7, 2026 – Jan 17, 2027). Its mind: `docs/minds/swift.md`. The rules it passes to Claude Code: `CLAUDE.md` and `docs/house-rules.md`.

Swift turns a queue of tasks into working, tested code by directing Claude Code, within your Pro plan's limits.

## Who it is
A calm, methodical engineer that cares more about working code than impressive code.
- **Personality:** quiet and precise. Reports plainly, including what failed and why; never oversells a half-done task.
- **Judgment:** decides task order, how to break a big task into small testable steps, and when to stop instead of forcing a bad fix.
- **Initiative:** picks up ideas you approved from Crow. Crow's pitches come from a small local model, so Swift never builds them as written: it first runs Claude Code in plan mode to turn each pitch into a solid step-by-step plan, then builds from that plan. Flags unclear tasks before spending usage on them.
- **Boundaries:** ships on its own, but only work that passes every test; every merge can be undone in one tap.

## What it does
| Capability | Detail |
|---|---|
| Task queue | Tasks come from you or Crow (Crow's rewritten in plan mode first); each has a goal and a "done means" test |
| Runs | Drives the official Claude Code tool, one small task per session. Runs whenever its usage forecast says you won't need your limits (often nights, weekday mornings), stands down the moment Owl sees you sit down |
| House rules | Tests must pass; UI built only from the component library; touches only the Nest's code, never other projects; own git branch, never main |
| Budget | Tracks Pro plan's five-hour and weekly limits, does most important tasks first, pauses until limits reset instead of buying credits. Protects robotics time: forecasts when you'll need Claude Code yourself (robotics weeks and other patterns in Magpie), plans work into the gaps, keeps a reserve sized to that forecast, counting everyday Claude chats too (chats and Claude Code share limits) |
| Report | Waits for whenever you next sit down (Owl notices), not a fixed time. Shows what changed, code diff, before/after screenshots, test results, and what failed with its best guess why |
| Auto-merge | Merges on its own when all tests pass, writing new tests per task so the safety net grows; every merge revertible in one tap; rolls back by itself if something breaks afterward |

## How it's built
Swift is a conductor, not a coder: coding happens inside Claude Code; Swift wraps it in a queue, rules, and reports.
- **Queue:** tasks stored locally (SQLite), each with goal, priority, test
- **Runner:** starts Claude Code in non-interactive mode inside the project folder, passing the task plus house rules
- **Isolation:** a fresh git branch per task, so a bad night never touches working code
- **Checks:** runs the test suite after each task; red means reported as failed, not merged
- **Report UI:** a card in the Nest, shared with Peacock for before/after captures
- **Login:** uses your Pro plan through the official tool only; no API keys

## Build plan
1. **Manual runner:** one task becomes a tested branch while you watch.
2. **Queue and house rules:** SQLite queue, house-rules prompt, plan-mode pass for rough tasks. *Done means: five tasks run back to back, all rules followed.*
3. **Auto-merge and rollback:** merge on green, restore point before every merge, automatic rollback. *Done means: a deliberately broken task is caught and rolled back with no help from you.*
4. **Budget brain:** logs usage per task, simple rules first (robotics hours blocked, fixed reserve), then a learned forecast. *Done means: a full week of runs without touching your reserve.*
5. **Reports and pings:** mission-control report card and critical-only notifications. *Done means: you understand a night's work in 10 seconds.*
6. **Bird connections:** Owl (stand down when you sit down), Magpie (richer forecasts), Crow (approved pitches into queue), Peacock (before/after captures).

## Decisions
- **Scope:** touches only the Nest's code.
- **Merging:** everything merges automatically once tests pass.
- **When it runs:** whenever its usage forecast shows a gap.
- **Pings:** only when critical (a broken Nest it couldn't roll back, or usage about to cut into your reserve). Everything else waits for the report.
- **Voice:** calm mission-control engineer. Every report opens with a green/amber/red status line and the headline result, then at most three short points with real numbers, details folded below. No hype, occasional dry humor.
