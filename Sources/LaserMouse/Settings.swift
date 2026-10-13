import AppKit
import LaserMouseCore

/// The laser colors offered in the menu.
enum LaserColor: String, CaseIterable {
  case red, green, blue, yellow

  var title: String { rawValue.capitalized }

  var nsColor: NSColor {
    switch self {
    case .red: NSColor(srgbRed: 1, green: 0.12, blue: 0.1, alpha: 1)
    case .green: NSColor(srgbRed: 0.15, green: 1, blue: 0.3, alpha: 1)
    case .blue: NSColor(srgbRed: 0.2, green: 0.55, blue: 1, alpha: 1)
    case .yellow: NSColor(srgbRed: 1, green: 0.9, blue: 0.1, alpha: 1)
    }
  }
}

/// User preferences, persisted in UserDefaults.
@MainActor
final class Settings {
  static let fadeDelayRange: ClosedRange<Double> = 0...5
  static let fadeRange: ClosedRange<Double> = 0.2...5
  static let smoothingRange: ClosedRange<Double> = 0...200
  static let strokeWidthRange: ClosedRange<Double> = 4...40

  private let defaults = UserDefaults.standard

  var fadeDuration: TimeInterval {
    get { defaults.object(forKey: "fadeDuration") as? Double ?? 3 }
    set { defaults.set(newValue, forKey: "fadeDuration") }
  }

  var fadeDelay: TimeInterval {
    get { defaults.object(forKey: "fadeDelay") as? Double ?? 0 }
    set { defaults.set(newValue, forKey: "fadeDelay") }
  }

  var smoothing: Double {
    get { defaults.object(forKey: "smoothing") as? Double ?? 10 }
    set { defaults.set(newValue, forKey: "smoothing") }
  }

  var strokeWidth: CGFloat {
    get { defaults.object(forKey: "strokeWidth") as? Double ?? 12 }
    set { defaults.set(Double(newValue), forKey: "strokeWidth") }
  }

  static let defaultTriggers: [Action: Trigger] = [
    .draw: [.control, .option, .command, .leftClick],
    .rectangle: [.control, .option, .command, .rightClick],
  ]

  var triggers: [Action: Trigger] {
    Dictionary(uniqueKeysWithValues: Action.allCases.map { ($0, trigger(for: $0)) })
  }

  func trigger(for action: Action) -> Trigger {
    (defaults.object(forKey: "trigger.\(action.rawValue)") as? Int).map(Trigger.init) ?? Self.defaultTriggers[action]!
  }

  func setTrigger(_ trigger: Trigger, for action: Action) {
    defaults.set(trigger.rawValue, forKey: "trigger.\(action.rawValue)")
  }

  var color: LaserColor {
    get { defaults.string(forKey: "color").flatMap(LaserColor.init) ?? .red }
    set { defaults.set(newValue.rawValue, forKey: "color") }
  }
}
