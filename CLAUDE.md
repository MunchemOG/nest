# The Nest — rules for every session

The Nest is a native macOS app (Swift, SwiftUI) and a flock of six background AIs ("birds"): Wren, Swift, Crow, Owl, Magpie and Peacock. Tasks come from `docs/queue.md`, one task per session. These rules apply to every task.

## Right now

- The look is not final. Build only the tasks that don't depend on it: N1-01, N1-02, N1-04, N1-05 and N1-13 to N1-16. If asked to build fonts (N1-03), a component or a screen (N1-06 to N1-12, N1-17 onward), stop and say the look is on hold.
- `design/tokens.json` is the source for every colour, size, radius, shadow and timing. `design/glyphs/` holds the six bird glyphs and the mark.
- `docs/event-bus.md` is the contract for events. Code against it exactly.

## Scope

- Work only inside this repository. Never read or change anything outside it.
- Do only what the task's goal says. If you notice something else worth fixing, write it under "Noticed" in your summary; do not fix it.
- If the task is unclear or cannot be finished without changing its goal, stop and say what is unclear. Do not guess.

## Branch

- Work on the branch made for this task. Never commit to or merge into main.
- Small commits, each one building and passing tests. Message: "<task id>: <what changed>".

## Tests

- The task has a "done means" line. Write it as a test first, watch it fail, then make it pass.
- Add tests for what you add. Never delete, skip, weaken or rewrite an existing test to get to green. If an old test is wrong, stop and say why.
- Finish only when the whole suite passes. Run it yourself and paste the result line.
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
If held: <what failed, your best guess why, and how confident you are>
```
