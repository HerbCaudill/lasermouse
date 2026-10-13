# LaserMouse

A macOS menu bar app that turns your pointer into a laser. Hold ⌃⌥⌘ and a red dot appears on the pointer, trailing a tail that fades away. It's meant for screen recordings where you want to point at things.

## Install

Requires macOS 14 or later and Swift 6 (Xcode or the Command Line Tools).

```sh
git clone https://github.com/HerbCaudill/lasermouse.git
cd lasermouse
make install
open /Applications/LaserMouse.app
```

The app is signed ad hoc, so it only runs on the Mac that built it.

## Use

Hold the modifier combo and move the pointer. Release it and the tail finishes fading. The menu bar icon lets you change the combo, the fade time, the dot size and the color, and turn on "Open at login".

LaserMouse needs no permissions. It reads the modifier keys and pointer position by polling rather than by listening for events.

## Develop

- `make test` runs the unit tests.
- `make run` builds `build/LaserMouse.app` and opens it.
- `make install` copies it to `/Applications`.
