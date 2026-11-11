# Design status

**The look is not decided.** Do not build components or screens (queue tasks N1-03, N1-06 to N1-12, N1-17 onward) until this file says the direction is final.

## What is settled

- **Colours by role.** Each bird has its own colour and uses it only for itself. One accent colour (clay, `#CB6D4D`) marks the thing you can press. Status colours say how something went and always come with an icon and a word.
- **Bird colours:** Wren `#D2AE8A`, Swift `#6E9BD3`, Crow `#8E86D6`, Owl `#D4A954`, Magpie `#D47A93`, Peacock `#C27BB8`.
- **Bird glyphs:** `design/glyphs/`, one rounded single-stroke drawing per bird, plus the Flight m mark.
- **Every value is a token.** `design/tokens.json` holds colours, spacing, radii, shadows, durations and easing. Code reads tokens; it never hard-codes a value. When the look changes, the tokens change and the code doesn't.
- **Motion rules:** quick and soft; nothing a person waits on takes longer than 420ms; only the birds get flourishes; reduced motion drops movement but keeps colour changes.

## What is not settled

The overall visual direction. Rejected so far, each as "looks too AI, not unique or impressive":

1. Near-black dashboard with a sidebar, cards tinted in each bird's colour, soft serif headlines, small uppercase mono labels.
2. The same palette as one open scene: big serif sentence, birds drawn large on a wire, a "score" of the night along the bottom.
3. Three concepts: a split-flap airport departures board, a physical hardware console with a channel per bird, and a naturalist's field guide.

What Mithun wants: something that blows his mind. Likely needs motion, depth or interaction, not just a new static layout. The fonts in `tokens.json` (Fraunces, Manrope, IBM Plex Mono) may change with the direction.

When the direction is chosen, update this file, `design/tokens.json`, and the "Right now" section of `CLAUDE.md`.
