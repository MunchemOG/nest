# Demo clip

`shell-demo-day.mov` is N1-24: 31 seconds of the Phase 1 shell replaying the whole demo day
(`NestKit/Sources/NestKit/Resources/demo-day.jsonl`) at 2,700 times real speed — the flock idle before dawn,
Wren holding Focus with the ring and flow time, Crow paused, then night: Swift building and the accent turning lagoon.

To record it again, from a Debug build:

```sh
open -n -a <path to NestApp.app> --args -ApplePersistenceIgnoreState YES -NestReplaySpeed 2700
screencapture -v -V 31 -R <x,y,width,height of the window> -x raw.mov
avconvert --preset PresetHEVC1920x1080 --source raw.mov --output shell-demo-day.mov
```

`-NestReplayStart 15:16` jumps to a moment of the day (the one in `design/reference/home.png`), and
`-NestSource empty` starts with no events at all, so every bird shows asleep.
