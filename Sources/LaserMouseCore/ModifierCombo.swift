import AppKit

/// A set of modifier keys that turns the laser on while held.
public enum ModifierCombo: String, CaseIterable, Sendable {
  case controlOption
  case controlCommand
  case optionCommand
  case controlOptionCommand

  public var flags: NSEvent.ModifierFlags {
    switch self {
    case .controlOption: [.control, .option]
    case .controlCommand: [.control, .command]
    case .optionCommand: [.option, .command]
    case .controlOptionCommand: [.control, .option, .command]
    }
  }

  public var symbols: String {
    switch self {
    case .controlOption: "⌃⌥"
    case .controlCommand: "⌃⌘"
    case .optionCommand: "⌥⌘"
    case .controlOptionCommand: "⌃⌥⌘"
    }
  }

  /// Whether `pressed` contains exactly this combo, ignoring Caps Lock and other non-modifier bits.
  public func isHeld(by pressed: NSEvent.ModifierFlags) -> Bool {
    pressed.intersection([.control, .option, .command, .shift]) == flags
  }
}
