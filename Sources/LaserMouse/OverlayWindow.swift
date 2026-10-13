import AppKit

/// A transparent window covering one screen, above everything including full-screen apps. It lets
/// clicks through except while the trigger keys are down, and never activates the app when clicked.
final class OverlayWindow: NSPanel {
  init(screen: NSScreen, state: LaserState) {
    super.init(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
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
