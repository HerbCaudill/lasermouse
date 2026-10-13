import AppKit

/// The modifier keys and mouse click that together turn the laser on while held.
public struct Trigger: OptionSet, Sendable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let control = Trigger(rawValue: 1 << 0)
  public static let option = Trigger(rawValue: 1 << 1)
  public static let command = Trigger(rawValue: 1 << 2)
  public static let mouseClick = Trigger(rawValue: 1 << 3)

  public static let all: Trigger = [.control, .option, .command, .mouseClick]

  /// The modifier keys this trigger requires.
  public var flags: NSEvent.ModifierFlags {
    var flags: NSEvent.ModifierFlags = []
    if contains(.control) { flags.insert(.control) }
    if contains(.option) { flags.insert(.option) }
    if contains(.command) { flags.insert(.command) }
    return flags
  }

  /// Whether exactly this trigger's modifier keys are down (ignoring Caps Lock and other non-modifier
  /// bits) and, if it requires a click, the mouse button is pressed. An empty trigger is never held.
  public func isHeld(by pressed: NSEvent.ModifierFlags, mouseDown: Bool) -> Bool {
    guard !isEmpty else { return false }
    return keysMatch(pressed) && (mouseDown || !contains(.mouseClick))
  }

  /// Whether the overlay should take the mouse so the click that completes the trigger doesn't reach
  /// the app underneath. A click with no keys is never captured, or the mouse would stop working.
  public func capturesClicks(with pressed: NSEvent.ModifierFlags) -> Bool {
    contains(.mouseClick) && !flags.isEmpty && keysMatch(pressed)
  }

  private func keysMatch(_ pressed: NSEvent.ModifierFlags) -> Bool {
    pressed.intersection([.control, .option, .command, .shift]) == flags
  }
}
