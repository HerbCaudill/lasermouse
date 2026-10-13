LaserMouse is a macOS menu bar app written in Swift and AppKit, built with Swift Package Manager and the `Makefile`. There is no Xcode project.

- `Sources/LaserMouseCore` holds logic with no UI (the trail model and modifier matching). Test it with Swift Testing in `Tests/`.
- `Sources/LaserMouse` is the app: overlay windows, drawing, the status menu and settings.
- Run `make test` rather than `swift test`; the Makefile adds the framework paths that Swift Testing needs under the Command Line Tools.
- The app must not require Accessibility or Input Monitoring permissions, and must use only public APIs.
