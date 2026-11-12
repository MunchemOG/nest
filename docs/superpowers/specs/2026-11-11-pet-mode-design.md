# Pet mode: design

Date: 2026-11-11. Status: approved in brainstorming, waiting for spec review.

## What it is

When a bird has no work, it can leave the menu bar and live on the desktop like a pet: perching on Dock icons, hopping along window tops, preening, flying loops. They are there so working alone at the Mac is less boring. One hotkey sends them all home.

The pets are the same light-mote birds as the menu bar prototype: at rest the motes hold the bird's glyph; in flight they form a flapping bird with a soft trail.

## Who can come out

- Only idle birds: `BirdStatus.resting` or `.asleep`. Asleep counts so pets work before the real birds exist.
- `.active` and `.paused` birds stay home. A bird that turns active while out flies home on the next tick.

## Modes

| Mode | Trigger | Behaviour |
|---|---|---|
| Visitor (default) | Mithun is using the Mac | Every 10–20 min (random), one idle bird comes out for 1–4 min, then flies home. |
| Break buddy | 50 min of continuous input with no pause of 5 min or more | 2–3 idle birds come out on the screen with the pointer for about 3 min. Cool-down: 20 min before it can trigger again. No pop-ups or text. |
| Lively | No input for 3 min | Every idle bird comes out: loops, chasing, perching. On the next input they drift home within about 2 s, except for one visitor if a visit is due. |
| Hidden | Hotkey off, a full-screen app in front, a known meeting app in front (Zoom, Microsoft Teams, FaceTime), or Reduce Motion on | Every bird is home within 420 ms. Nothing comes out until the cause ends. |

If more than one mode applies, the precedence is: Hidden, then Lively, then Break buddy, then Visitor.

All numbers live in `PetSettings` and can be changed from Settings. The values above are the defaults.

## Hotkey

- Default ⌃⌥⌘P toggles pets on and off; the key can be changed in Settings.
- Off sends every bird home within 420 ms. On lets the scheduler run again.
- Whether pets are on is remembered across launches.

## Perches

In order of preference:

1. Dock icons, if Accessibility is granted.
2. The Dock's top edge.
3. The top edges of visible windows.
4. The menu bar.

Accessibility is asked for once, from Settings, never at launch. If it's denied, perches 2 to 4 are used and nothing nags.

## Personalities

Each bird has quirks (habits and how it reacts to the pointer) and context preferences.

| Bird | Habit | Pointer reaction | Prefers to perch on |
|---|---|---|---|
| Wren | Hops a lot | Brave: hops toward a still pointer and sits on it if it stays still | Finder, System Settings |
| Swift | Fast loops | Skittish: darts off at any quick move, circles back | Code editors (Xcode, VS Code, Cursor), Terminal |
| Crow | Pokes at the app just opened | Curious: follows the pointer at a distance, tilts its head at what's hovered | Web browsers |
| Owl | Dozes on a perch | Unbothered: turns its head to watch, blinks, almost never flees | After 23:00, perches near the front app whatever it is |
| Magpie | Collects a glint and drops it at the nest | Cheeky: hops close, "steals" a sparkle from the pointer, runs | Notes apps (Notes, Obsidian) |
| Peacock | Shows off its tail | Vain: fans its tail when hovered, huffs off if rushed | Design apps (Figma, Sketch) |

- When the front app matches a bird's preference, that bird is the favoured visitor and perches on that app's Dock icon or window. Only one preference wins at a time; Owl's late-night rule beats app preferences.
- Clicking a bird opens its quick chat popover, the same one the menu bar bird opens.
- Pets are silent in v1.

## Architecture

### NestKit (`NestKit/Sources/NestKit/Pets/`), pure Swift, no AppKit

| Type | Job |
|---|---|
| `PetWorld` | One snapshot of the inputs: idle birds, seconds since the last input, active streak, front app bundle ID, local hour, pointer position and speed, available perches, hide causes. |
| `PetSettings` | Every threshold in this spec, with the defaults above. |
| `PetMode` | `visitor`, `breakBuddy`, `lively`, `hidden`. |
| `PetScheduler` | Given the world, settings, a clock and a seeded random source, decides the mode and which birds are out. |
| `PetBrain` | A state machine per bird: home, flyingOut, perched, preening, hopping, dozing, fleeing, flyingHome. It turns world plus quirks into a `PetIntent` per bird. |
| `PetIntent` | Pose, target point, and the shape to draw (glyph or flight). |
| `BirdQuirks` | Each bird's personality as numbers (bravery, curiosity, flee distance, how long it stays) plus its preferred app bundle IDs. |

### App: the menu bar helper

Pets live in the menu bar helper: a background agent with no Dock icon (`LSUIElement`), started at login with `SMAppService`, that also hosts the six menu bar birds. Quitting the Nest window doesn't stop the pets.

| Part | Job |
|---|---|
| `PetOverlayWindow` | One borderless, transparent, non-activating panel per screen, above the Dock and on every Space. `ignoresMouseEvents` is on except while the pointer is inside a bird's hit area. |
| `PetRenderer` | A Metal `MTKView`. A compute kernel moves the motes and an additive pass gives the bloom. It pauses when every bird is home. |
| `InputIdleSensor` | Uses `CGEventSource.secondsSinceLastEventType`. No permission. |
| `FrontAppSensor` | Uses `NSWorkspace` for the front app. Full-screen detection uses window bounds only. No permission. |
| `PointerSensor` | Uses `NSEvent.mouseLocation`, polled each tick. No permission. |
| `DockPerchSensor` | Uses Accessibility on the Dock process for icon frames. Optional. |
| `PetHotkey` | A global hotkey via Carbon `RegisterEventHotKey`. No permission. |

## Data flow

1. About 30 times a second, the helper builds a `PetWorld` from the sensors and `FlockSource`.
2. `PetScheduler` picks the mode and who is out. `PetBrain` updates each bird's state and emits its `PetIntent`.
3. `PetRenderer` eases each bird's motes toward its intent at the display's refresh rate.

## Failure handling

- **Metal unavailable:** pets stay off and the menu bar birds behave as before.
- **A screen disconnects mid-flight:** birds on it go home and its window closes.
- **Accessibility denied or revoked:** the fallback perches are used.
- **`FlockSource` unavailable:** every bird is treated as asleep, so all can be pets.

## Safety and the project rules

- Pets change nothing on the Mac: no files, settings or look. So they publish no events and need no undo. The only thing stored is the pets on/off flag and the `PetSettings` values.
- No network, no analytics, no data leaves the Mac.
- Reduce Motion means no movement, so pets stay home. Menu bar colour changes still happen.
- Every colour, size, duration and curve comes from `design/tokens.json`. New tokens are needed for pet sizes, mote counts, flight speed and the 420 ms go-home duration. They're added in the plan, never hard-coded.
- A bird's colour is used only for its own motes.

## Testing

- **`PetScheduler` and `PetBrain`:** Swift Testing with a fake clock and a seeded random source. At minimum:
  - with no input for 3 min, every idle bird is out (lively)
  - 50 min of input with no 5 min break brings 2–3 birds out, then the 20 min cool-down holds
  - a bird turning active heads home on the next tick
  - the hotkey off, a full-screen app, a meeting app or Reduce Motion sends every bird home within 420 ms
  - with Xcode in front, Swift is the favoured visitor
  - after 23:00, Owl wins over app preferences
  - a fast pointer within flee distance makes Swift flee and leaves Owl in place
  - only resting and asleep birds ever come out
- **`BirdQuirks`:** one test per bird pins its personality numbers.
- **Overlay:** one UI test checks the overlay window passes clicks through away from birds.
- **Motion:** judged by eye.
- No test touches the network, real user data, or the file system outside a temp folder.

## Dependencies and order

- **The menu bar birds and helper:** they have to exist first. They aren't in the queue yet and need their own task.
- **The look hold:** `docs/design-status.md` holds back UI work. The NestKit brain (no UI) can be built now; the overlay and renderer wait until the hold is lifted for pets.
- **The queue:** tasks get added to `docs/queue.md` by the implementation plan.

## Not in v1

Sound, picking up and dragging birds, Focus mode detection, reliable screen-share detection, and reacting to Trash state.
