# The Nest — rules for every session

The Nest is Mithun's year-long solo project: a native macOS app (Swift, SwiftUI) and a flock of six background AIs ("birds") that run his Mac on their own: Wren, Swift, Crow, Owl, Magpie and Peacock. Tasks come from `docs/queue.md`, one task per session. These rules apply to every task.

## Where everything is

Read what the task needs; don't read everything every time.

| File | What it holds | Read it when |
| --- | --- | --- |
| `docs/queue.md` | Every task for Phases 1 and 2, each with a goal and a "done means" test | Always, for the task you're on |
| `docs/master-plan.md` | The whole project: the flock, principles, brains, build order, decisions | You need the big picture |
| `docs/nest-app.md` | The Nest app: screens, ways in, how it's built | Working on the app |
| `docs/event-bus.md` | The event contract every bird and the app speak | Anything touching events (N1-13 onward) |
| `docs/magpie-format.md` | Memory: vault layout, note format, lessons, forgetting | Anything touching memory (Phase 4) |
| `docs/design-status.md` | The approved look: the scene, the interface, what was rejected | Before any UI work |
| `design/reference/` | The approved Home prototype (`home.html`) and a still (`home.png`) | Building any component or screen |
| `docs/house-rules.md` | What Swift checks before merging; plan mode for Crow's ideas | Phase 2, or before merging |
| `docs/birds/<bird>.md` | Each bird's spec: job, powers, how it's built, decisions | Building that bird |
| `docs/minds/README.md`, `docs/minds/<bird>.md` | Each bird's prompt, allowed actions, voice and examples | Building that bird's brain or chat |
| `design/tokens.json` | Every colour, size, radius, shadow and timing | Any value in code |
| `design/glyphs/` | The six bird glyphs and the Flight m mark (SVG) | Assets |

If these docs disagree, `CLAUDE.md` wins, then `docs/queue.md`, then the rest.

## Right now

- The look is final (approved 2026-11-12). Read `docs/design-status.md` before any UI work, and match the approved prototype `design/reference/home.html`. Every value still comes from `design/tokens.json`.
- Done: N1-01, N1-02, N1-04, N1-05, N1-13 to N1-16 and PB-01 to PB-06.
- Order: N1-03, N1-06, N1-07, N1-08, N1-09, N1-10, N1-11, N1-12, N1-17, N1-18, N1-19, N1-20, N1-21, N1-22, N1-23, N1-24.
- `docs/event-bus.md` is the contract for events. Code against it exactly.

## How a task runs

1. Mithun says "Do task N1-xx". Check its `needs` in `docs/queue.md` are merged into main; if not, say which.
2. Make sure you're on branch `task/N1-xx` (create it from main if needed).
3. Write the "done means" test first, watch it fail, then build until it and the whole suite pass.
4. Commit, then reply with the summary block (below).
5. After Mithun checks it, he may ask you to merge: `git switch main && git merge --no-ff task/N1-xx && git push`, then start the next task's branch.

## Scope

- Work only inside this repository. Never read or change anything outside it.
- Do only what the task's goal says. If you notice something else worth fixing, write it under "Noticed" in your summary; do not fix it.
- If the task is unclear or cannot be finished without changing its goal, stop and say what is unclear. Do not guess.

## Branch

- Work on the branch made for this task. Never commit to main, except the merge in step 5 when Mithun asks.
- Small commits, each one building and passing tests. Message: "<task id>: <what changed>".

## Tests

- Write the "done means" test first, watch it fail, then make it pass.
- Add tests for what you add. Never delete, skip, weaken or rewrite an existing test to get to green. If an old test is wrong, stop and say why.
- Finish only when the whole suite passes. Run it yourself (`xcodebuild test -scheme NestApp -destination 'platform=macOS'`) and paste the result line.
- Tests must not touch the network, the real file system outside a temp folder, the camera, or real user data.

## Design

- Never hard-code a colour, font, size, radius, shadow, duration or curve. Use the tokens. If the value you need has no token, stop and say which one is missing.
- A bird's colour is used only for that bird.
- Honour reduced motion: no movement, but colour changes still happen.

## Safety

- Every action a bird takes must be an event with an undo (see `docs/event-bus.md`). Code that changes the user's files, look or settings without publishing an undoable event is a bug.
- Never delete user files. Never change security or privacy settings. Never send data off the Mac. Never add analytics.
- No new dependency unless the task names it. Prefer Apple frameworks.
- No secrets, keys or tokens in the repository.

## Code

- Swift 6, SwiftUI, async/await, Swift Testing. Match the style of the files around you.
- Keep files small and named for what they hold. One type per file for views and models.
- Public things in NestKit get a one-line doc comment.
- Leave no TODO, commented-out code or debug print.

## When you finish, reply with exactly this

```
Result: done | held | unclear
Did: <one sentence>
Tests: <passed>/<total>, <new tests added>
Files: <list>
Noticed: <anything outside the task, or "nothing">
Next: <the next task in order, and whether its needs are met>
If held: <what failed, your best guess why, and how confident you are>
```
