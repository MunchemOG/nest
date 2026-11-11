# Peacock — the showcase

Master-plan phase 7 (Jul 12 – Aug 15, 2027). Its mind: `docs/minds/peacock.md`. Not being built yet; when it is, it should read the portfolio site (munchem.me), write devlogs, and add new clips or text to it.

Peacock notices when your work succeeds and turns those moments into clips, devlogs and portfolio entries, without you stopping to document.

## Who it is
Proud of your work and a little flashy, but it has taste: shows off the right moments, not every moment.
- **Personality:** enthusiastic and celebratory, with a designer's eye.
- **Judgment:** decides which moments are worth keeping (a first working demo, a big before/after).
- **Initiative:** captures without being asked, drafts devlogs and reels on its own, tells you when you've built something worth sharing.
- **Boundaries:** never posts anything itself. It prepares; you publish.

## What it does
| Capability | Detail |
|---|---|
| Win detection | Tests passing after failing, a new screen in an app you're building, a demo that runs, Swift's successful reports |
| Capture | Saves the last moments as a screen clip, plus before/after screenshots and short GIFs |
| Devlog | Drafts entries in your voice from what changed, ready to edit |
| Highlight reels | Monthly edited video of best moments, with captions and music |
| Portfolio | Writes draft entries for your portfolio site in its project format |
| Ready to Post | Finished pieces go to Wren's Ready to Post folder with a post kit (platform, title, description, hashtags, best time); you post them yourself |

## How it's built
Key trick: a rolling recording buffer, so Peacock can save a moment after it happens.
- **Recording:** ScreenCaptureKit keeps the last 30 seconds in memory, discarded unless a win is detected
- **Triggers:** test results, git commits, new app windows, Swift's reports
- **Writing:** a local model drafts devlogs from commits and notes
- **Editing:** Peacock trims raw clips with AVFoundation, then hands them to an AI editing tool (Claude, Higgsfield, or similar) with the design system so the reel matches your theme
- **Privacy:** recordings stay on your Mac until you publish; only clips you'd post go to the editing tool

## Decisions
- **Where work ends up:** your own site as home base, plus Instagram, YouTube, LinkedIn and others as they fit. Shapes each post per platform (vertical reels for Instagram/Shorts, longer YouTube edits, LinkedIn write-ups) but never posts; Wren files each piece with its post kit.
- **When it records:** whenever you're doing something clip-worthy. Uses Crow's view of your screen to tell when you're building, designing or demoing; runs the buffer then, memory only.
- **Reel style:** AI editing tool with the design system as the style guide.
- **Devlog voice:** exactly like you, learned from your past writing in Magpie and every edit you make to a draft.
- **Reaching out:** from the background when it matters (e.g. a post kit ready while a win is fresh), at calm moments only, never during flow.
