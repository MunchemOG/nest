# Design status

**The direction is final.** Mithun approved the Home screen on 2026-11-12. Components and screens can be built against it, using `design/tokens.json` for every value.

The approved prototype is `design/reference/home.html` (open it in a browser; it runs on its own). `design/reference/home.png` is a still of the main screen. When this file and the prototype disagree on a value, the tokens win; when they disagree on behaviour, ask.

## The direction in one line

A dark 3D studio where the six birds fly as solid app-icon tiles, framed by smoked-glass panels, in the spirit of visionOS and a Tesla car screen.

## What is settled

### The scene

- **The birds are their icons.** Each bird is its `design/glyphs/` icon made solid: a glossy ceramic tile in the bird's colour (`radius-tile` corners), with the glyph cut as one clean piece in black enamel (`glyph-ink`), floating just in front of the tile and casting a soft shadow on it. Never rebuild a glyph from separate strokes.
- **The flock flies in a V.** A working bird leads at the point, idle birds fan out behind, paused birds trail at the back. When a bird starts or stops working, the flock glides into its new order. A slow wave runs down each arm, so the tiles rise, dip and bank in turn.
- **The studio.** A near-black space (`scene-void`) with a lacquered floor (`scene-floor`) that mirrors the tiles faintly and fades with depth. A curved back wall carries a soft wash of light whose tint follows the Mac's mode (`mode-morning`, `mode-focus`, `mode-night`). Each tile drops a soft shadow and a little light of its own colour onto the floor.
- **The camera.** It drifts slowly around the flock, and the tiles lean toward the pointer. Depth of field keeps the lead bird sharp.
- **Close-up.** Clicking a bird glides the camera to it. The other five slide out of frame, and the bird slowly turns to show its form. Its panel (name in `display-xl`, status, progress, last three actions, Message / Undo / Pause) sits on the left.

### The interface

- **Smoked glass for everything that floats** (`glass`, `blur-glass`, `shadow-panel`, `radius-xl`): the side rail, the mode switch, the focus widget, the needs-you stack and the activity feed.
- **Layout on one grid:** rail at 24px from the left, content from 112px, 32px gutters on the right and bottom.
- **Headline:** one plain statement in `display-l`, with bird names in their own colour, and one quieter line beneath it in `body-l`. A new statement arrives word by word.
- **Command bar:** a pill in `glass-bar` with `shadow-bar`. The six mini bird icons at its left pick who you are talking to.
- **Mini bird icons** (26px tiles with `shadow-icon`) mark a bird everywhere in the UI, so the 3D tiles and the UI match.
- **Controls are pills** (`radius-full`). One white primary action per card.
- **Type:** Inter Tight for display and titles, Inter for text, IBM Plex Mono for code only.

### Unchanged from before

- **Colours by role.** Each bird has its own colour and uses it only for itself. Clay (`#CB6D4D`) marks the thing you can press and keyboard focus. Status colours always come with an icon and a word.
- **Bird colours:** Wren `#D2AE8A`, Swift `#6E9BD3`, Crow `#8E86D6`, Owl `#D4A954`, Magpie `#D47A93`, Peacock `#C27BB8`.
- **Every value is a token.** Code reads `design/tokens.json`; it never hard-codes a value.
- **Motion:** quick and soft; nothing a person waits on takes longer than `duration-slow` (420ms). `duration-reveal` (900ms) is for first-load choreography only. Reduced motion drops movement but keeps colour changes.

## What was tried and rejected

Kept so no one tries them again:

- A near-black dashboard of bird-tinted cards; one open scene with birds on a wire; a split-flap board, a hardware console and a field guide ("looks too AI").
- Ambient art with no information; a dense hairline "control room" ("feels like an IDE").
- Birds as tubes bent into the glyph shapes ("looks cheap, overlapped").
- Stacked effects: plinths, a stage disc, a light beam with dust, a particle murmuration, lens bokeh, god rays ("rushed", "cheap", "why is there holy light").
- Glow: glowing orbs, glints and coloured floor glows. Depth comes from light and shadow, not glow.

## Still open

- Screens other than Home (Activity, Memory, Settings) have a place in the rail but no design yet. Build them from the same parts.
- How the 3D scene is built natively (RealityKit or SceneKit inside SwiftUI) is a build decision for the first screen task.
