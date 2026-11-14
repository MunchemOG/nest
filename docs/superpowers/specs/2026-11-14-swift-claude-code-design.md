# Swift is a visual Claude Code

Approved in chat on 2026-11-14 from the mockup `swift-claude-code-v2`. This replaces the cockpit's chat, memory and per-project rules from `2026-11-14-swift-cockpit-design.md`. The limits, the Nest's autobuild and the learned forecast stay.

## What Swift is

Swift is a visual wrapper around Claude Code that does nothing Claude Code doesn't. You choose a project, a model and an effort, then work with Claude Code in a real interface instead of a terminal. On top of that, Swift runs the Nest's autobuild and any other work you schedule, in the hours it has learned you don't work, inside the limits you set.

## Decisions

| Question | Answer |
| --- | --- |
| Where it lives | Swift's close-up on Home: the session on the left, Swift's tile in the middle, the schedule and limits on the right. A small floating Swift shows the same live session; the menu bar opens it until the desktop birds exist. |
| What a session is | The real `claude` in the project's folder, driven over its stream-json protocol (`--input-format stream-json --output-format stream-json --permission-prompt-tool stdio`). It brings your login, your settings, the folder's `CLAUDE.md` and Claude Code's own per-project memory. Nothing crosses between projects unless you add another folder as a reference. |
| Permissions | Exactly Claude Code's: Allow, Always allow (Claude Code's own suggestion) or Deny on each request, and its modes: Ask, Accept edits, Plan, Auto. |
| Model and effort | Pills in the composer. Model changes live (`set_model`). Effort changes resume the same session with the new `--effort`. |
| Multi-agent work | Claude Code's own Ultracode: a switch in the composer that adds the keyword. Custom subagents are archived (see Later). |
| Memory | Claude Code's per-folder memory only. The `.nest/memory` brief is removed. |
| Projects | A launcher: one tile per folder (an initial on one of the Nest's accent colours), branch and changed files, last sessions, and a 14-day activity strip read from Claude Code's own session history. |
| Scheduled work | Any prompt can become a job: project, prompt, model, effort, Ultracode and mode, run at the next gap, tonight, at a time, or on repeat. Jobs run only while you're away, inside your limits, in a git worktree on their own branch (`swift/<job>`), so your working copy is never touched. Deleting the branch undoes the job. |
| When you work | Learned from the timestamps of your messages in Claude Code's session history, by weekday and hour, over the last four weeks. An hour you've worked in at least twice is yours, and Swift doesn't run in it. |

## Self-driving presence (S2-30)

- **What Swift learns from:** all your work. That's the Mac's active minutes (keyboard or mouse use in a minute, counted per hour, kept only on this Mac in Swift's folder) and the timestamps of your Claude Code messages. Swift's own headless runs are not you and leave no activity.
- **How it learns:** an hour of a day counts as worked if you messaged Claude in it or were active for at least 10 minutes. Each worked hour adds to its weekday-and-hour slot, weighted by how recent it is: 1 for the last week, 0.75, 0.5 and 0.25 for the three before. A slot scoring 1.25 or more is yours: more than any one week, so a single late night doesn't take an hour away from Swift.
- **When you count as away:** after 15 idle minutes in a gap, or after 60 idle minutes at any time. Touching the Mac makes you here again at once. "Hold Swift" in the menu bar keeps you here until you turn it off.
- **Who follows it:** the autobuild and scheduled jobs. Swift decides only *when* to build. *What* to build comes from `docs/queue.md` and, later, Crow.

## Everything Claude Code has (added 2026-11-14)

Swift shows and does everything the terminal does, asking Claude Code itself over the same stream. Nothing is estimated and nothing costs usage to read.

- **Claude's own numbers** (`get_usage`, `get_context_usage`, `initialize`, `rate_limit_event`): your session (five-hour) limit, the week, and each model's own week, each with its reset time; your plan and account; how full the context is and when it compacts; what the session has cost and the lines it changed. Read when a session starts, after every turn, and every five minutes while Swift's close-up is open. The limits panel uses the latest reading, so it no longer waits for a night's run.
- **Sessions:** like Claude Code in several terminal tabs. Each session is its own Claude Code in its own project, shown as a tab with its project and a dot while Claude works or waits for you. Sessions keep running when you switch tabs. Choosing a project opens a fresh session there at once; ⌘N starts a new one in the same project; closing a tab ends only its Claude Code. Esc stops Claude, and `/clear` starts the tab fresh. A past session opens in its own tab.
- **Questions and plans:** when Claude asks a question, Swift shows its options (one or several, plus your own words) and sends your answers back as Claude Code expects. When Claude shows a plan, Swift shows the plan with Approve and Keep planning.
- **What Claude is doing:** its thinking, its to-do list as a live checklist, each subagent's work under its card, compaction, and API retries.
- **Attachments:** paste or drop images and they go with your message; drop a file or type `@` to mention a file in the project.
- **Models:** the picker lists every model your account has, with only the effort levels each one supports, and fast mode when Claude Code offers it.
- **Setup:** your skills, plugins, agents, MCP servers (with their status), output style and effective settings, as Claude Code reports them. You can turn an MCP server on or off, reconnect it, reload plugins and choose the output style. Each change is an undoable event. Permission rules are shown but not changed.

## Parts

- **NestKit `ClaudeCode/`**
  - `ClaudeEvent`: one line of the stream, parsed.
  - `ClaudeSession`: the process. It handles start, send, answers, interrupt, model, mode and stop.
  - `SessionTranscript`: the events folded into what you see.
  - `PermissionAnswer`.
  - `ClaudeHistory`: past sessions and activity per folder, read from Claude Code's projects folder.
- **NestKit `Schedule/`**
  - `SwiftJob`.
  - `JobTiming`.
  - `WorkPattern`: your learned week.
  - `JobRunner`: runs a job in a worktree, headless.
- **App**
  - `SwiftSessionModel`: shared by the close-up and the small Swift.
  - `SwiftSessionPanel` and its item views.
  - `SwiftLauncher`.
  - `SwiftWeekPanel`.
  - `SwiftScheduleSheet`.
  - The small Swift window.

## Later (archived)

- Custom subagents with visual prompts and capabilities.
- Ultracode's workflow-size setting. It has no command-line flag yet.
- Swift's own memory brief.
