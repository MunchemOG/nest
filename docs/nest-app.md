# Nest app

The Nest app is your window into the flock: a full Mac app to watch every bird and talk to any of them, while the birds keep working on their own whether it's open or not.

## What it's for
- **Watch:** see what every bird is doing right now and what it did while you were away
- **Talk:** chat with any bird, or give an order that one bird hands to another
- **Review:** everything waiting on you in one place: Crow's pitch cards, Swift's reports, Peacock's post kits, Owl's alerts
- **Control:** pause a bird, undo any action, and set each bird's boundaries

## Screens
| Screen | What it shows |
|---|---|
| Home | The whole flock at a glance: each bird's status, its latest action, and a live activity timeline |
| Bird pages | A chat with that bird, its recent actions, and its settings and boundaries |
| Timeline | Everything every bird did, newest first, with one-tap undo on each action |
| Inbox | Items waiting for you: pitch cards, reports, post kits, alerts |
| Memory | Magpie's view: search, a timeline, and a map of linked ideas |
| Settings | Per-bird permissions, pause switches, and schedules |

## Ways in
- **The app:** the full experience, in your Dock
- **Menu bar birds:** click a bird for a quick chat popover without opening the app
- **Global shortcut:** a floating bar from anywhere; type to any bird by name
- **Later:** a private portal so your iPad's browser can reach the whole flock over Tailscale

## Look and feel
Built entirely from the design system and tinted by Wren's current theme. Each bird has its own icon and accent so you can tell them apart at a glance, and every action animates in as it happens. Calm by default; it only draws attention when something needs you. The visual direction is still open: see `docs/design-status.md`.

## How it's built
- **App:** native SwiftUI
- **The birds run separately:** each bird is a background service, so quitting the app never stops the flock
- **Connection:** the app listens to the Nest's shared event bus (`docs/event-bus.md`) for live activity and reads Magpie for history and memory
- **Chat:** each message goes to that bird's own brain (a local model, or Claude Code for Swift)
- **Shortcut and popovers:** a global hotkey opens a floating panel; each menu bar bird hosts its own small chat

## Build plan
1. **Shell (Phase 1):** app frame, Home, Timeline, and the design system applied. Done means: the app shows each bird's status, even before the birds exist.
2. **Grows with the flock:** each bird adds its page and its Inbox items as it ships.
3. **Shortcut and menu bar chats:** talk to any bird without opening the app.
4. **Later:** the iPad portal.

## Leaning, not final
- One menu bar icon per bird (six in all).
- You can talk to the whole flock at once ("everyone, focus mode for two hours").
