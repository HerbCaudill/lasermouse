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
  static let dotSizeRange: ClosedRange<Double> = 8...40

  private let defaults = UserDefaults.standard

  var fadeDuration: TimeInterval {
    get { defaults.object(forKey: "fadeDuration") as? Double ?? 3 }
    set { defaults.set(newValue, forKey: "fadeDuration") }
  }

  var fadeDelay: TimeInterval {
    get { defaults.object(forKey: "fadeDelay") as? Double ?? 0 }
    set { defaults.set(newValue, forKey: "fadeDelay") }
  }

  var dotSize: CGFloat {
    get { defaults.object(forKey: "dotSize") as? Double ?? 16 }
    set { defaults.set(Double(newValue), forKey: "dotSize") }
  }

  var trigger: Trigger {
    get { (defaults.object(forKey: "trigger") as? Int).map(Trigger.init) ?? .all }
    set { defaults.set(newValue.rawValue, forKey: "trigger") }
  }

  var color: LaserColor {
    get { defaults.string(forKey: "color").flatMap(LaserColor.init) ?? .red }
    set { defaults.set(newValue.rawValue, forKey: "color") }
  }
}
