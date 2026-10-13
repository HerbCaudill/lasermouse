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

Hold ⌃⌥⌘ and drag with the left button to draw, or with the right button to draw a rectangle. Let go and the mark fades. While the keys are down, clicks go to LaserMouse instead of the app underneath. The menu bar icon has a grid for choosing which keys and buttons trigger each action, and lets you change the fade delay and fade time, the stroke width and the color, and turn on "Open at login".

LaserMouse needs no permissions. It reads the modifier keys, mouse buttons and pointer position by polling rather than by listening for events.

## Develop

- `make test` runs the unit tests.
- `make run` builds `build/LaserMouse.app` and opens it.
- `make install` copies it to `/Applications`.
