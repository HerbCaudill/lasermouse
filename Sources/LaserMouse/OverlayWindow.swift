import AppKit

/// A transparent, click-through window covering one screen, above everything including full-screen apps.
final class OverlayWindow: NSWindow {
  init(screen: NSScreen, state: LaserState) {
    super.init(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
    setFrame(screen.frame, display: false)
    isOpaque = false
    backgroundColor = .clear
    hasShadow = false
    ignoresMouseEvents = true
    isReleasedWhenClosed = false
    level = .screenSaver
    collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    contentView = LaserView(state: state)
  }

  override var canBecomeKey: Bool { false }
  override var canBecomeMain: Bool { false }
}
