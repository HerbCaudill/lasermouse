import AppKit
import LaserMouseCore

/// Polls the modifier keys, mouse buttons and pointer, records the trail and rectangles, and redraws the overlays.
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
    let buttons = Trigger.buttons(pressed: NSEvent.pressedMouseButtons)
    let triggers = settings.triggers
    let action = Action.held(by: triggers, keys: keys, buttons: buttons)
    let pointer = NSEvent.mouseLocation

    state.now = now
    state.trail.fadeDuration = settings.fadeDuration
    state.trail.fadeDelay = settings.fadeDelay
    state.trail.smoothing = settings.smoothing
    state.rectangles.fade = Fade(duration: settings.fadeDuration, delay: settings.fadeDelay)
    state.color = settings.color.nsColor
    state.strokeWidth = settings.strokeWidth
    state.head = action == .draw ? pointer : nil
    if action == .draw { state.trail.add(pointer, at: now) } else { state.trail.endStroke() }
    if action == .rectangle { state.rectangles.drag(to: pointer) } else { state.rectangles.release(at: now) }
    state.trail.prune(at: now)
    state.rectangles.prune(at: now)

    // Keep the mouse until the button comes up, so the app underneath never sees half a click.
    let capture = triggers.values.contains { $0.capturesClicks(with: keys) } || (isCapturing && !buttons.isEmpty)
    if capture != isCapturing {
      overlays.forEach { $0.ignoresMouseEvents = !capture }
      isCapturing = capture
    }

    let isActive = action != nil || !state.trail.isEmpty || !state.rectangles.isEmpty
    if isActive || wasActive {
      overlays.forEach { $0.contentView?.needsDisplay = true }
    }
    wasActive = isActive
  }
}
