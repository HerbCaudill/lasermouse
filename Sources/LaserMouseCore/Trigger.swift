import AppKit

/// The modifier keys and mouse buttons that together turn on an action while held.
public struct Trigger: OptionSet, Hashable, Sendable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let control = Trigger(rawValue: 1 << 0)
  public static let option = Trigger(rawValue: 1 << 1)
  public static let command = Trigger(rawValue: 1 << 2)
  public static let leftClick = Trigger(rawValue: 1 << 3)
  public static let rightClick = Trigger(rawValue: 1 << 4)

  public static let buttons: Trigger = [.leftClick, .rightClick]

  /// The mouse buttons down in `NSEvent.pressedMouseButtons`.
  public static func buttons(pressed: Int) -> Trigger {
    var buttons: Trigger = []
    if pressed & 1 != 0 { buttons.insert(.leftClick) }
    if pressed & 2 != 0 { buttons.insert(.rightClick) }
    return buttons
  }

  /// The modifier keys this trigger requires.
  public var flags: NSEvent.ModifierFlags {
    var flags: NSEvent.ModifierFlags = []
    if contains(.control) { flags.insert(.control) }
    if contains(.option) { flags.insert(.option) }
    if contains(.command) { flags.insert(.command) }
    return flags
  }

  /// How many keys and buttons this trigger requires; the more specific trigger wins a tie.
  var specificity: Int { rawValue.nonzeroBitCount }

  /// Whether exactly this trigger's modifier keys are down (ignoring Caps Lock and other non-modifier
  /// bits) and, if it requires buttons, exactly those buttons are pressed. An empty trigger is never held.
  public func isHeld(by pressed: NSEvent.ModifierFlags, buttons: Trigger) -> Bool {
    guard !isEmpty else { return false }
    let required = intersection(.buttons)
    return keysMatch(pressed) && (required.isEmpty || buttons.intersection(.buttons) == required)
  }

  /// Whether the overlay should take the mouse so the click that completes the trigger doesn't reach
  /// the app underneath. A click with no keys is never captured, or the mouse would stop working.
  public func capturesClicks(with pressed: NSEvent.ModifierFlags) -> Bool {
    !intersection(.buttons).isEmpty && !flags.isEmpty && keysMatch(pressed)
  }

  private func keysMatch(_ pressed: NSEvent.ModifierFlags) -> Bool {
    pressed.intersection([.control, .option, .command, .shift]) == flags
  }
}
