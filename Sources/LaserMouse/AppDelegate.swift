import AppKit
import LaserMouseCore

/// Polls the modifier keys, mouse button and pointer, records the trail, and redraws the overlays.
///
/// Polling `NSEvent.modifierFlags`, `NSEvent.pressedMouseButtons` and `NSEvent.mouseLocation` needs no Accessibility or Input
/// Monitoring permission, unlike global event monitors.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private let settings = Settings()
  private let state = LaserState()
  private var overlays: [OverlayWindow] = []
  private var statusMenu: StatusMenu?
  private var timer: Timer?
  private var wasActive = false
  private var isCapturing = false

  func applicationDidFinishLaunching(_ notification: Notification) {
    statusMenu = StatusMenu(settings: settings)
    rebuildOverlays()
    NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated { self?.rebuildOverlays() }
    }
    let timer = Timer(timeInterval: 1.0 / 120, repeats: true) { [weak self] _ in
      MainActor.assumeIsolated { self?.tick() }
    }
    RunLoop.main.add(timer, forMode: .common)
    self.timer = timer
  }

  private func rebuildOverlays() {
    overlays.forEach { $0.close() }
    overlays = NSScreen.screens.map { OverlayWindow(screen: $0, state: state) }
    isCapturing = false
    overlays.forEach { $0.orderFrontRegardless() }
  }

  private func tick() {
    let now = ProcessInfo.processInfo.systemUptime
    let keys = NSEvent.modifierFlags
    let mouseDown = NSEvent.pressedMouseButtons & 1 != 0
    let isHeld = settings.trigger.isHeld(by: keys, mouseDown: mouseDown)
    let pointer = NSEvent.mouseLocation

    state.now = now
    state.trail.fadeDuration = settings.fadeDuration
    state.color = settings.color.nsColor
    state.dotSize = settings.dotSize
    state.head = isHeld ? pointer : nil
    if isHeld { state.trail.add(pointer, at: now) }
    state.trail.prune(at: now)

    // Keep the mouse until the button comes up, so the app underneath never sees half a click.
    let capture = settings.trigger.capturesClicks(with: keys) || (isCapturing && mouseDown)
    if capture != isCapturing {
      overlays.forEach { $0.ignoresMouseEvents = !capture }
      isCapturing = capture
    }

    let isActive = isHeld || !state.trail.isEmpty
    if isActive || wasActive {
      overlays.forEach { $0.contentView?.needsDisplay = true }
    }
    wasActive = isActive
  }
}
