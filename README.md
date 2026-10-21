# Cat on the Screen 🐈

A little white cat that lives on your Mac screen. It sleeps, wanders, climbs onto your app
windows, gets the zoomies, eats kibble you sprinkle, and purrs when you pet it. Native
macOS, zero dependencies.

## Install

One line in Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/RutkayAzizAksu/cat-on-the-screen/main/scripts/install-latest.sh | bash
```

Or download `Neko.zip` from the [latest release](https://github.com/RutkayAzizAksu/cat-on-the-screen/releases/latest),
unzip it, and move `Neko.app` to Applications. On first launch (the app isn't notarized):
right-click `Neko.app` → **Open**. After that it updates itself.

## Features

- **Lives on your windows** — drag the cat and drop it on top of any app window; it walks
  along the window and falls off the edge or when the window closes. It also jumps between
  windows and back to the floor on its own.
- **Reacts to you**
  - Pet it with the cursor → hearts and a happy meow.
  - Drop it from high up → it lands and meows angrily.
  - Right-click → meow, hiss, shout, wake up, sleep, lick, jump (all with sound).
- **Needs-driven daily routine**: energy / boredom / hunger + time-of-day rhythm
  (sleeps deeper at night, most active at dawn and dusk).
- **Feeding** — hold **⌃⌥⌘X**: kibble pours from the cursor. Kibble has real physics
  (gravity, friction, bounce), you can drag and throw it, heaps collapse, and the cat eats
  it bite by bite.
- **Walkabout**: sometimes it digs through the wall and disappears for a few minutes.
- **Auto-update** via GitHub Releases (toggle in the menu).

## Controls

- **⌃⌥⌘X** (hold) — pour kibble at the cursor.
- Drag with the mouse — the cat and the kibble.
- Right-click the cat — action menu.
- Menu-bar 🐈 → *Pour kibble*, *Go for a walk*, *Check for updates*, *Auto-update*, *Quit*.

## Build & run

```bash
./build.sh            # build dist/Neko.app
open dist/Neko.app    # run
```

## Release a new version

```bash
scripts/release.sh 2.0.1 "What's new"
```

Bumps the version → builds → zips → pushes → creates a GitHub Release. Installed copies
update automatically (checked at launch and every 6 hours).

## Credits

Based on the open-source macOS Neko app by [superbereza](https://github.com/superbereza/neko).
The sprite is the classic **oneko** / *Neko* desktop pet (1989 Macintosh "Neko" desk
accessory by Watanabe Daisuke); the sheet comes from
[adryd325/oneko.js](https://github.com/adryd325/oneko.js), recolored here.
